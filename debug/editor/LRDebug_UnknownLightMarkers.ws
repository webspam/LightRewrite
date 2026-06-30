/**
 * Permanent HUD flags for light entities the mod isn't tagging.
 *
 * Walking near a point or spot light that lacks TAG_HAS_LIGHT registers it here; the
 * marker then stays put so untracked light sources can be spotted and folded into a profile.
 */
class LRDebug_UnknownLightMarkers {
    private const var fontSize: int;     default fontSize = 32;
    private const var colour  : string;  default colour = "#ff0000";

    private var markerIdSeq: int;  default markerIdSeq = 0x40007000;
    private var markers : array<LRDebug_WorldMarker>;
    private var entities: array<CGameplayEntity>;

    /** Flag an untracked light once; a light already flagged is left alone so it stays marked */
    public function Register(entity: CGameplayEntity) {
        var marker: LRDebug_WorldMarker;

        if (!entity || IsRegistered(entity)) return;

        marker = new LRDebug_WorldMarker in this;
        marker.Init("?", fontSize, colour, NextMarkerId());

        markers.PushBack(marker);
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

    private function NextMarkerId(): int {
        markerIdSeq += 1;
        return markerIdSeq;
    }
}
