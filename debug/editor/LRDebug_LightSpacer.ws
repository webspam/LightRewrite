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
    // Gather radius from the player, pre-squared for distance checks (75 m)
    private const var RANGE_SQUARED: float;  default RANGE_SQUARED = 5625.0;
    // Floor radius; spheres are never shrunk below this
    private const var MIN_RADIUS   : float;  default MIN_RADIUS = 0.1;
    // Overlap below this (metres) counts as "not overlapping"
    private const var EPSILON      : float;  default EPSILON = 0.01;
    // Safety bound on relaxation passes (coincident centres can never separate)
    private const var MAX_PASSES   : int;    default MAX_PASSES = 64;
    // Each light may overlap at most this many others (MAX_OVERLAPS + 1 lights may
    // share a space). Deeper overlaps win the slots; shallower excess is cleared
    private const var MAX_OVERLAPS : int;    default MAX_OVERLAPS = 3;

    // Parallel arrays, one entry per gathered entity
    private var entities : array<CGameplayEntity>;
    private var positions: array<Vector>;
    private var radii    : array<float>;
    private var original : array<float>;

    /** Runs the full pass; returns how many entities were shrunk. */
    public function Solve(): int {
        Gather();
        if (entities.Size() < 2) return 0;

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

        // Every light the mod tagged, world-wide; FindGameplayEntitiesInRange caps out and
        // misses lights in dense rooms, so we take the full list and filter to range ourselves.
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

            // Non-shadow-casting lights cost nothing to render, so they never need spacing
            if (light.shadowCastingMode == LSCM_None) continue;

            if (light.radius > maxRadius) maxRadius = light.radius;
        }
        return maxRadius;
    }

    /**
     * Jacobi-style relaxation: each pass lets every light keep its deepest
     * MAX_OVERLAPS overlaps, then has both spheres of every excess overlapping
     * pair give up half the overlap, applies the worst reduction each sphere
     * accrued, and repeats until a pass finds no excess overlap. Shrinking only
     * ever removes overlaps, never creates them, so the pass converges.
     */
    private function Relax() {
        var kept: array<int>;
        var reduce: array<float>;
        var pass, i, j, count: int;
        var distSq, overlap, half, sumRadii: float;
        var keptByBoth, changed: bool;

        count = radii.Size();

        for (pass = 0; pass < MAX_PASSES; pass += 1) {
            SelectKeptNeighbours(kept);

            reduce.Clear();
            for (i = 0; i < count; i += 1) reduce.PushBack(0.0);

            changed = false;
            for (i = 0; i < count; i += 1) {
                for (j = i + 1; j < count; j += 1) {
                    sumRadii = radii[i] + radii[j];
                    distSq = VecDistanceSquared(positions[i], positions[j]);

                    // Squared test rejects non-touching pairs without a sqrt
                    if (distSq >= sumRadii * sumRadii) continue;

                    // Overlapping: one sqrt to size the reduction (rA + rB - distance)
                    overlap = sumRadii - SqrtF(distSq);
                    if (overlap <= EPSILON) continue;

                    // An overlap may stand only if both lights kept the other
                    keptByBoth = IsKept(kept, i, j) && IsKept(kept, j, i);
                    if (keptByBoth) continue;

                    half = overlap * 0.5;
                    if (half > reduce[i]) reduce[i] = half;
                    if (half > reduce[j]) reduce[j] = half;
                    changed = true;
                }
            }

            if (!changed) break;

            for (i = 0; i < count; i += 1) {
                radii[i] = MaxF(MIN_RADIUS, radii[i] - reduce[i]);
            }
        }
    }

    /**
     * Builds each light's deepest-MAX_OVERLAPS overlaps into kept (stride
     * MAX_OVERLAPS, neighbour indices descending by overlap, -1 padded) so the
     * relaxation loop can test membership instead of re-ranking every pair. Ties
     * keep the lower index, so each light's kept set is stable.
     */
    private function SelectKeptNeighbours(out kept: array<int>) {
        var slotOverlap: array<float>;
        var i, j, s, t, count, base: int;
        var distSq, overlap, sumRadii: float;

        count = radii.Size();

        kept.Clear();
        for (i = 0; i < count * MAX_OVERLAPS; i += 1) kept.PushBack(-1);
        for (s = 0; s < MAX_OVERLAPS; s += 1) slotOverlap.PushBack(0.0);

        for (i = 0; i < count; i += 1) {
            base = i * MAX_OVERLAPS;
            for (s = 0; s < MAX_OVERLAPS; s += 1) {
                kept[base + s] = -1;
                slotOverlap[s] = 0.0;
            }

            for (j = 0; j < count; j += 1) {
                if (j == i) continue;

                sumRadii = radii[i] + radii[j];
                distSq = VecDistanceSquared(positions[i], positions[j]);
                if (distSq >= sumRadii * sumRadii) continue;

                overlap = sumRadii - SqrtF(distSq);
                if (overlap <= EPSILON) continue;

                // Insert j into the descending top-MAX_OVERLAPS slots
                for (s = 0; s < MAX_OVERLAPS; s += 1) {
                    if (overlap > slotOverlap[s]) {
                        for (t = MAX_OVERLAPS - 1; t > s; t -= 1) {
                            slotOverlap[t] = slotOverlap[t - 1];
                            kept[base + t] = kept[base + t - 1];
                        }
                        slotOverlap[s] = overlap;
                        kept[base + s] = j;
                        break;
                    }
                }
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
