/**
 * Eases the cost of dense, overlapping shadow-casting lights under ray tracing by shrinking
 * some of their radii until each light overlaps only a limited number of its neighbours.
 *
 * Lights are modelled as spheres, and the crowding is resolved by relaxation: deeper overlaps
 * are preserved while shallower ones are shrunk away. The pass only ever shrinks, never grows,
 * so it is idempotent and leaves uncrowded lights untouched.
 */
class LRDebug_LightSpacer {
    private const var MIN_RADIUS  : float;  default MIN_RADIUS = 0.1;
    // Overlap shallower than this (metres) counts as not overlapping
    private const var EPSILON     : float;  default EPSILON = 0.01;
    // Most other lights any one light may overlap
    private const var MAX_OVERLAPS: int;    default MAX_OVERLAPS = 5;
    // Fraction of each overlap removed per pass; lower overshoots less but needs more passes
    private const var RELAX_OMEGA : float;  default RELAX_OMEGA = 0.5;
    private const var MAX_PASSES  : int;    default MAX_PASSES = 64;

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

    /** Runs the full pass; returns how many entities were shrunk. */
    public function Solve(): int {
        Gather();
        if (entities.Size() < 2) return 0;

        BuildPairs();
        Relax();
        return Apply();
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
        var shed: array<int>;
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
                if (shed[e] == 0) continue;
                i = pairI[e];
                j = pairJ[e];

                overlap = radii[i] + radii[j] - pairDist[e];
                if (overlap <= EPSILON) continue;
                if (overlap > worst) worst = overlap;

                step = overlap * RELAX_OMEGA;
                if (shed[e] == 1) {
                    // Both crowd each other: split the step by size, so both keep one scale
                    share = step / (original[i] + original[j]);
                    target[i] = MinF(target[i], radii[i] - share * original[i]);
                    target[j] = MinF(target[j], radii[j] - share * original[j]);
                }
                // Otherwise only the crowded light gives way, leaving its quiet neighbour alone
                else if (shed[e] == 2) target[i] = MinF(target[i], radii[i] - step);
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

    /** How a candidate pair must give: 0 both keep it, 1 both shed, 2 only i sheds, 3 only j */
    private function ShedKind(i: int, j: int): int {
        var keptI, keptJ: bool;

        keptI = IsKept(i, j);
        keptJ = IsKept(j, i);

        if (keptI && keptJ) return 0;
        if (!keptI && !keptJ) return 1;
        if (!keptI) return 2;
        return 3;
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

    /** Writes shrunk radii back through each entity's rewriter; returns count changed */
    private function Apply(): int {
        var i, count, changedCount: int;
        var rewriter: ILightSourceRewriter;
        var params: CLightRewriteSourceParams;
        var entity: CGameplayEntity;

        count = entities.Size();
        for (i = 0; i < count; i += 1) {
            // Shrink-only: skip anything the relaxation left at (or above) its start radius
            if (radii[i] >= original[i] - EPSILON) continue;

            LogChannel(
                'LRDebug_LightSpacer',
                "Shrinking " + entity.ToString() + " from " + original[i] + " to " + radii[i]
            );

            entity = entities[i];
            rewriter = entity.LRDebug_GetOrCreateRewriter();
            params = entity.LRDebug_GetParams(rewriter);

            params.radius.has = true;
            params.radius.value = radii[i];

            rewriter.LRDebug_SetMenuOverrideParams(params);
            rewriter.RestoreOriginalState();
            rewriter.RewriteLight();

            changedCount += 1;
        }
        return changedCount;
    }
}
