enum LR_ELightSpaceMode {
    LR_LSM_Off = 0,
    LR_LSM_DistanceClamp = 1,
    LR_LSM_RelaxCount = 2,
    LR_LSM_RelaxVolume = 3
}

enum LR_EShedKind {
    LR_SK_None = 0,
    LR_SK_Both = 1,
    LR_SK_OnlyI = 2,
    LR_SK_OnlyJ = 3
}

/**
 * Eases the cost of dense, overlapping shadow-casting lights under ray tracing by shrinking
 * some of their radii until each light overlaps only a limited number of its neighbours.
 *
 * Lights are modelled as spheres, and the crowding is resolved by relaxation: deeper overlaps
 * are preserved while shallower ones are shrunk away. The pass only ever shrinks, never grows,
 * so it is idempotent and leaves uncrowded lights untouched.
 *
 * Solve() measures each light's live radius, so callers must clear any prior spacing caps and
 * rewrite to the true profile radii before calling it, or the solve compounds its own output.
 */
class CLightSpacer {
    private var SPACE_MODE: LR_ELightSpaceMode;  default SPACE_MODE = LR_LSM_RelaxVolume;

    private const var MIN_RADIUS : float;  default MIN_RADIUS = 0.1;
    // Overlap shallower than this (metres) counts as not overlapping
    private const var EPSILON    : float;  default EPSILON = 0.01;
    // Most other lights any one light may overlap
    private var MAX_OVERLAPS     : int;    default MAX_OVERLAPS = 7;
    // Most other light centres a distance-clamped sphere may keep within its radius
    private var MAX_CENTRES      : int;    default MAX_CENTRES = 2;
    // Fraction of each overlap removed per pass; lower overshoots less but needs more passes
    private const var RELAX_OMEGA: float;  default RELAX_OMEGA = 0.5;
    private const var MAX_PASSES : int;    default MAX_PASSES = 64;

    // Total overlap each light may keep, as the volume of a sphere this big
    private var OVERLAP_BUDGET_RADIUS: float;  default OVERLAP_BUDGET_RADIUS = 4.0;

    // Parallel arrays, one entry per gathered entity
    private var entities : array<CGameplayEntity>;
    private var positions: array<Vector>;
    private var radii    : array<float>;
    private var original : array<float>;
    private var modes    : array<ELightShadowCastingMode>;

    // Candidate overlap pairs, only those near enough to ever touch; parallel arrays, one per pair
    private var pairI   : array<int>;
    private var pairJ   : array<int>;
    private var pairDist: array<float>;

    private var kept       : array<int>;
    private var slotOverlap: array<float>;
    private var degree     : array<int>;

    /** Apply the menu's spacing type and amount; the overlap count drives both centre and count modes, budget radius drives volume mode */
    public function Configure(mode: LR_ELightSpaceMode, amount: float) {
        SPACE_MODE = mode;
        if (mode == LR_LSM_DistanceClamp) MAX_CENTRES = FloorF(amount);
        else if (mode == LR_LSM_RelaxCount) MAX_OVERLAPS = FloorF(amount);
        else if (mode == LR_LSM_RelaxVolume) OVERLAP_BUDGET_RADIUS = amount;
    }

    /** Runs the full pass; returns how many entities were shrunk. */
    public function Solve(): int {
        if (SPACE_MODE == LR_LSM_Off) return 0;

        Gather();
        if (entities.Size() < 1) return 0;

        switch (SPACE_MODE) {
            case LR_LSM_DistanceClamp:
                ShrinkToCentres();
                break;
            case LR_LSM_RelaxVolume:
                BuildPairs();
                RelaxByVolume();
                break;
            default:
                BuildPairs();
                Relax();
                break;
        }
        return Apply();
    }

    /** Shrink each light so its sphere clears every other light centre but the MAX_CENTRES nearest */
    private function ShrinkToCentres() {
        var order: array<int>;
        var nearest: array<float>;
        var a, b, i, j, s, count, span: int;
        var maxReach, d2, r2, clamp: float;

        count = positions.Size();
        span = MAX_CENTRES + 1;
        nearest.Grow(count * span);
        for (i = 0; i < count; i += 1) {
            r2 = radii[i] * radii[i];
            for (s = 0; s < span; s += 1) nearest[i * span + s] = r2;
            order.PushBack(i);
        }

        SortByX(order);
        // Reach is one radius: a centre sits inside a sphere, not sphere against sphere
        maxReach = MaxRadius();

        for (a = 0; a < count; a += 1) {
            i = order[a];
            for (b = a + 1; b < count; b += 1) {
                j = order[b];
                // Sorted ascending by X, so once the gap clears the reach no later light can touch
                if (positions[j].X - positions[i].X > maxReach) break;

                d2 = VecDistanceSquared(positions[i], positions[j]);
                InsertNearest(nearest, i * span, span, d2);
                InsertNearest(nearest, j * span, span, d2);
            }
        }

        // Squared throughout; the sole sqrt is each final radius
        for (i = 0; i < count; i += 1) {
            clamp = nearest[i * span + span - 1];
            if (clamp < radii[i] * radii[i]) {
                radii[i] = MaxF(MIN_RADIUS, SqrtF(clamp) - EPSILON);
            }
        }
    }

    /** Insert squared distance d2 into a light's ascending nearest-slots, dropping the farthest */
    private function InsertNearest(out nearest: array<float>, base: int, span: int, d2: float) {
        var s, t: int;

        if (d2 >= nearest[base + span - 1]) return;

        for (s = 0; s < span; s += 1) {
            if (d2 >= nearest[base + s]) continue;
            for (t = span - 1; t > s; t -= 1) nearest[base + t] = nearest[base + t - 1];
            nearest[base + s] = d2;
            return;
        }
    }

    private function Gather() {
        var found: array<CEntity>;
        var entity: CGameplayEntity;
        var lightPos: Vector;
        var i, count: int;
        var radius: float;
        var mode: ELightShadowCastingMode;

        entities.Clear();
        positions.Clear();
        radii.Clear();
        original.Clear();
        modes.Clear();

        theGame.GetEntitiesByTag(theGame.lightRewrite.TAG_HAS_LIGHT, found);

        count = found.Size();
        for (i = 0; i < count; i += 1) {
            entity = (CGameplayEntity)found[i];
            if (!entity) continue;

            if (!GetEntitySphere(entity, lightPos, radius, mode)) continue;

            entities.PushBack(entity);
            positions.PushBack(lightPos);
            radii.PushBack(radius);
            original.PushBack(radius);
            modes.PushBack(mode);
        }
    }

    /** Finds the largest shadow-casting point light, returning false if none */
    private function GetEntitySphere(
        entity: CGameplayEntity,
        out centre: Vector,
        out radius: float,
        out mode: ELightShadowCastingMode
    ): bool {
        var components: array<CComponent>;
        var light: CPointLightComponent;
        var i, count: int;

        radius = 0.0;
        mode = LSCM_None;
        components = entity.GetComponentsByClassName('CPointLightComponent');
        count = components.Size();
        for (i = 0; i < count; i += 1) {
            light = (CPointLightComponent)components[i];
            if (!light) continue;
            if (light.shadowCastingMode == LSCM_None) continue;

            if (light.radius > radius) {
                radius = light.radius;
                centre = light.GetWorldPosition();
                mode = light.shadowCastingMode;
            }
        }
        return radius > 0.0;
    }

    private function BuildPairs() {
        var order: array<int>;
        var a, b, count, i, j: int;
        var maxReach, threshold, d2: float;

        pairI.Clear();
        pairJ.Clear();
        pairDist.Clear();

        count = positions.Size();
        if (count < 2) return;

        maxReach = 2.0 * MaxRadius();

        for (a = 0; a < count; a += 1) order.PushBack(a);
        SortByX(order);

        for (a = 0; a < count; a += 1) {
            i = order[a];
            for (b = a + 1; b < count; b += 1) {
                j = order[b];
                // Sorted ascending by X, so once the gap clears the reach no later light can touch
                if (positions[j].X - positions[i].X > maxReach) break;

                threshold = original[i] + original[j] - EPSILON;
                if (threshold <= 0.0) continue;

                // Dynamic-only and static-only lights shadow different geometry; they never crowd
                if (!ModesConflict(modes[i], modes[j])) continue;

                // Compare squared distances so only genuinely overlapping pairs pay the sqrt
                d2 = VecDistanceSquared(positions[i], positions[j]);
                if (d2 >= threshold * threshold) continue;

                pairI.PushBack(i);
                pairJ.PushBack(j);
                pairDist.PushBack(SqrtF(d2));
            }
        }
    }

    /** Two shadow-casters compete unless one is dynamic-only and the other static-only */
    private function ModesConflict(a: ELightShadowCastingMode, b: ELightShadowCastingMode): bool {
        if (a == LSCM_OnlyDynamic && b == LSCM_OnlyStatic) return false;
        if (a == LSCM_OnlyStatic && b == LSCM_OnlyDynamic) return false;
        return true;
    }

    /** Largest gathered sphere radius; bounds how far any two lights can overlap */
    private function MaxRadius(): float {
        var i, count: int;
        var m: float;

        m = 0.0;
        count = original.Size();
        for (i = 0; i < count; i += 1) {
            if (original[i] > m) m = original[i];
        }
        return m;
    }

    /** Heapsort `order` ascending by each index's X, so BuildPairs can sweep-and-prune */
    private function SortByX(out order: array<int>) {
        var n, start, end, tmp: int;

        n = order.Size();
        if (n < 2) return;

        start = n / 2 - 1;
        while (start >= 0) {
            SiftDown(order, start, n - 1);
            start -= 1;
        }

        end = n - 1;
        while (end > 0) {
            tmp = order[0];
            order[0] = order[end];
            order[end] = tmp;
            end -= 1;
            SiftDown(order, 0, end);
        }
    }

    private function SiftDown(out order: array<int>, lo: int, hi: int) {
        var root, child, tmp: int;

        root = lo;
        while (root * 2 + 1 <= hi) {
            child = root * 2 + 1;
            if (child + 1 <= hi && positions[order[child]].X < positions[order[child + 1]].X) {
                child += 1;
            }

            if (positions[order[root]].X >= positions[order[child]].X) return;

            tmp = order[root];
            order[root] = order[child];
            order[child] = tmp;
            root = child;
        }
    }

    /** Shrink the crowded lights so each one overlaps no more than MAX_OVERLAPS others */
    private function Relax() {
        var target: array<float>;
        var shed: array<LR_EShedKind>;
        var pass, e, i, j: int;
        var overlap, step, worst, share: float;
        var changed: bool;

        var edgeCount: int = pairI.Size();
        var lightCount: int = radii.Size();

        target.Grow(lightCount);

        SelectKeptNeighbours(edgeCount, lightCount);

        for (e = 0; e < edgeCount; e += 1) {
            shed.PushBack(ShedKind(pairI[e], pairJ[e]));
        }

        for (pass = 0; pass < MAX_PASSES; pass += 1) {
            for (i = 0; i < lightCount; i += 1) target[i] = radii[i];

            worst = 0.0;
            for (e = 0; e < edgeCount; e += 1) {
                if (shed[e] == LR_SK_None) continue;
                i = pairI[e];
                j = pairJ[e];

                overlap = radii[i] + radii[j] - pairDist[e];
                if (overlap <= EPSILON) continue;
                if (overlap > worst) worst = overlap;

                step = overlap * RELAX_OMEGA;
                if (shed[e] == LR_SK_Both) {
                    // Both crowd each other: split the step by size, so both keep one scale
                    share = step / (original[i] + original[j]);
                    target[i] = MinF(target[i], radii[i] - share * original[i]);
                    target[j] = MinF(target[j], radii[j] - share * original[j]);
                }
                // Otherwise only the crowded light gives way, leaving its quiet neighbour alone
                else if (shed[e] == LR_SK_OnlyI) target[i] = MinF(target[i], radii[i] - step);
                else target[j] = MinF(target[j], radii[j] - step);
            }

            if (worst <= EPSILON) break;

            changed = false;
            for (i = 0; i < lightCount; i += 1) {
                target[i] = MaxF(MIN_RADIUS, target[i]);
                if (target[i] < radii[i]) {
                    radii[i] = target[i];
                    changed = true;
                }
            }
            if (!changed) break;
        }
    }

    private function ShedKind(i: int, j: int): LR_EShedKind {
        var keptI, keptJ: bool;

        keptI = IsKept(i, j);
        keptJ = IsKept(j, i);

        if (keptI && keptJ) return LR_SK_None;
        if (!keptI && !keptJ) return LR_SK_Both;
        if (!keptI) return LR_SK_OnlyI;
        return LR_SK_OnlyJ;
    }

    /** Precompute which overlaps each crowded light keeps, so relaxation needn't re-rank each pass */
    private function SelectKeptNeighbours(edgeCount: int, lightCount: int) {
        var e, s, i, j: int;
        var overlap: float;

        var slots: int = lightCount * MAX_OVERLAPS;

        kept.Resize(slots);
        slotOverlap.Resize(slots);

        for (s = 0; s < slots; s += 1) {
            kept[s] = -1;
            slotOverlap[s] = 0.0;
        }

        degree.Clear();
        degree.Grow(lightCount);

        for (e = 0; e < edgeCount; e += 1) {
            i = pairI[e];
            j = pairJ[e];

            degree[i] += 1;
            degree[j] += 1;
        }

        for (e = 0; e < edgeCount; e += 1) {
            i = pairI[e];
            j = pairJ[e];

            overlap = radii[i] + radii[j] - pairDist[e];

            if (degree[i] > MAX_OVERLAPS) InsertKept(i, j, overlap);
            if (degree[j] > MAX_OVERLAPS) InsertKept(j, i, overlap);
        }
    }

    /** Insert neighbour `other` (depth `overlap`) into `owner`s descending top-MAX_OVERLAPS slots */
    private function InsertKept(owner: int, other: int, overlap: float) {
        var base, s, t: int;

        base = owner * MAX_OVERLAPS;
        for (s = 0; s < MAX_OVERLAPS; s += 1) {
            if (overlap <= slotOverlap[base + s]) continue;

            for (t = MAX_OVERLAPS - 1; t > s; t -= 1) {
                slotOverlap[base + t] = slotOverlap[base + t - 1];
                kept[base + t] = kept[base + t - 1];
            }
            slotOverlap[base + s] = overlap;
            kept[base + s] = other;
            return;
        }
    }

    /** Whether other sits in owner's kept slots; an under-cap owner keeps everyone */
    private function IsKept(owner: int, other: int): bool {
        var s, base: int;

        if (degree[owner] <= MAX_OVERLAPS) return true;

        base = owner * MAX_OVERLAPS;
        for (s = 0; s < MAX_OVERLAPS; s += 1) {
            if (kept[base + s] == other) return true;
        }
        return false;
    }

    /** Shrink crowded lights until each one's summed overlap volume fits the budget sphere */
    private function RelaxByVolume() {
        var load: array<float>;
        var pass, e, i, j, lightCount, edgeCount: int;
        var budget, vol, scale, newR: float;
        var changed: bool;

        edgeCount = pairI.Size();
        lightCount = radii.Size();
        budget = OVERLAP_BUDGET_RADIUS * OVERLAP_BUDGET_RADIUS * OVERLAP_BUDGET_RADIUS;
        load.Grow(lightCount);

        for (pass = 0; pass < MAX_PASSES; pass += 1) {
            for (i = 0; i < lightCount; i += 1) load[i] = 0.0;

            for (e = 0; e < edgeCount; e += 1) {
                i = pairI[e];
                j = pairJ[e];
                vol = OverlapVolume(radii[i], radii[j], pairDist[e]);
                load[i] += vol;
                load[j] += vol;
            }

            changed = false;
            for (i = 0; i < lightCount; i += 1) {
                if (load[i] <= budget) continue;

                // Overlap volume scales ~r^3; cube-root the ratio to ease load toward budget, omega damps overshoot
                scale = PowF(budget / load[i], 1.0 / 3.0);
                newR = radii[i] - RELAX_OMEGA * radii[i] * (1.0 - scale);
                newR = MaxF(MIN_RADIUS, newR);
                if (newR < radii[i]) {
                    radii[i] = newR;
                    changed = true;
                }
            }
            if (!changed) break;
        }
    }

    /** Sphere-sphere intersection volume in r^3 units (sphere = r^3), matching how the budget is measured */
    private function OverlapVolume(rA: float, rB: float, d: float): float {
        var inner: float;

        if (d >= rA + rB) return 0.0;

        // Within the radius gap the smaller sphere sits wholly inside the larger, so it is the whole overlap
        if (d <= AbsF(rA - rB)) {
            inner = MinF(rA, rB);
            return inner * inner * inner;
        }

        // Lens volume where the two spheres overlap
        return (rA + rB - d) * (rA + rB - d)
            * (d * d + 2.0 * d * rA - 3.0 * rA * rA + 2.0 * d * rB + 6.0 * rA * rB - 3.0 * rB * rB)
            / (16.0 * d);
    }

    /** Caps each shrunk light's radius through its rewriter; returns count changed */
    private function Apply(): int {
        var i, count, changedCount: int;
        var rewriter: ILightSourceRewriter;

        count = entities.Size();
        for (i = 0; i < count; i += 1) {
            // Shrink-only: the solve never pulls a light below its start radius, so skip the rest
            if (radii[i] >= original[i] - EPSILON) continue;

            // Production only spaces lights the mod already rewrites; skip anything uncovered
            rewriter = entities[i].lightSourceRewriter;
            if (!rewriter) continue;

            LogLightRewrite("Spacing " + entities[i] + " from " + original[i] + " to " + radii[i]);

            rewriter.SetMaxSafeRadius(radii[i]);
            rewriter.RewriteLight();

            changedCount += 1;
        }
        return changedCount;
    }
}
