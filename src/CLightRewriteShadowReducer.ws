// Live, camera-aware shadow thinning: each frame, shrink casters by the on-screen volume their
// shadow spheres waste overlapping each other, easing back as the view changes. The moving-shot
// counterpart to the static spacer; run with that spacer off or they fight over the live radius.
class CLightRewriteShadowReducer {
    // Gather radius and frustum far plane; entities past this never reach the shot
    var QUERY_RANGE: float;  default QUERY_RANGE = 45.0;

    // Total in-view overlap the whole frame may keep, as the volume of a sphere this big
    var TOTAL_OVERLAP_RADIUS: float;  default TOTAL_OVERLAP_RADIUS = 8.0;

    // Lights this close to the camera are never shrunk; their on-screen footprint is too large to touch
    var PROTECT_DIST    : float;  default PROTECT_DIST = 8.0;
    // At or past this camera distance a light is fully shrinkable
    var FULL_SHRINK_DIST: float;  default FULL_SHRINK_DIST = 30.0;
    // How much an in-frustum light may still give way; 0 protects every visible light
    var INSIDE_WEIGHT   : float;  default INSIDE_WEIGHT = 0.4;
    // Metres outside the frustum over which a light's willingness to shrink ramps to full
    var OUTSIDE_MARGIN  : float;  default OUTSIDE_MARGIN = 4.0;

    // Fraction of the gap to the relaxed radius closed per frame; lower is smoother but lags
    var EASE: float;  default EASE = 0.25;

    private const var NEAR      : float;  default NEAR = 0.05;
    // tan(22 deg): half of the 44 vertical FOV
    private const var TAN_HALF_V: float;  default TAN_HALF_V = 0.4040;
    // 32:9
    private const var ASPECT    : float;  default ASPECT = 3.5556;

    private const var MIN_RADIUS : float;  default MIN_RADIUS = 0.1;
    private const var RELAX_OMEGA: float;  default RELAX_OMEGA = 0.5;
    private const var MAX_PASSES : int;    default MAX_PASSES = 16;
    private const var EPSILON    : float;  default EPSILON = 0.001;

    // View frustum as six inward half-spaces; signedDist(X) = VecDot(planeN[k], X) - planeD[k]
    private var planeN: array<Vector>;
    private var planeD: array<float>;

    // Per-frame scratch, index-aligned across the light arrays
    private var lights  : array<CPointLightComponent>;
    private var centers : array<Vector>;
    private var radii   : array<float>;
    private var authored: array<float>;
    private var modes   : array<ELightShadowCastingMode>;
    private var gShrink : array<float>;

    // Candidate in-view overlap pairs; parallel arrays, one entry per pair
    private var pairI     : array<int>;
    private var pairJ     : array<int>;
    private var pairDist  : array<float>;
    private var pairWeight: array<float>;

    public function Tick() {
        var director: CCameraDirector;
        var camPos, fwd, right, up, center: Vector;
        var found: array<CGameplayEntity>;
        var entity: CGameplayEntity;
        var light: CPointLightComponent;
        var auth, proj: float;
        var i, count: int;

        if (!theGame.lightRewrite || !theGame.GetWorld()) return;
        director = theGame.GetWorld().GetCameraDirector();
        if (!director) return;

        camPos = director.GetCameraPosition();
        fwd = director.GetCameraForward();
        right = director.GetCameraRight();
        up = director.GetCameraUp();

        BuildFrustum(camPos, fwd, right, up);

        lights.Clear();
        centers.Clear();
        radii.Clear();
        authored.Clear();
        modes.Clear();
        gShrink.Clear();

        FindGameplayEntitiesInRange(
            found,
            thePlayer,
            QUERY_RANGE,
            1024,
            theGame.lightRewrite.TAG_HAS_LIGHT,
            FLAG_ExcludePlayer
        );

        count = found.Size();
        for (i = 0; i < count; i += 1) {
            entity = found[i];
            if (!entity) continue;
            if (!PickCaster(entity, light, auth)) continue;

            center = light.GetWorldPosition();
            proj = SignedDistMin(center);

            // Our own cull: a sphere that never reaches the view is switched off entirely
            if (proj < -auth) {
                SetRadius(light, 0.0);
                continue;
            }

            lights.PushBack(light);
            centers.PushBack(center);
            authored.PushBack(auth);
            radii.PushBack(auth);
            modes.PushBack(light.shadowCastingMode);
            gShrink.PushBack(ShrinkWeight(VecLength(center - camPos), proj));
        }

        BuildPairs();
        Relax();
        Apply();
    }

    private function BuildFrustum(camPos, fwd, right, up: Vector) {
        var tanH: float;

        tanH = TAN_HALF_V * ASPECT;

        planeN.Clear();
        planeD.Clear();

        // Four side planes through the apex, then near and far
        AddPlane(fwd * tanH - right, camPos);
        AddPlane(fwd * tanH + right, camPos);
        AddPlane(fwd * TAN_HALF_V - up, camPos);
        AddPlane(fwd * TAN_HALF_V + up, camPos);
        AddPlane(fwd, camPos + fwd * NEAR);
        AddPlane(fwd * -1.0, camPos + fwd * QUERY_RANGE);
    }

    private function AddPlane(n: Vector, point: Vector) {
        var unit: Vector;

        unit = VecNormalize(n);
        planeN.PushBack(unit);
        planeD.PushBack(VecDot(unit, point));
    }

    /** Depth of a point inside the frustum: the tightest plane's signed distance, negative if outside */
    private function SignedDistMin(p: Vector): float {
        var i, count: int;
        var d, m: float;

        m = 100000.0;
        count = planeN.Size();
        for (i = 0; i < count; i += 1) {
            d = VecDot(planeN[i], p) - planeD[i];
            if (d < m) m = d;
        }
        return m;
    }

    /** Largest enabled shadow-casting point light on the entity, plus its authored radius */
    private function PickCaster(
        entity: CGameplayEntity,
        out outLight: CPointLightComponent,
        out outAuthored: float
    ): bool {
        var components: array<CComponent>;
        var light: CPointLightComponent;
        var rewriter: ILightSourceRewriter;
        var uncapped, best: float;
        var i, count: int;
        var hasSchedule: bool;

        rewriter = entity.lightSourceRewriter;
        if (!rewriter) return false;

        hasSchedule = entity.IsCityScheduledLight();
        components = entity.GetComponentsByClassName('CPointLightComponent');
        count = components.Size();
        best = 0.0;

        for (i = 0; i < count; i += 1) {
            light = (CPointLightComponent)components[i];
            if (!light) continue;
            if (light.shadowCastingMode == LSCM_None) continue;
            if (!hasSchedule && !light.IsEnabled()) continue;

            uncapped = rewriter.GetUncappedRadius(light);
            if (uncapped > best) {
                best = uncapped;
                outLight = light;
                outAuthored = uncapped;
            }
        }

        return best > 0.0;
    }

    /** Find every overlapping caster pair whose overlap is at least partly on screen */
    private function BuildPairs() {
        var order: array<int>;
        var a, b, count, i, j: int;
        var maxReach, threshold, d2, d, w: float;

        pairI.Clear();
        pairJ.Clear();
        pairDist.Clear();
        pairWeight.Clear();

        count = centers.Size();
        if (count < 2) return;

        maxReach = 2.0 * MaxAuthored();

        for (a = 0; a < count; a += 1) order.PushBack(a);
        SortByX(order);

        for (a = 0; a < count; a += 1) {
            i = order[a];
            for (b = a + 1; b < count; b += 1) {
                j = order[b];
                // Sorted ascending by X, so once the gap clears the reach no later light can touch
                if (centers[j].X - centers[i].X > maxReach) break;

                // Dynamic-only and static-only casters shadow different geometry; they never crowd
                if (!ModesConflict(modes[i], modes[j])) continue;

                threshold = authored[i] + authored[j];
                d2 = VecDistanceSquared(centers[i], centers[j]);
                if (d2 >= threshold * threshold) continue;

                d = SqrtF(d2);
                w = FrustumWeight(i, j, d);
                if (w < EPSILON) continue;

                pairI.PushBack(i);
                pairJ.PushBack(j);
                pairDist.PushBack(d);
                pairWeight.PushBack(w);
            }
        }
    }

    /** Fraction of an overlap lens that lies inside the frustum, so off-screen crowding is ignored */
    private function FrustumWeight(i, j: int, d: float): float {
        var u, c: Vector;
        var a, rho, m, ri, rj: float;

        ri = authored[i];
        rj = authored[j];

        if (d <= AbsF(ri - rj)) {
            // One sphere contains the other, so the smaller sphere is the whole overlap
            rho = MinF(ri, rj);
            if (ri <= rj) c = centers[i];
            else c = centers[j];
        }
        else {
            // Plane of the intersection circle, measured from centre i along the axis to j
            a = (d * d + ri * ri - rj * rj) / (2.0 * d);
            u = (centers[j] - centers[i]) * (1.0 / d);
            c = centers[i] + u * a;
            rho = SqrtF(MaxF(0.0, ri * ri - a * a));
        }

        // Linear share of the lens disk (radius rho, centred at c) inside its tightest plane
        m = SignedDistMin(c);
        return ClampF((m + rho) / (2.0 * MaxF(rho, EPSILON)), 0.0, 1.0);
    }

    /** Willingness to shrink a light: high far-and-outside view, zero up close so near lights never pop */
    private function ShrinkWeight(dist, proj: float): float {
        var far, view: float;

        far = ClampF((dist - PROTECT_DIST) / (FULL_SHRINK_DIST - PROTECT_DIST), 0.0, 1.0);
        view = INSIDE_WEIGHT + (1.0 - INSIDE_WEIGHT) * ClampF(-proj / OUTSIDE_MARGIN, 0.0, 1.0);
        return far * view;
    }

    /** Two shadow-casters compete unless one is dynamic-only and the other static-only */
    private function ModesConflict(a: ELightShadowCastingMode, b: ELightShadowCastingMode): bool {
        if (a == LSCM_OnlyDynamic && b == LSCM_OnlyStatic) return false;
        if (a == LSCM_OnlyStatic && b == LSCM_OnlyDynamic) return false;
        return true;
    }

    /** Shrink the most expendable lights until the frame's total in-view overlap fits the budget */
    private function Relax() {
        var load: array<float>;
        var pass, e, i, j, lightCount, edgeCount: int;
        var budget, total, excess, denom, vol, shed, frac, scale, newR: float;
        var changed: bool;

        edgeCount = pairI.Size();
        if (edgeCount < 1) return;

        lightCount = radii.Size();
        budget = TOTAL_OVERLAP_RADIUS * TOTAL_OVERLAP_RADIUS * TOTAL_OVERLAP_RADIUS;
        load.Grow(lightCount);

        for (pass = 0; pass < MAX_PASSES; pass += 1) {
            for (i = 0; i < lightCount; i += 1) load[i] = 0.0;

            total = 0.0;
            for (e = 0; e < edgeCount; e += 1) {
                i = pairI[e];
                j = pairJ[e];
                vol = pairWeight[e] * OverlapVolume(radii[i], radii[j], pairDist[e]);
                load[i] += vol;
                load[j] += vol;
                total += vol;
            }

            if (total <= budget) break;
            excess = total - budget;

            // Split the excess across lights by willingness times their overlap, so protected lights take none
            denom = 0.0;
            for (i = 0; i < lightCount; i += 1) denom += gShrink[i] * load[i];
            if (denom < EPSILON) break;

            changed = false;
            for (i = 0; i < lightCount; i += 1) {
                if (gShrink[i] * load[i] < EPSILON) continue;

                shed = excess * (gShrink[i] * load[i]) / denom;
                // Overlap scales ~r^3, so cube-root the surviving fraction into a radius scale; omega damps overshoot
                frac = ClampF(1.0 - shed / load[i], 0.0, 1.0);
                scale = PowF(frac, 1.0 / 3.0);
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

    /** Ease each live radius toward this frame's relaxed target; uncrowded lights drift back to authored */
    private function Apply() {
        var i, count: int;
        var live, eased: float;

        count = lights.Size();
        for (i = 0; i < count; i += 1) {
            live = lights[i].radius;
            eased = live + (radii[i] - live) * EASE;
            SetRadius(lights[i], eased);
        }
    }

    /** Largest gathered sphere radius; bounds how far any two lights can overlap */
    private function MaxAuthored(): float {
        var i, count: int;
        var m: float;

        m = 0.0;
        count = authored.Size();
        for (i = 0; i < count; i += 1) {
            if (authored[i] > m) m = authored[i];
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
            if (child + 1 <= hi && centers[order[child]].X < centers[order[child + 1]].X) {
                child += 1;
            }

            if (centers[order[root]].X >= centers[order[child]].X) return;

            tmp = order[root];
            order[root] = order[child];
            order[child] = tmp;
            root = child;
        }
    }

    /** Toggle enable so the radius change takes visual effect; skip no-op writes */
    private function SetRadius(light: CPointLightComponent, desired: float) {
        var wasEnabled: bool;

        if (AbsF(light.radius - desired) < 0.01) return;

        wasEnabled = light.IsEnabled();
        if (wasEnabled) light.SetEnabled(false);
        light.radius = desired;
        if (wasEnabled) light.SetEnabled(true);
    }
}

@addField(CR4Player) public var lrShadowReducer: CLightRewriteShadowReducer;

@wrapMethod(CR4Player)
function OnGameCameraPostTick(out moveData: SCameraMovementData, dt: float) {
    var handled: bool;
    handled = wrappedMethod(moveData, dt);

    if (!lrShadowReducer) lrShadowReducer = new CLightRewriteShadowReducer in this;
    lrShadowReducer.Tick();

    return handled;
}
