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
    private const var fontSize: int;     default fontSize = 32;
    private const var colour  : string;  default colour = "#ff0000";

    private var entities: array<CGameplayEntity>;

    public function Init() {
        InitPool(0x40007000);
    }

    /** Permanently flag an untracked light */
    public function Register(entity: CGameplayEntity) {
        if (!entity || IsRegistered(entity)) return;

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
