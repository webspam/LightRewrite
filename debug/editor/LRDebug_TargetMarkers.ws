@wrapMethod(CR4HudModuleOneliners)
function OnTick(timeDelta: float) {
    wrappedMethod(timeDelta);

    if (thePlayer.lrDebugTargetMarkers) {
        thePlayer.lrDebugTargetMarkers.Update();
    }
}

/**
 * Shows a pinpoint HUD marker for each of an entities lights.
 */
class LRDebug_TargetMarkers {
    private const var markersPerType: int;  default markersPerType = 5;

    private var markerIdSeq: int;  default markerIdSeq = 0x40004000;
    private var labels    : array<LRDebug_WorldMarker>;
    private var components: array<CComponent>;
    private var radiusRing: LRDebug_RadiusRing;

    public function Init() {
        BuildPool("#00ff52");
        BuildPool("#b100ff");

        radiusRing = new LRDebug_RadiusRing in this;
        radiusRing.Init(0x40005000);

        Update();
    }

    /** Reposition every marker and hide any without a component. */
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

        UpdateRadiusRing();
    }

    /** Show a 2d indicator of the first lights radius (always pointlight if any are present) */
    private function UpdateRadiusRing() {
        var light: CLightComponent;

        if (
            thePlayer.lrDebugLabels &&
            thePlayer.lrDebugAttrEditor &&
            thePlayer.lrDebugAttrEditor.IsEditingRadius()
        ) {
            light = (CLightComponent)components[0];
        }

        if (light) radiusRing.Update(light.GetWorldPosition(), light.radius);
        else radiusRing.Hide();
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

        radiusRing.Hide();
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
