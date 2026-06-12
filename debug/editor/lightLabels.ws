/**
 * Light Rewrite's in-game light authoring overlay.
 *
 * Wires input actions to the label manager, attribute editor, and accelerator.
 * All domain logic lives in the dedicated files in this folder.
 *
 * Requires: mod_sharedutils_oneliners via SU_Oneliner
 *
 * Example input.settings (under [LRDebug]):
 *
 * IK_NumPad7=(Action=LRDebug_ToggleLabels)
 * IK_NumPad8=(Action=LRDebug_ToggleLabelPaths)
 * IK_NumPad9=(Action=LRDebug_ExportEdited)
 * IK_Q=(Action=LRDebug_BrightnessModifier)
 * IK_1=(Action=LRDebug_RadiusModifier)
 *
 * Hold-to-edit reads the engine's mouse-Y axis (GI_MouseDampY) directly, so it needs
 * no extra context or binding: holding a modifier locks the camera and feeds mouse-Y
 * into the selected attribute.
 */

// ---- CR4Player fields ----

@addField(CR4Player) public var lrDebugLabels: bool;
@addField(CR4Player) public var lrDebugLabelManager: LRDebug_LabelManager;
@addField(CR4Player) public var lrDebugAttrEditor: LRDebug_AttributeEditor;
@addField(CR4Player) public var lrDebugAdjusting: bool;
// ---- Lifecycle ----

@wrapMethod(CR4Player)
function OnSpawned(spawnData: SEntitySpawnData) {
    wrappedMethod(spawnData);

    AddTimer('LRDebug_DeferredLabelInstall', 1.f, false);
}

@addMethod(CR4Player)
timer function LRDebug_DeferredLabelInstall(dt: float, id: int) {
    if (!theGame || !thePlayer) return;

    lrDebugLabelManager = new LRDebug_LabelManager in this;
    lrDebugLabelManager.Init();
    lrDebugAttrEditor = new LRDebug_AttributeEditor in this;
    lrDebugAttrEditor.Init();
    theInput.RegisterListener(this, 'LRDebug_OnInputToggleLabels', 'LRDebug_ToggleLabels');
    theInput.RegisterListener(this, 'LRDebug_OnInputToggleLabelPaths', 'LRDebug_ToggleLabelPaths');
    theInput.RegisterListener(this, 'LRDebug_OnInputCycleAttrPrev', 'LRDebug_CycleAttrPrev');
    theInput.RegisterListener(this, 'LRDebug_OnInputCycleAttrNext', 'LRDebug_CycleAttrNext');
    theInput.RegisterListener(this, 'LRDebug_OnInputAdjustDown', 'LRDebug_AdjustDown');
    theInput.RegisterListener(this, 'LRDebug_OnInputToggleRewriter', 'LRDebug_ToggleRewriter');
    theInput.RegisterListener(this, 'LRDebug_OnInputExportEdited', 'LRDebug_ExportEdited');
    theInput.RegisterListener(this, 'LRDebug_OnBrightnessModifier', 'LRDebug_BrightnessModifier');
    theInput.RegisterListener(this, 'LRDebug_OnRadiusModifier', 'LRDebug_RadiusModifier');
    theInput.RegisterListener(this, 'LRDebug_OnAttenuationModifier', 'LRDebug_AttenuationModifier');
    theInput.RegisterListener(
        this,
        'LRDebug_OnShadowFadeDistanceModifier',
        'LRDebug_ShadowFadeDistanceModifier'
    );
    theInput.RegisterListener(
        this,
        'LRDebug_OnShadowFadeRangeModifier',
        'LRDebug_ShadowFadeRangeModifier'
    );
    theInput.RegisterListener(
        this,
        'LRDebug_OnShadowBlendFactorModifier',
        'LRDebug_ShadowBlendFactorModifier'
    );
    theInput.RegisterListener(
        this,
        'LRDebug_OnUseSpotlightColorModifier',
        'LRDebug_UseSpotlightColorModifier'
    );
    theInput.RegisterListener(
        this,
        'LRDebug_OnAlignPointLightsModifier',
        'LRDebug_AlignPointLightsModifier'
    );
    theInput.RegisterListener(
        this,
        'LRDebug_OnAlignOffsetZModifier',
        'LRDebug_AlignOffsetZModifier'
    );
    theInput.RegisterListener(
        this,
        'LRDebug_OnOverrideColourModifier',
        'LRDebug_OverrideColourModifier'
    );
    theInput.RegisterListener(this, 'LRDebug_OnColourRModifier', 'LRDebug_ColourRModifier');
    theInput.RegisterListener(this, 'LRDebug_OnColourGModifier', 'LRDebug_ColourGModifier');
    theInput.RegisterListener(this, 'LRDebug_OnColourBModifier', 'LRDebug_ColourBModifier');
    theInput.RegisterListener(this, 'LRDebug_OnAdjustAxis', 'GI_MouseDampY');
}

// ---- Refresh timer ----

@addMethod(CR4Player)
timer function LRDebug_RefreshOnelinersTimer(dt: float, id: int) {
    if (!lrDebugLabels || !theGame || !thePlayer) return;

    lrDebugLabelManager.Scan();
}

// ---- Input: toggle labels ----

@addMethod(CR4Player)
public function LRDebug_OnInputToggleLabels(action: SInputAction): bool {
    if (!IsPressed(action) || !thePlayer) return false;

    lrDebugLabels = !lrDebugLabels;
    LogChannel('LRDebug', "LRDebug_Toggle: " + lrDebugLabels);

    RemoveTimer('LRDebug_RefreshOnelinersTimer');
    if (lrDebugLabels) {
        theInput.StoreContext('LRDebug');
        AddTimer('LRDebug_RefreshOnelinersTimer', 0.1f, true);
    }
    else {
        theInput.RestoreContext('LRDebug', true);
    }

    return true;
}

// ---- Input: toggle path labels ----

@addMethod(CR4Player)
public function LRDebug_OnInputToggleLabelPaths(action: SInputAction): bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    lrDebugLabelManager.TogglePathLabels();
    return true;
}

// ---- Input: cycle attribute ----

@addMethod(CR4Player)
public function LRDebug_OnInputCycleAttrPrev(action: SInputAction): bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    lrDebugAttrEditor.CycleAttribute(-1);
    lrDebugLabelManager.RefreshTargetOneliner();
    return true;
}

@addMethod(CR4Player)
public function LRDebug_OnInputCycleAttrNext(action: SInputAction): bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    lrDebugAttrEditor.CycleAttribute(1);
    lrDebugLabelManager.RefreshTargetOneliner();
    return true;
}

@addField(CInputManager) public var lrDebug: LRDebug_Input;

@wrapMethod(CR4IngameMenu)
function OnConfigUI() {
    var iManager: CInputManager = theInput;

    wrappedMethod();

    iManager.lrDebug = new LRDebug_Input in iManager;
}

// ---- Input: adjust attribute value ----

@addMethod(CR4Player)
public function LRDebug_OnInputAdjustDown(action: SInputAction): bool {
    if (!lrDebugLabels || !action.value || !thePlayer) return false;

    if (theInput.IsActionPressed('ShowDeveloperModeAlt')) {
        lrDebugAttrEditor.CycleAttribute((int)SignF(action.value) * -1);
        lrDebugLabelManager.RefreshTargetOneliner();
        return true;
    }

    // Mouse scroll wheel sends multiples of +/- 3.0 per event (fast scrolling yields higher numbers)
    lrDebugLabelManager.ApplyAttributeAdjustment(action.value * 0.333333f, lrDebugAttrEditor);
    return true;
}

// ---- Input: toggle rewriter on/off ----

@addMethod(CR4Player)
public function LRDebug_OnInputToggleRewriter(action: SInputAction): bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    lrDebugLabelManager.ToggleRewriterOnTarget();
    return true;
}

// ---- Input: export edited lights ----

@addMethod(CR4Player)
public function LRDebug_OnInputExportEdited(action: SInputAction): bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    LRDebug_ExportEditedLights();
    return true;
}

// ---- Input: hold-to-edit analog modifiers ----

@addMethod(CR4Player)
public function LRDebug_OnBrightnessModifier(action: SInputAction): bool {
    return LRDebug_EnterAdjust(action, 0);
}

@addMethod(CR4Player)
public function LRDebug_OnRadiusModifier(action: SInputAction): bool {
    return LRDebug_EnterAdjust(action, 1);
}

@addMethod(CR4Player)
public function LRDebug_OnAttenuationModifier(action: SInputAction): bool {
    return LRDebug_EnterAdjust(action, 2);
}

@addMethod(CR4Player)
public function LRDebug_OnShadowFadeDistanceModifier(action: SInputAction): bool {
    return LRDebug_EnterAdjust(action, 3);
}

@addMethod(CR4Player)
public function LRDebug_OnShadowFadeRangeModifier(action: SInputAction): bool {
    return LRDebug_EnterAdjust(action, 4);
}

@addMethod(CR4Player)
public function LRDebug_OnShadowBlendFactorModifier(action: SInputAction): bool {
    return LRDebug_EnterAdjust(action, 5);
}

@addMethod(CR4Player)
public function LRDebug_OnUseSpotlightColorModifier(action: SInputAction): bool {
    return LRDebug_ToggleAttr(action, 6);
}

@addMethod(CR4Player)
public function LRDebug_OnAlignPointLightsModifier(action: SInputAction): bool {
    return LRDebug_ToggleAttr(action, 7);
}

@addMethod(CR4Player)
public function LRDebug_OnAlignOffsetZModifier(action: SInputAction): bool {
    return LRDebug_EnterAdjust(action, 8);
}

@addMethod(CR4Player)
public function LRDebug_OnOverrideColourModifier(action: SInputAction): bool {
    return LRDebug_ToggleAttr(action, 9);
}

@addMethod(CR4Player)
public function LRDebug_OnColourRModifier(action: SInputAction): bool {
    return LRDebug_EnterAdjust(action, 10);
}

@addMethod(CR4Player)
public function LRDebug_OnColourGModifier(action: SInputAction): bool {
    return LRDebug_EnterAdjust(action, 11);
}

@addMethod(CR4Player)
public function LRDebug_OnColourBModifier(action: SInputAction): bool {
    return LRDebug_EnterAdjust(action, 12);
}

/**
 * On key-press, lock the camera (rotation stops but GI_MouseDamp values keep flowing)
 * and flag adjust mode so the mouse-Y listener edits the chosen attribute live; the
 * matching unlock happens on release.
 */
@addMethod(CR4Player)
public function LRDebug_EnterAdjust(action: SInputAction, attrIndex: int): bool {
    if (!lrDebugLabels || !thePlayer) return false;

    if (IsPressed(action)) {
        lrDebugAttrEditor.SetAttributeIndex(attrIndex);
        lrDebugAttrEditor.ResetAdjustAccumulator();
        lrDebugLabelManager.RefreshTargetOneliner();
        thePlayer.EnableManualCameraControl(false, theInput.lrDebug.CAMERA_LOCK_SOURCE);
        lrDebugAdjusting = true;
        return true;
    }

    if (IsReleased(action)) {
        thePlayer.EnableManualCameraControl(true, theInput.lrDebug.CAMERA_LOCK_SOURCE);
        lrDebugAdjusting = false;
        return true;
    }

    return false;
}

/** Bools toggle on key-press: flip the value and refresh, no camera lock or analog hold. */
@addMethod(CR4Player)
public function LRDebug_ToggleAttr(action: SInputAction, attrIndex: int): bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    lrDebugAttrEditor.SetAttributeIndex(attrIndex);
    lrDebugLabelManager.ApplyToggle(lrDebugAttrEditor);
    return true;
}

/**
 * Push listener on the engine's mouse-Y axis. Fires whenever the mouse moves, but only
 * edits while a modifier is held; the camera is locked then, so the deltas are ours.
 */
@addMethod(CR4Player)
public function LRDebug_OnAdjustAxis(action: SInputAction): bool {
    if (!lrDebugAdjusting || action.value == 0.0 || !thePlayer) return false;

    lrDebugLabelManager.ApplyContinuousAdjustment(
        -action.value * theInput.lrDebug.ADJUST_AXIS_SENSITIVITY,
        lrDebugAttrEditor
    );
    return true;
}
