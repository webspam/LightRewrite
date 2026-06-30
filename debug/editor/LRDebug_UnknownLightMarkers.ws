@wrapMethod(CR4HudModuleOneliners)
function OnTick(timeDelta: float) {
    wrappedMethod(timeDelta);

    if (thePlayer.lrDebugUnknownMarkers) {
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
    private const var fontSize : int;     default fontSize = 32;
    private const var colour   : string;  default colour = "#ff0000";
    private const var scanRange: float;   default scanRange = 10.0;

    private var entities: array<CGameplayEntity>;

    public function Init() {
        SetBaseId(0x40007000);
    }

    /** Sweep nearby entities for light sources the mod never tagged and flag each one */
    public function Scan() {
        var found: array<CGameplayEntity>;
        var entity: CGameplayEntity;
        var i, count: int;

        FindGameplayEntitiesInRange(found, thePlayer, scanRange, 1024, , FLAG_ExcludePlayer);

        count = found.Size();
        for (i = 0; i < count; i += 1) {
            entity = found[i];
            if (!entity || entity.HasTag(theGame.lightRewrite.TAG_HAS_LIGHT)) continue;

            if (
                entity.GetComponentByClassName('CPointLightComponent') ||
                entity.GetComponentByClassName('CSpotLightComponent')
            ) {
                Register(entity);
            }
        }
    }

    private function Register(entity: CGameplayEntity) {
        if (IsRegistered(entity)) return;

        AddMarker("?", fontSize, colour);
        entities.PushBack(entity);
    }

    /** A flag hides while the overlay is off or once its entity has streamed out of the world */
    public function Update() {
        var i: int;

        for (i = 0; i < markers.Size(); i += 1) {
            if (thePlayer.lrDebugLabels && entities[i]) {
                markers[i].SetWorldPosition(entities[i].GetWorldPosition());
            }
            else {
                markers[i].Hide();
            }
        }
    }

    private function IsRegistered(entity: CGameplayEntity): bool {
        var i: int;

        for (i = 0; i < entities.Size(); i += 1) {
            if (entities[i] == entity) return true;
        }
        return false;
    }
}
