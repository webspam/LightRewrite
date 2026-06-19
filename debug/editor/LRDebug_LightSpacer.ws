/**
 * Debug-only spacing pass: shrinks nearby Light Rewrite lights so their spherical
 * radii no longer overlap one another.
 *
 * Each light-bearing entity is treated as a single sphere: centre = entity world
 * position, radius = its largest point-light radius (spotlights are ignored).
 * Overlapping pairs are relaxed by equal pairwise reduction over repeated passes
 * until none overlap, then the surviving radius is written back through the
 * entity's normal rewriter (the same path LRDebug_AttributeEditor uses).
 *
 * Shrink-only: a light that already clears its neighbours is left untouched, so
 * the pass is idempotent and safe to re-run.
 */
class LRDebug_LightSpacer {
    // Gather radius from the player, pre-squared for distance checks (75 m).
    private const var RANGE_SQUARED: float;  default RANGE_SQUARED = 5625.0;
    // Floor radius; spheres are never shrunk below this.
    private const var MIN_RADIUS   : float;  default MIN_RADIUS = 0.1;
    // Overlap below this (metres) counts as "not overlapping".
    private const var EPSILON      : float;  default EPSILON = 0.01;
    // Safety bound on relaxation passes (coincident centres can never separate).
    private const var MAX_PASSES   : int;    default MAX_PASSES = 64;

    // Parallel arrays, one entry per gathered entity.
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

            // No point light, or all of them dark - nothing to space.
            radius = GetEntitySphereRadius(entity);
            if (radius <= 0.0) continue;

            entities.PushBack(entity);
            positions.PushBack(entityPos);
            radii.PushBack(radius);
            original.PushBack(radius);
        }
    }

    /** Largest radius among the entity's point lights, or 0 if it has none */
    private function GetEntitySphereRadius(entity: CGameplayEntity): float {
        var components: array<CComponent>;
        var light: CPointLightComponent;
        var i, count: int;
        var maxRadius: float;

        components = entity.GetComponentsByClassName('CPointLightComponent');
        count = components.Size();
        for (i = 0; i < count; i += 1) {
            light = (CPointLightComponent)components[i];
            if (light && light.radius > maxRadius) maxRadius = light.radius;
        }
        return maxRadius;
    }

    /**
     * Jacobi-style relaxation: each pass measures every pair, has both spheres of
     * an overlapping pair give up half the overlap, applies the worst reduction
     * each sphere accrued, and repeats until a pass finds no overlap.
     */
    private function Relax() {
        var reduce: array<float>;
        var pass, i, j, count: int;
        var distSq, overlap, half, sumRadii: float;
        var changed: bool;

        count = radii.Size();

        for (pass = 0; pass < MAX_PASSES; pass += 1) {
            reduce.Clear();
            for (i = 0; i < count; i += 1) reduce.PushBack(0.0);

            changed = false;
            for (i = 0; i < count; i += 1) {
                for (j = i + 1; j < count; j += 1) {
                    sumRadii = radii[i] + radii[j];
                    distSq = VecDistanceSquared(positions[i], positions[j]);

                    // Squared test rejects non-touching pairs without a sqrt.
                    if (distSq >= sumRadii * sumRadii) continue;

                    // Overlapping: one sqrt to size the reduction (rA + rB - distance).
                    overlap = sumRadii - SqrtF(distSq);
                    if (overlap <= EPSILON) continue;

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

    /** Writes shrunk radii back through each entity's rewriter; returns count changed */
    private function Apply(): int {
        var i, count, changedCount: int;
        var rewriter: ILightSourceRewriter;
        var params: CLightRewriteSourceParams;
        var entity: CGameplayEntity;

        count = entities.Size();
        for (i = 0; i < count; i += 1) {
            // Shrink-only: skip anything the relaxation left at (or above) its start radius.
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
