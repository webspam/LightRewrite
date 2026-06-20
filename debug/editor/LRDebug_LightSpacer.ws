/**
 * Shrink nearby shadow-casting lights, to reduce the number of overlapping lights.
 *
 * Each light-bearing entity is treated as one sphere, centred on the entity and
 * sized to its largest shadow-casting point light. Shadow casting lights are the
 * target of this optimisation, so non-shadow point lights are skipped.
 *
 * A light may overlap at most MAX_OVERLAPS others. Any excess is relaxed away over
 * repeated passes, shrinking the offending radii until every light is within the
 * limit. The result is written back through the entity's rewriter, the same path
 * the attribute editor uses.
 *
 * The pass only ever shrinks, so it is idempotent: re-running never grows a light
 * back, and lights that already clear their neighbours are left untouched.
 */
class LRDebug_LightSpacer {
    // Max range from player to consider lights for spacing
    private const var RANGE_SQUARED: float;  default RANGE_SQUARED = 22500.0;
    // Floor radius; spheres are never shrunk below this
    private const var MIN_RADIUS   : float;  default MIN_RADIUS = 0.1;
    // Overlap below this (metres) counts as "not overlapping"
    private const var EPSILON      : float;  default EPSILON = 0.01;
    // Hard cap: lights sharing a centre can never be separated, so the loop would otherwise spin forever
    private const var MAX_PASSES   : int;    default MAX_PASSES = 256;
    // How much of each overlap to remove per pass; smaller values overshoot less but need more passes
    private const var RELAX_OMEGA  : float;  default RELAX_OMEGA = 0.3;
    // Each light may overlap at most this many others (MAX_OVERLAPS + 1 lights may
    // share a space). Deeper overlaps win the slots; shallower excess is cleared
    private const var MAX_OVERLAPS : int;    default MAX_OVERLAPS = 3;

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
        var playerPos, entityPos: Vector;
        var i, count: int;
        var radius: float;

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

            // No point light, or all of them dark - nothing to space
            radius = GetEntitySphereRadius(entity);
            if (radius <= 0.0) continue;

            entities.PushBack(entity);
            positions.PushBack(entityPos);
            radii.PushBack(radius);
            original.PushBack(radius);
        }
    }

    /** Largest radius among the entity's shadow-casting point lights, or 0 if it has none */
    private function GetEntitySphereRadius(entity: CGameplayEntity): float {
        var components: array<CComponent>;
        var light: CPointLightComponent;
        var i, count: int;
        var maxRadius: float;

        components = entity.GetComponentsByClassName('CPointLightComponent');
        count = components.Size();
        for (i = 0; i < count; i += 1) {
            light = (CPointLightComponent)components[i];
            if (!light) continue;
            if (light.shadowCastingMode == LSCM_None) continue;

            if (light.radius > maxRadius) maxRadius = light.radius;
        }
        return maxRadius;
    }

    /**
     * Build the candidate-pair edge list once: radii only shrink, so pairs that can't
     * reach each other at full size never will, and every pass then skips the n^2 misses.
     */
    private function BuildPairs() {
        var i, j, count: int;
        var dist: float;

        pairI.Clear();
        pairJ.Clear();
        pairDist.Clear();

        count = positions.Size();
        for (i = 0; i < count; i += 1) {
            for (j = i + 1; j < count; j += 1) {
                dist = SqrtF(VecDistanceSquared(positions[i], positions[j]));
                if (original[i] + original[j] - dist <= EPSILON) continue;

                pairI.PushBack(i);
                pairJ.PushBack(j);
                pairDist.PushBack(dist);
            }
        }
    }

    /**
     * Gauss-Seidel relaxation: each pass lets every light keep its deepest
     * MAX_OVERLAPS overlaps, then shrinks both spheres of every excess pair by a
     * fraction of the overlap, applied at once so later pairs see it, and repeats
     * until a pass finds no excess overlap. Shrinking only ever removes overlaps,
     * never creates them, so the pass converges.
     */
    private function Relax() {
        var kept: array<int>;
        var slotOverlap: array<float>;
        var pass, e, i, j, edgeCount, slots: int;
        var overlap, step: float;
        var changed: bool;

        edgeCount = pairI.Size();
        slots = radii.Size() * MAX_OVERLAPS;

        // Allocate the kept ranking once; SelectKeptNeighbours rebuilds it in place each pass
        for (e = 0; e < slots; e += 1) {
            kept.PushBack(-1);
            slotOverlap.PushBack(0.0);
        }

        for (pass = 0; pass < MAX_PASSES; pass += 1) {
            SelectKeptNeighbours(kept, slotOverlap);

            changed = false;
            for (e = 0; e < edgeCount; e += 1) {
                i = pairI[e];
                j = pairJ[e];

                overlap = radii[i] + radii[j] - pairDist[e];
                if (overlap <= EPSILON) continue;

                // An overlap may stand only if both lights kept the other
                if (IsKept(kept, i, j) && IsKept(kept, j, i)) continue;

                step = overlap * 0.5 * RELAX_OMEGA;
                // Pairs already pinned at the floor can't separate; don't keep the pass loop alive for them
                if (radii[i] > MIN_RADIUS || radii[j] > MIN_RADIUS) changed = true;
                radii[i] = MaxF(MIN_RADIUS, radii[i] - step);
                radii[j] = MaxF(MIN_RADIUS, radii[j] - step);
            }

            if (!changed) break;
        }
    }

    /**
     * Rebuild each light's deepest-MAX_OVERLAPS overlaps into kept (stride MAX_OVERLAPS
     * per light, neighbour indices descending by overlap, -1 padded) so the relaxation
     * loop tests membership instead of re-ranking. Each edge feeds both its endpoints.
     */
    private function SelectKeptNeighbours(out kept: array<int>, out slotOverlap: array<float>) {
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

            InsertKept(kept, slotOverlap, i, j, overlap);
            InsertKept(kept, slotOverlap, j, i, overlap);
        }
    }

    /** Insert neighbour `other` (depth `overlap`) into `owner`s descending top-MAX_OVERLAPS slots */
    private function InsertKept(
        out kept: array<int>,
        out slotOverlap: array<float>,
        owner: int,
        other: int,
        overlap: float
    ) {
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

    /** Whether other sits in owner's kept slots */
    private function IsKept(out kept: array<int>, owner: int, other: int): bool {
        var s, base: int;

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
