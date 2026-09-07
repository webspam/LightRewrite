@wrapMethod(CR4HudModuleOneliners)
function OnTick(timeDelta: float) {
    wrappedMethod(timeDelta);

    if (thePlayer.lrDebugLabels && thePlayer.lrDebugGroupMarkers) {
        thePlayer.lrDebugGroupMarkers.Update();
    }
}

/**
 * Diamonds on the other members of the current group edit.
 *
 * On-screen members are marked in-world; off-screen members are pinned to the screen
 * edge in the direction they lie from the camera, so the whole group stays locatable.
 */
class LRDebug_GroupMarkers extends LRDebug_MarkerPool {
    private const var MAX_MARKERS: int;     default MAX_MARKERS = 192;
    private const var FONT_SIZE  : int;     default FONT_SIZE = 20;
    private const var GLYPH      : string;  default GLYPH = "&#9671;";
    private const var COLOUR     : string;  default COLOUR = "#61e5c7";

    private var members: array<CGameplayEntity>;

    public function Init() {
        var i: int;

        SetBaseId(0x40008000);
        for (i = 0; i < MAX_MARKERS; i += 1) AddMarker(GLYPH, FONT_SIZE, COLOUR);
    }

    public function Update() {
        var editor: LRDebug_AttributeEditor = thePlayer.lrDebugAttrEditor;
        var camPos, right, up: Vector;
        var i, count: int;

        if (!editor || !editor.IsGroupEditing()) {
            Hide();
            return;
        }

        editor.GetGroupMembers(thePlayer.lrDebugTargeting.GetTarget(), members);
        GetCameraBasis(camPos, right, up);

        count = members.Size();
        if (count > MAX_MARKERS) count = MAX_MARKERS;

        for (i = 0; i < count; i += 1) {
            if (!members[i]) {
                markers[i].Hide();
                continue;
            }

            markers[i].SetWorldPositionClamped(members[i].GetWorldPosition(), camPos, right, up);
        }

        for (i = count; i < markers.Size(); i += 1) {
            markers[i].Hide();
        }
    }

    /** Camera-relative axes, roll ignored, for projecting off-screen members onto the edge */
    private function GetCameraBasis(out camPos: Vector, out right: Vector, out up: Vector) {
        var director: CCameraDirector = theGame.GetWorld().GetCameraDirector();
        var fwd: Vector = VecNormalize(director.GetCameraDirection());

        camPos = director.GetCameraPosition();
        right = VecCross(fwd, Vector(0.0, 0.0, 1.0));

        if (VecLengthSquared(right) < 0.0001) {
            right = Vector(1.0, 0.0, 0.0);
            up = Vector(0.0, 1.0, 0.0);
            return;
        }

        right = VecNormalize(right);
        up = VecCross(right, fwd);
    }
}
