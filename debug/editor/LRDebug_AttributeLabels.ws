/**
 * Bottom-left grid listing every setting on the active light.
 *
 * Shown with the path labels. Values and refresh events come from the target's
 * LRDebug_LightOneLiner.
 */
class LRDebug_AttributeLabels {
    private var labels  : array<LRDebug_ScreenLabel>;
    private var slotUsed: array<bool>;

    private const var COLS   : int;  default COLS = 4;
    private const var ROWS   : int;  default ROWS = 5;
    private const var BASE_ID: int;  default BASE_ID = 1073766656;

    private const var RIGHT_X : float;  default RIGHT_X = 0.40;
    private const var COL_STEP: float;  default COL_STEP = 0.03;
    private const var BOTTOM_Y: float;  default BOTTOM_Y = 0.98;
    private const var ROW_STEP: float;  default ROW_STEP = 0.016;
    private const var FONT    : int;    default FONT = 16;

    public function Init() {
        var col, row, idx: int;

        for (col = 0; col < COLS; col += 1) {
            for (row = 0; row < ROWS; row += 1) {
                idx = SlotIndex(col, row);
                labels.PushBack(new LRDebug_ScreenLabel in this);
                labels[idx].Init(
                    BASE_ID + idx,
                    RIGHT_X - col * COL_STEP,
                    BOTTOM_Y - row * ROW_STEP
                );
                slotUsed.PushBack(false);
            }
        }
    }

    private function SlotIndex(col: int, row: int): int {
        return col * ROWS + row;
    }

    public function Update(target: CGameplayEntity) {
        var oneliner: LRDebug_LightOneLiner;
        var type: name;

        ResetSlots();

        if (!target || !target.lrdebugOneliner || !thePlayer.lrDebugAttrEditor) {
            HideUnused();
            return;
        }

        oneliner = target.lrdebugOneliner;
        type = thePlayer.lrDebugAttrEditor.GetSelectedLightType(target);

        BuildCoreColumn(oneliner, type);
        BuildShadowColumn(oneliner, type);
        BuildColourColumn(oneliner, type);
        BuildPlacementColumn(oneliner, type);

        HideUnused();
    }

    public function Hide() {
        var i: int;

        for (i = 0; i < labels.Size(); i += 1) {
            labels[i].Hide();
        }
        ResetSlots();
    }

    private function BuildCoreColumn(oneliner: LRDebug_LightOneLiner, type: name) {
        Emit(oneliner, type, 0, 3, 'brightness');
        Emit(oneliner, type, 0, 2, 'radius');
        Emit(oneliner, type, 0, 1, 'attenuation');
    }

    private function BuildShadowColumn(oneliner: LRDebug_LightOneLiner, type: name) {
        Emit(oneliner, type, 1, 3, 'shadowMode', "mode");
        Emit(oneliner, type, 1, 2, 'shadowFadeDistance', "shadow dist");
        Emit(oneliner, type, 1, 1, 'shadowFadeRange', "shadow range");
        Emit(oneliner, type, 1, 0, 'shadowBlendFactor', "shadow blend");
    }

    private function BuildColourColumn(oneliner: LRDebug_LightOneLiner, type: name) {
        Emit(oneliner, type, 2, 3, 'colourR', "R");
        Emit(oneliner, type, 2, 2, 'colourG', "G");
        Emit(oneliner, type, 2, 1, 'colourB', "B");
        Emit(oneliner, type, 2, 0, 'overrideColour', "override");
    }

    private function BuildPlacementColumn(oneliner: LRDebug_LightOneLiner, type: name) {
        Emit(oneliner, type, 3, 3, 'alignOffsetZ', "offset Z");

        if (type == 'spot') {
            Emit(oneliner, type, 3, 2, 'innerAngle');
            Emit(oneliner, type, 3, 1, 'outerAngle');
            Emit(oneliner, type, 3, 0, 'softness');
        }
        else {
            Emit(oneliner, type, 3, 1, 'alignPointLights', "align points");
            Emit(oneliner, type, 3, 0, 'useSpotlightColor', "use spotlight colour");
        }
    }

    private function Emit(
        oneliner: LRDebug_LightOneLiner,
        type: name,
        col: int,
        row: int,
        attr: name,
        optional labelText: string
    ) {
        var idx: int = SlotIndex(col, row);
        var active: bool = thePlayer.lrDebugAttrEditor.GetCurrentAttrId(type) == attr;
        var label: string = labelText;
        var newText: string;

        if (label == "") label = attr;
        newText = BuildRow(label, oneliner.GetAttributeValueString(attr, type), active);

        labels[idx].SetText(newText);
        labels[idx].Show();
        slotUsed[idx] = true;
    }

    /** Accent label, white value; the attribute being edited is picked out in yellow. */
    private function BuildRow(label: string, value: string, active: bool): string {
        var labelColour: string = "#dd88ff";
        var valueColour: string = "#ffffff";

        if (active) labelColour = "#88ffdd";
        if (value == "None") valueColour = "#999999";

        return "<font size='" + FONT + "' color='" + labelColour + "'>" + label
            + " </font><font size='" + FONT + "' color='" + valueColour + "'>" + value + "</font>";
    }

    private function ResetSlots() {
        var i: int;

        for (i = 0; i < slotUsed.Size(); i += 1) {
            slotUsed[i] = false;
        }
    }

    private function HideUnused() {
        var i: int;

        for (i = 0; i < labels.Size(); i += 1) {
            if (!slotUsed[i]) labels[i].Hide();
        }
    }
}
