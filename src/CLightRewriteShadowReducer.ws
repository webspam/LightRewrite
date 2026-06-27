// PoC: shrink casters by real screen-space overlap depth, recomputed per frame.
// Run with the static spacer off, or the two fight over the live radius.
class CLightRewriteShadowReducer {
    var QUERY_RANGE: float;  default QUERY_RANGE = 45.0;

    var TARGET_DEPTH: int;  default TARGET_DEPTH = 3;

    var MIN_SCALE: float;  default MIN_SCALE = 0.35;

    var GRID: int;  default GRID = 64;

    // flip to 0 / 1 if WorldVectorToViewRatio is UV-based, not NDC
    var RATIO_MIN: float;  default RATIO_MIN = -1.0;
    var RATIO_MAX: float;  default RATIO_MAX = 1.0;

    // per-frame scratch, index-aligned across the light arrays
    private var lights  : array<CPointLightComponent>;
    private var sx      : array<float>;
    private var sy      : array<float>;
    private var sr      : array<float>;
    private var authored: array<float>;
    private var grid    : array<int>;

    public function Tick() {
        var director: CCameraDirector;
        var camRight, pos, edge: Vector;
        var found: array<CGameplayEntity>;
        var entity: CGameplayEntity;
        var light: CPointLightComponent;
        var auth, rx, ry, ex, ey, scale: float;
        var i, n, count, peak: int;

        if (!theGame.lightRewrite || !theGame.GetWorld()) return;
        director = theGame.GetWorld().GetCameraDirector();
        if (!director) return;
        camRight = director.GetCameraRight();

        lights.Clear();
        sx.Clear();
        sy.Clear();
        sr.Clear();
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
            // Off-screen casters add no on-screen shadow volume, so restore them
            if (!director.WorldVectorToViewRatio(pos, rx, ry)) {
                SetRadius(light, auth);
                continue;
            }

            edge = pos + camRight * auth;
            director.WorldVectorToViewRatio(edge, ex, ey);

            lights.PushBack(light);
            sx.PushBack(rx);
            sy.PushBack(ry);
            sr.PushBack(VecLength(Vector(ex - rx, ey - ry, 0.0)));
            authored.PushBack(auth);
        }

        n = lights.Size();
        EnsureGrid();
        ZeroGrid();

        // Splat authored footprints so the metric is stable against our own shrinking
        for (i = 0; i < n; i += 1) Splat(sx[i], sy[i], sr[i]);

        for (i = 0; i < n; i += 1) {
            peak = PeakUnder(sx[i], sy[i], sr[i]);

            scale = 1.0;
            if (peak > TARGET_DEPTH) {
                scale = ClampF((float)TARGET_DEPTH / (float)peak, MIN_SCALE, 1.0);
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

    private function Splat(cxR, cyR, rR: float) {
        var cfx, cfy, radC, dx, dy: float;
        var x0, x1, y0, y1, x, y: int;

        radC = ClampF(CellLen(rR), 0.0, (float)GRID);
        cfx = CellPos(cxR);
        cfy = CellPos(cyR);
        x0 = Lo(cfx - radC);
        x1 = Hi(cfx + radC);
        y0 = Lo(cfy - radC);
        y1 = Hi(cfy + radC);

        for (y = y0; y <= y1; y += 1) {
            for (x = x0; x <= x1; x += 1) {
                dx = ((float)x + 0.5) - cfx;
                dy = ((float)y + 0.5) - cfy;
                if (dx * dx + dy * dy <= radC * radC) grid[y * GRID + x] += 1;
            }
        }
    }

    /** Highest stack of casters over any cell this light covers */
    private function PeakUnder(cxR, cyR, rR: float): int {
        var cfx, cfy, radC, dx, dy: float;
        var x0, x1, y0, y1, x, y, peak, d: int;

        radC = ClampF(CellLen(rR), 0.0, (float)GRID);
        cfx = CellPos(cxR);
        cfy = CellPos(cyR);
        x0 = Lo(cfx - radC);
        x1 = Hi(cfx + radC);
        y0 = Lo(cfy - radC);
        y1 = Hi(cfy + radC);
        peak = 0;

        for (y = y0; y <= y1; y += 1) {
            for (x = x0; x <= x1; x += 1) {
                dx = ((float)x + 0.5) - cfx;
                dy = ((float)y + 0.5) - cfy;
                if (dx * dx + dy * dy <= radC * radC) {
                    d = grid[y * GRID + x];
                    if (d > peak) peak = d;
                }
            }
        }

        return peak;
    }

    private function CellPos(r: float): float {
        return (r - RATIO_MIN) / (RATIO_MAX - RATIO_MIN) * (float)GRID;
    }

    private function CellLen(r: float): float {
        return r / (RATIO_MAX - RATIO_MIN) * (float)GRID;
    }

    private function Lo(v: float): int {
        var c: int = (int)FloorF(v);
        if (c < 0) return 0;
        return c;
    }

    private function Hi(v: float): int {
        var c: int = (int)CeilF(v);
        if (c > GRID - 1) return GRID - 1;
        return c;
    }

    private function EnsureGrid() {
        var need: int = GRID * GRID;
        while (grid.Size() < need) grid.PushBack(0);
    }

    private function ZeroGrid() {
        var i, need: int;
        need = GRID * GRID;
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
