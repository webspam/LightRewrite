@wrapMethod(CR4HudModuleOneliners)
function OnTick(timeDelta: float) {
    wrappedMethod(timeDelta);

    if (thePlayer.lrDebugLabels && thePlayer.lrDebugUnknownMarkers) {
        thePlayer.lrDebugUnknownMarkers.Update();
    }
}

/**
 * Permanent HUD flags for light entities the mod isn't tagging.
 *
 * Walking near a point or spot light that lacks TAG_HAS_LIGHT registers it here; the
 * marker then stays put so untracked light sources can be spotted and folded into a profile.
 */
class LRDebug_UnknownLightMarkers extends LRDebug_MarkerPool {
    private const var FONT_SIZE : int;     default FONT_SIZE = 32;
    private const var COLOUR    : string;  default COLOUR = "#ff0000";
    private const var SCAN_RANGE: float;   default SCAN_RANGE = 10.0;

    private var entities: array<CGameplayEntity>;

    public function Init() {
        SetBaseId(0x40007000);
    }

    /** Sweep nearby entities for light sources the mod never tagged and flag each one */
    public function Scan() {
        var found: array<CGameplayEntity>;
        var entity: CGameplayEntity;
        var i, count: int;

        FindGameplayEntitiesInRange(found, thePlayer, SCAN_RANGE, 1024, , FLAG_ExcludePlayer);

        count = found.Size();
        for (i = 0; i < count; i += 1) {
            entity = found[i];
            if (
                !entity ||
                entity.HasTag(theGame.lightRewrite.TAG_HAS_LIGHT) ||
                !entity.HasRewritableLight()
            ) {
                continue;
            }

            Register(entity);
        }
    }

    private function Register(entity: CGameplayEntity) {
        if (IsRegistered(entity)) return;

        AddMarker("?", FONT_SIZE, COLOUR);
        entities.PushBack(entity);
    }

    public function Update() {
        var i, count: int;

        count = markers.Size();
        for (i = 0; i < count; i += 1) {
            if (entities[i]) {
                markers[i].SetWorldPosition(entities[i].GetWorldPosition());
            }
            else {
                markers[i].Hide();
            }
        }
    }

    private function IsRegistered(entity: CGameplayEntity): bool {
        var i, count: int;

        count = entities.Size();
        for (i = 0; i < count; i += 1) {
            if (entities[i] == entity) return true;
        }
        return false;
    }
}
