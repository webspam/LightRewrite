/**
 * Shrink nearby shadow-casting lights, to reduce the number of overlapping lights.
 *
 * Each light-bearing entity is treated as one sphere, centred on the entity and
 * sized to its largest shadow-casting point light. Shadow casting lights are the
 * target of this optimisation, so non-shadow point lights are skipped.
 *
 * A light may overlap at most MAX_OVERLAPS others. Excess overlaps are shed in one
 * pass, shrinking the offending radii proportionally to their size until every light
 * is within the limit. The result is written back through the entity's rewriter, the
 * same path the attribute editor uses.
 *
 * The pass only ever shrinks, so it is idempotent: re-running never grows a light
 * back, and lights that already clear their neighbours are left untouched.
 */
class LRDebug_LightSpacer {
    // Max range from player to consider lights for spacing
    private const var RANGE_SQUARED: float;  default RANGE_SQUARED = 160000.0;
    // Floor radius; spheres are never shrunk below this
    private const var MIN_RADIUS   : float;  default MIN_RADIUS = 0.1;
    // Overlap below this (metres) counts as "not overlapping"
    private const var EPSILON      : float;  default EPSILON = 0.01;
    // Each light may overlap at most this many others (MAX_OVERLAPS + 1 lights may
    // share a space). Deeper overlaps win the slots; shallower excess is cleared
    private const var MAX_OVERLAPS : int;    default MAX_OVERLAPS = 5;
    // Fraction of each overlap removed per pass; lower overshoots less but needs more passes
    private const var RELAX_OMEGA  : float;  default RELAX_OMEGA = 0.5;
    // Hard cap so a pair that cannot separate (shared centre) can't spin the loop forever
    private const var MAX_PASSES   : int;    default MAX_PASSES = 64;

    // Parallel arrays, one entry per gathered entity
    private var entities : array<CGameplayEntity>;
    private var positions: array<Vector>;
    private var radii    : array<float>;
    private var original : array<float>;

    // Candidate overlap edges: only pairs near enough to ever touch, so the passes
    // skip the n^2 misses. Parallel arrays, one per edge; pairDist is fixed.
    private var pairI   : array<int>;
    private var pairJ   : array<int>;
    private var pairDist: array<float>;

    private var kept       : array<int>;
    private var slotOverlap: array<float>;
    private var degree     : array<int>;

    /** Runs the full pass; returns how many entities were shrunk. */
    public function Solve(): int {
        Gather();
        LogChannel('LightSpacer', "Entity count: " + IntToString(entities.Size()));
        LogChannel('LightSpacer', "Position count: " + IntToString(positions.Size()));
        LogChannel('LightSpacer', "Radius count: " + IntToString(radii.Size()));
        LogChannel('LightSpacer', "Original count: " + IntToString(original.Size()));
        if (entities.Size() < 2) return 0;

        BuildPairs();
        LogChannel('LightSpacer', "PairI count: " + IntToString(pairI.Size()));
        LogChannel('LightSpacer', "PairJ count: " + IntToString(pairJ.Size()));
        LogChannel('LightSpacer', "PairDist count: " + IntToString(pairDist.Size()));
        Relax();
        return Apply();
    }

    private function Gather() {
        var found: array<CEntity>;
        var entity: CGameplayEntity;
        var playerPos, entityPos, lightPos: Vector;
        var i, count: int;
        var radius: float;

        LogChannel('LightSpacer', "Gathering at " + theGame.GetLocalTimeAsMilliseconds());

        entities.Clear();
        positions.Clear();
        radii.Clear();
        original.Clear();

        theGame.GetEntitiesByTag(theGame.lightRewrite.TAG_HAS_LIGHT, found);
        playerPos = thePlayer.GetWorldPosition();

        count = found.Size();
        for (i = 0; i < count; i += 1) {
            entity = (CGameplayEntity)found[i];
            if (!entity) continue;

            entityPos = entity.GetWorldPosition();
            if (VecDistanceSquared(playerPos, entityPos) > RANGE_SQUARED) continue;
            if (!GetEntitySphere(entity, lightPos, radius)) continue;

            entities.PushBack(entity);
            positions.PushBack(lightPos);
            radii.PushBack(radius);
            original.PushBack(radius);
        }
    }

    /** Finds the largest shadow-casting point light, returning false if none */
    private function GetEntitySphere(
        entity: CGameplayEntity,
        out centre: Vector,
        out radius: float
    ): bool {
        var components: array<CComponent>;
        var light: CPointLightComponent;
        var i, count: int;

        radius = 0.0;
        components = entity.GetComponentsByClassName('CPointLightComponent');
        count = components.Size();
        for (i = 0; i < count; i += 1) {
            light = (CPointLightComponent)components[i];
            if (!light) continue;
            if (light.shadowCastingMode == LSCM_None) continue;

            if (light.radius > radius) {
                radius = light.radius;
                centre = light.GetWorldPosition();
            }
        }
        return radius > 0.0;
    }

    private function BuildPairs() {
        var order: array<int>;
        var a, b, count, i, j: int;
        var maxReach, threshold, d2: float;

        LogChannel('LightSpacer', "Building pairs at " + theGame.GetLocalTimeAsMilliseconds());

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

                // Compare squared distances so only genuinely overlapping pairs pay the sqrt
                d2 = VecDistanceSquared(positions[i], positions[j]);
                if (d2 >= threshold * threshold) continue;

                pairI.PushBack(i);
                pairJ.PushBack(j);
                pairDist.PushBack(SqrtF(d2));
            }
        }
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
        var pass, e, i, j, edgeCount, slots, lightCount: int;
        var overlap, step, worst, share: float;
        var changed: bool;

        LogChannel('LightSpacer', "Relaxing at " + theGame.GetLocalTimeAsMilliseconds());

        edgeCount = pairI.Size();
        lightCount = radii.Size();
        slots = lightCount * MAX_OVERLAPS;

        kept.Clear();
        slotOverlap.Clear();
        degree.Clear();
        for (e = 0; e < slots; e += 1) {
            kept.PushBack(-1);
            slotOverlap.PushBack(0.0);
        }
        for (i = 0; i < lightCount; i += 1) {
            degree.PushBack(0);
            target.PushBack(0.0);
        }

        SelectKeptNeighbours();

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

    /**
     * Rebuild each light's deepest-MAX_OVERLAPS overlaps into kept (stride MAX_OVERLAPS
     * per light, neighbour indices descending by overlap, -1 padded) so the relaxation
     * loop tests membership instead of re-ranking. Each edge feeds both its endpoints.
     * Only over-cap lights are ranked, since an under-cap light keeps every neighbour.
     */
    private function SelectKeptNeighbours() {
        var e, s, edgeCount, slots, i, j: int;
        var overlap: float;

        slots = kept.Size();
        edgeCount = pairI.Size();

        for (s = 0; s < slots; s += 1) {
            kept[s] = -1;
            slotOverlap[s] = 0.0;
        }

        for (e = 0; e < edgeCount; e += 1) {
            i = pairI[e];
            j = pairJ[e];

            overlap = radii[i] + radii[j] - pairDist[e];
            if (overlap <= EPSILON) continue;

            degree[i] += 1;
            degree[j] += 1;
        }

        for (e = 0; e < edgeCount; e += 1) {
            i = pairI[e];
            j = pairJ[e];

            overlap = radii[i] + radii[j] - pairDist[e];
            if (overlap <= EPSILON) continue;

            if (degree[i] > MAX_OVERLAPS) InsertKept(i, j, overlap);
            if (degree[j] > MAX_OVERLAPS) InsertKept(j, i, overlap);
        }
    }

    /** Insert neighbour `other` (depth `overlap`) into `owner`s descending top-MAX_OVERLAPS slots */
    private function InsertKept(owner: int, other: int, overlap: float) {
        var base, s, t: int;

        base = owner * MAX_OVERLAPS;
        for (s = 0; s < MAX_OVERLAPS; s += 1) {
            if (overlap > slotOverlap[base + s]) {
                for (t = MAX_OVERLAPS - 1; t > s; t -= 1) {
                    slotOverlap[base + t] = slotOverlap[base + t - 1];
                    kept[base + t] = kept[base + t - 1];
                }
                slotOverlap[base + s] = overlap;
                kept[base + s] = other;
                return;
            }
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

        LogChannel('LightSpacer', "Applying at " + theGame.GetLocalTimeAsMilliseconds());

        count = entities.Size();
        for (i = 0; i < count; i += 1) {
            // Shrink-only: skip anything the relaxation left at (or above) its start radius
            if (radii[i] >= original[i] - EPSILON) continue;

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
