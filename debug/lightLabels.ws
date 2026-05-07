/**
 * Light Rewrite's in-game light authoring overlay.
 *
 * Wires input actions to the label manager, attribute editor, and accelerator.
 * All domain logic lives in the dedicated files in this folder.
 *
 * Requires: mod_sharedutils_oneliners via SU_Oneliner
 *
 * Example input.settings:
 *
 * IK_NumPad7=(Action=LRDebug_ToggleLabels)
 * IK_NumPad8=(Action=LRDebug_ToggleLabelPaths)
 */

// ---- CR4Player fields ----

@addField(CR4Player) public var lrDebugLabels : bool;
@addField(CR4Player) private var lrDebugToast : LRDebug_ToastOneLiner;
@addField(CR4Player) public var lrDebugLabelManager : LRDebug_LabelManager;
@addField(CR4Player) public var lrDebugAttrEditor : LRDebug_AttributeEditor;
@addField(CR4Player) private var lrDebugAccelerator : LRDebug_AdjustAccelerator;

// ---- Lifecycle ----

@wrapMethod(CR4Player)
function OnSpawned(spawnData : SEntitySpawnData) {
    wrappedMethod(spawnData);

    AddTimer('LRDebug_DeferredLabelInstall', 1.f, false);
}

@addMethod(CR4Player)
timer function LRDebug_DeferredLabelInstall(dt : float, id : int) {
    if (!theGame || !thePlayer) return;

    lrDebugLabelManager = new LRDebug_LabelManager in this;
    lrDebugAttrEditor = new LRDebug_AttributeEditor in this;
    lrDebugAccelerator = new LRDebug_AdjustAccelerator in this;
    lrDebugToast = new LRDebug_ToastOneLiner in this;

    theInput.RegisterListener(this, 'LRDebug_OnInputToggleLabels',    'LRDebug_ToggleLabels');
    theInput.RegisterListener(this, 'LRDebug_OnInputToggleLabelPaths', 'LRDebug_ToggleLabelPaths');
    theInput.RegisterListener(this, 'LRDebug_OnInputCycleAttrPrev',   'LRDebug_CycleAttrPrev');
    theInput.RegisterListener(this, 'LRDebug_OnInputCycleAttrNext',   'LRDebug_CycleAttrNext');
    theInput.RegisterListener(this, 'LRDebug_OnInputAdjustDown',      'LRDebug_AdjustDown');
    theInput.RegisterListener(this, 'LRDebug_OnInputToggleRewriter',  'LRDebug_ToggleRewriter');
}

// ---- Toast helper ----

@addMethod(CR4Player)
private function LRDebug_ShowToast(text : string) {
    lrDebugToast.Init("<font size='14'>" + text + "</font>", 1.0);
    lrDebugToast.Start();
}

// ---- Refresh timer ----

@addMethod(CR4Player)
timer function LRDebug_RefreshOnelinersTimer(dt : float, id : int) {
    if (!lrDebugLabels || !theGame || !thePlayer) return;

    lrDebugLabelManager.Scan();
}

// ---- Input: toggle labels ----

@addMethod(CR4Player)
public function LRDebug_OnInputToggleLabels(action : SInputAction) : bool {
    if (!IsPressed(action) || !thePlayer) return false;

    lrDebugLabels = !lrDebugLabels;
    LogChannel('LRDebug', "LRDebug_Toggle: " + lrDebugLabels);

    RemoveTimer('LRDebug_RefreshOnelinersTimer');
    if (lrDebugLabels) {
        AddTimer('LRDebug_RefreshOnelinersTimer', 0.25f, true);
    }

    return true;
}

// ---- Input: toggle path labels ----

@addMethod(CR4Player)
public function LRDebug_OnInputToggleLabelPaths(action : SInputAction) : bool {
    if (!IsPressed(action) || !thePlayer) return false;

    lrDebugLabelManager.TogglePathLabels();
    return true;
}

// ---- Input: cycle attribute ----

@addMethod(CR4Player)
public function LRDebug_OnInputCycleAttrPrev(action : SInputAction) : bool {
    if (!IsPressed(action) || !thePlayer) return false;

    lrDebugAttrEditor.CycleAttribute(-1);
    lrDebugLabelManager.RefreshTargetOneliner();
    return true;
}

@addMethod(CR4Player)
public function LRDebug_OnInputCycleAttrNext(action : SInputAction) : bool {
    if (!IsPressed(action) || !thePlayer) return false;

    lrDebugAttrEditor.CycleAttribute(1);
    lrDebugLabelManager.RefreshTargetOneliner();
    return true;
}

// ---- Input: adjust attribute value ----

@addMethod(CR4Player)
public function LRDebug_OnInputAdjustDown(action : SInputAction) : bool {
    var sign : int;

    if (!action.value) return false;

    // Convert from +/- float (e.g. ±3.0) to int sign.
    if (action.value > 0.0) sign = 1;
    else sign = -1;

    lrDebugLabelManager.ApplyAttributeAdjustment(sign, lrDebugAttrEditor, lrDebugAccelerator);
    return true;
}

// ---- Input: toggle rewriter on/off ----

@addMethod(CR4Player)
public function LRDebug_OnInputToggleRewriter(action : SInputAction) : bool {
    var result : string;

    if (!IsPressed(action) || !thePlayer) return false;

    result = lrDebugLabelManager.ToggleRewriterOnTarget();
    if (result != "") LRDebug_ShowToast("LightRewrite: " + result);

    return true;
}
