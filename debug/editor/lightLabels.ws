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
@addField(CR4Player) public var lrDebugLabelManager : LRDebug_LabelManager;
@addField(CR4Player) public var lrDebugAttrEditor : LRDebug_AttributeEditor;
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
    lrDebugLabelManager.Init();
    lrDebugAttrEditor = new LRDebug_AttributeEditor in this;
    lrDebugAttrEditor.Init();
    theInput.RegisterListener(this, 'LRDebug_OnInputToggleLabels',    'LRDebug_ToggleLabels');
    theInput.RegisterListener(this, 'LRDebug_OnInputToggleLabelPaths', 'LRDebug_ToggleLabelPaths');
    theInput.RegisterListener(this, 'LRDebug_OnInputCycleAttrPrev',   'LRDebug_CycleAttrPrev');
    theInput.RegisterListener(this, 'LRDebug_OnInputCycleAttrNext',   'LRDebug_CycleAttrNext');
    theInput.RegisterListener(this, 'LRDebug_OnInputAdjustDown',      'LRDebug_AdjustDown');
    theInput.RegisterListener(this, 'LRDebug_OnInputToggleRewriter',  'LRDebug_ToggleRewriter');
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
        AddTimer('LRDebug_RefreshOnelinersTimer', 0.1f, true);
    }

    return true;
}

// ---- Input: toggle path labels ----

@addMethod(CR4Player)
public function LRDebug_OnInputToggleLabelPaths(action : SInputAction) : bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    lrDebugLabelManager.TogglePathLabels();
    return true;
}

// ---- Input: cycle attribute ----

@addMethod(CR4Player)
public function LRDebug_OnInputCycleAttrPrev(action : SInputAction) : bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    lrDebugAttrEditor.CycleAttribute(-1);
    lrDebugLabelManager.RefreshTargetOneliner();
    return true;
}

@addMethod(CR4Player)
public function LRDebug_OnInputCycleAttrNext(action : SInputAction) : bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    lrDebugAttrEditor.CycleAttribute(1);
    lrDebugLabelManager.RefreshTargetOneliner();
    return true;
}

// ---- Input: adjust attribute value ----

@addMethod(CR4Player)
public function LRDebug_OnInputAdjustDown(action : SInputAction) : bool {
    if (!lrDebugLabels || !action.value || !thePlayer) return false;

    // Mouse scroll wheel sends multiples of +/- 3.0 per event (fast scrolling yields higher numbers)
    lrDebugLabelManager.ApplyAttributeAdjustment(action.value * 0.333334f, lrDebugAttrEditor);
    return true;
}

// ---- Input: toggle rewriter on/off ----

@addMethod(CR4Player)
public function LRDebug_OnInputToggleRewriter(action : SInputAction) : bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    lrDebugLabelManager.ToggleRewriterOnTarget();
    return true;
}
