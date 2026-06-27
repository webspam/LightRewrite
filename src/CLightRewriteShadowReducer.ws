// PoC: shrink casters by real screen-space overlap area, recomputed per frame.
// Run with the static spacer off, or the two fight over the live radius.
class CLightRewriteShadowReducer {
    var QUERY_RANGE: float;  default QUERY_RANGE = 45.0;

    var OVERLAP_BUDGET: float;  default OVERLAP_BUDGET = 0.15;

    var MIN_SCALE: float;  default MIN_SCALE = 0.35;

    // tan(22 deg): half of the 44 vertical FOV
    var TAN_HALF_V: float;  default TAN_HALF_V = 0.4040;

    // 32:9
    var ASPECT: float;  default ASPECT = 3.5556;

    var GRID_W: int;  default GRID_W = 128;
    var GRID_H: int;  default GRID_H = 36;

    // per-frame scratch, index-aligned across the light arrays
    private var lights  : array<CPointLightComponent>;
    private var cx      : array<float>;
    private var cy      : array<float>;
    private var cr      : array<float>;
    private var authored: array<float>;
    private var grid    : array<int>;

    public function Tick() {
        var director: CCameraDirector;
        var camPos, fwd, right, up, v, pos: Vector;
        var found: array<CGameplayEntity>;
        var entity: CGameplayEntity;
        var light: CPointLightComponent;
        var auth, z, xN, yN, rN, scale, excessFrac: float;
        var i, n, count: int;

        if (!theGame.lightRewrite || !theGame.GetWorld()) return;
        director = theGame.GetWorld().GetCameraDirector();
        if (!director) return;

        camPos = director.GetCameraPosition();
        fwd = director.GetCameraForward();
        right = director.GetCameraRight();
        up = director.GetCameraUp();

        lights.Clear();
        cx.Clear();
        cy.Clear();
        cr.Clear();
        authored.Clear();

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

            pos = light.GetWorldPosition();
            v = pos - camPos;
            z = VecDot(v, fwd);
            if (z < 0.05) {
                SetRadius(light, auth);
                continue;
            }

            xN = (VecDot(v, right) / z) / (TAN_HALF_V * ASPECT);
            yN = (VecDot(v, up) / z) / TAN_HALF_V;
            rN = (auth / z) / TAN_HALF_V;

            // Casters whose disk misses the screen add no on-screen overlap, so restore
            if (AbsF(xN) - rN / ASPECT > 1.0 || AbsF(yN) - rN > 1.0) {
                SetRadius(light, auth);
                continue;
            }

            lights.PushBack(light);
            cx.PushBack((xN + 1.0) * 0.5 * (float)GRID_W);
            cy.PushBack((yN + 1.0) * 0.5 * (float)GRID_H);
            cr.PushBack(rN * 0.5 * (float)GRID_H);
            authored.PushBack(auth);
        }

        n = lights.Size();
        EnsureGrid();
        ZeroGrid();

        // Splat authored footprints so the metric is stable against our own shrinking
        for (i = 0; i < n; i += 1) Splat(cx[i], cy[i], cr[i]);

        for (i = 0; i < n; i += 1) {
            excessFrac = OverlapExcessUnder(cx[i], cy[i], cr[i]) / (float)(GRID_W * GRID_H);

            scale = 1.0;
            if (excessFrac > OVERLAP_BUDGET) {
                scale = ClampF(SqrtF(OVERLAP_BUDGET / excessFrac), MIN_SCALE, 1.0);
            }

            SetRadius(lights[i], authored[i] * scale);
        }
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

    private function Splat(ccx, ccy, ccr: float) {
        var dx, dy: float;
        var x0, x1, y0, y1, x, y: int;

        x0 = Lo(ccx - ccr);
        x1 = Hi(ccx + ccr, GRID_W - 1);
        y0 = Lo(ccy - ccr);
        y1 = Hi(ccy + ccr, GRID_H - 1);

        for (y = y0; y <= y1; y += 1) {
            for (x = x0; x <= x1; x += 1) {
                dx = ((float)x + 0.5) - ccx;
                dy = ((float)y + 0.5) - ccy;
                if (dx * dx + dy * dy <= ccr * ccr) grid[y * GRID_W + x] += 1;
            }
        }
    }

    /** Overlap area under this light, counted once per overlapping caster */
    private function OverlapExcessUnder(ccx, ccy, ccr: float): float {
        var dx, dy, excess: float;
        var x0, x1, y0, y1, x, y: int;

        x0 = Lo(ccx - ccr);
        x1 = Hi(ccx + ccr, GRID_W - 1);
        y0 = Lo(ccy - ccr);
        y1 = Hi(ccy + ccr, GRID_H - 1);
        excess = 0.0;

        for (y = y0; y <= y1; y += 1) {
            for (x = x0; x <= x1; x += 1) {
                dx = ((float)x + 0.5) - ccx;
                dy = ((float)y + 0.5) - ccy;
                if (dx * dx + dy * dy <= ccr * ccr) excess += (float)(grid[y * GRID_W + x] - 1);
            }
        }

        return excess;
    }

    private function Lo(v: float): int {
        var c: int = (int)FloorF(v);
        if (c < 0) return 0;
        return c;
    }

    private function Hi(v: float, hiMax: int): int {
        var c: int = (int)CeilF(v);
        if (c > hiMax) return hiMax;
        return c;
    }

    private function EnsureGrid() {
        var need: int = GRID_W * GRID_H;
        while (grid.Size() < need) grid.PushBack(0);
    }

    private function ZeroGrid() {
        var i, need: int;
        need = GRID_W * GRID_H;
        for (i = 0; i < need; i += 1) grid[i] = 0;
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
