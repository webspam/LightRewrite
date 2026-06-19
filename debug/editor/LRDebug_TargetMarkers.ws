/**
 * Maintains a pool of LRDebug_WorldMarker labels that pinpoint each light
 * component on the current target entity.
 *
 * SetTarget() rebinds the pool to a new entity's light components - point lights
 * to the green markers, spot lights to the purple ones. Update() repositions every
 * bound marker to its component's on-screen position and is driven from the oneliner
 * HUD module's tick (see the wrapMethod below) so the markers track at frame rate
 * rather than at the slower Scan() cadence.
 *
 * Lives on CR4Player as lrDebugTargetMarkers; LRDebug_LabelManager only tells it
 * which entity is the target.
 */

@wrapMethod(CR4HudModuleOneliners)
function OnTick(timeDelta: float) {
    wrappedMethod(timeDelta);

    if (thePlayer.lrDebugTargetMarkers) {
        thePlayer.lrDebugTargetMarkers.Update();
    }
}

class LRDebug_TargetMarkers {
    private const var markersPerType: int;  default markersPerType = 5;

    private var markerIdSeq: int;  default markerIdSeq = 0x40004000;
    private var labels    : array<LRDebug_WorldMarker>;
    private var components: array<CComponent>;

    public function Init() {
        BuildPool("#00ff52");
        BuildPool("#b100ff");
        Update();
    }

    /** Reposition every bound marker; hide any without a component or while labels are off. */
    public function Update() {
        var i, count: int;

        count = labels.Size();
        for (i = 0; i < count; i += 1) {
            if (thePlayer.lrDebugLabels && components[i]) {
                labels[i].SetWorldPosition(components[i].GetWorldPosition());
            }
            else {
                labels[i].Hide();
            }
        }
    }

    /** Bind the marker pool to the new target's light components (point then spot). */
    public function SetTarget(entity: CGameplayEntity) {
        Clear();

        if (!entity) return;

        Bind(entity, 'CPointLightComponent', 0);
        Bind(entity, 'CSpotLightComponent', markersPerType);
    }

    private function Bind(entity: CGameplayEntity, className: name, offset: int) {
        var found: array<CComponent>;
        var i: int;

        found = entity.GetComponentsByClassName(className);
        for (i = 0; i < found.Size() && i < markersPerType; i += 1) {
            components[offset + i] = found[i];
        }
    }

    private function Clear() {
        var i: int;

        for (i = 0; i < labels.Size(); i += 1) {
            components[i] = NULL;
            labels[i].Hide();
        }
    }

    private function BuildPool(color: string) {
        var i: int;
        var marker: LRDebug_WorldMarker;

        for (i = 0; i < markersPerType; i += 1) {
            marker = new LRDebug_WorldMarker in this;
            marker.Init("+", 16, color, NextMarkerId());
            labels.PushBack(marker);
            components.PushBack(NULL);
        }
    }

    private function NextMarkerId(): int {
        markerIdSeq += 1;
        return markerIdSeq;
    }
}
