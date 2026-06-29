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
 * IK_NumPad6=(Action=LRDebug_Lock)
 * IK_NumPad4=(Action=LRDebug_ResetLight)
 * IK_NumPad5=(Action=LRDebug_SolveSpacing)
 * IK_NumPad4=(Action=LRDebug_ResetLight)
 * IK_Q=(Action=LRDebug_BrightnessModifier)
 * IK_1=(Action=LRDebug_RadiusModifier)
 * IK_5=(Action=LRDebug_SoftnessModifier)
 *
 * Hold-to-edit reads the engine's mouse-Y axis (GI_MouseDampY) directly, so it needs
 * no extra context or binding: holding a modifier locks the camera and feeds mouse-Y
 * into the selected attribute.
 *
 * In spot mode the point-only modifier keys are reused: UseSpotlightColor edits inner
 * angle, AlignPointLights edits outer angle, AlignOffsetZ edits the spotlight's offset Z,
 * and the dedicated SoftnessModifier edits softness.
 */

@addField(CR4Player) public var lrDebugLabels: bool;
@addField(CR4Player) public var lrDebugLabelManager: LRDebug_LabelManager;
@addField(CR4Player) public var lrDebugAttrEditor: LRDebug_AttributeEditor;
@addField(CR4Player) public var lrDebugTargetMarkers: LRDebug_TargetMarkers;
@addField(CR4Player) public var lrDebugAdjusting: bool;

/*
 * Lifecycle
 */

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
    lrDebugTargetMarkers = new LRDebug_TargetMarkers in this;
    lrDebugTargetMarkers.Init();
    theInput.RegisterListener(this, 'LRDebug_OnInputToggleLabels', 'LRDebug_ToggleLabels');
    theInput.RegisterListener(this, 'LRDebug_OnInputToggleLabelPaths', 'LRDebug_ToggleLabelPaths');
    theInput.RegisterListener(this, 'LRDebug_OnInputLock', 'LRDebug_Lock');
    theInput.RegisterListener(this, 'LRDebug_OnInputCycleAttrPrev', 'LRDebug_CycleAttrPrev');
    theInput.RegisterListener(this, 'LRDebug_OnInputCycleAttrNext', 'LRDebug_CycleAttrNext');
    theInput.RegisterListener(this, 'LRDebug_OnInputCycleLight', 'LRDebug_CycleLight');
    theInput.RegisterListener(this, 'LRDebug_OnInputToggleRewriter', 'LRDebug_ToggleRewriter');
    theInput.RegisterListener(this, 'LRDebug_OnInputExportEdited', 'LRDebug_ExportEdited');
    theInput.RegisterListener(this, 'LRDebug_OnInputResetLight', 'LRDebug_ResetLight');
    theInput.RegisterListener(this, 'LRDebug_OnInputSolveSpacing', 'LRDebug_SolveSpacing');
    theInput.RegisterListener(this, 'LRDebug_OnInputResetLight', 'LRDebug_ResetLight');
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
    theInput.RegisterListener(this, 'LRDebug_OnSoftnessModifier', 'LRDebug_SoftnessModifier');
    theInput.RegisterListener(this, 'LRDebug_OnMouseAxisX', 'GI_MouseDampX');
    theInput.RegisterListener(this, 'LRDebug_OnMouseAxisY', 'GI_MouseDampY');

    theInput.RegisterListener(this, 'LRDebug_OnModifierKeyPressed', 'LRDebug_ModifierKey');
    theInput.RegisterListener(this, 'LRDebug_OnAltPressed', 'ShowDeveloperModeAlt');
}

/** Update labels when the mod is toggle on/off */
@wrapMethod(CLightRewriteSettings)
function OptionValueChanged(groupId: int, optionName: name, optionValue: string) {
    var wasEnabled: bool = isEnabled;

    wrappedMethod(groupId, optionName, optionValue);

    if (
        isEnabled != wasEnabled &&
        thePlayer &&
        thePlayer.lrDebugLabels &&
        thePlayer.lrDebugLabelManager
    ) {
        thePlayer.lrDebugLabelManager.RefreshTargetOneliner();
    }
}

/** Track lights that were edited */
@wrapMethod(CLightRewriteSettings)
function GetAllLightSourceTags(): array<name> {
    var tags: array<name>;

    tags = wrappedMethod();
    tags.PushBack('LR_DebugLight');
    return tags;
}

@addMethod(CR4Player)
timer function LRDebug_RefreshOnelinersTimer(dt: float, id: int) {
    if (!lrDebugLabels || !theGame || !thePlayer) return;
    if (theInput.IsActionPressed('LRDebug_CtrlModifier')) return;

    lrDebugLabelManager.Scan();
}

/*
 * Input handlers
 */

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
        lrDebugLabelManager.HidePathLabel();
    }

    return true;
}

@wrapMethod(CExplorationStateManager)
function PostStateChange() {
    wrappedMethod();

    if (thePlayer.lrDebugLabels && theInput.GetContext() == thePlayer.GetExplorationInputContext()) {
        theInput.StoreContext('LRDebug');
    }
}

@addMethod(CR4Player)
public function LRDebug_OnInputLock(action: SInputAction): bool {
    if (!IsPressed(action) || !thePlayer) return false;

    lrDebugLabelManager.ToggleLock();
    return true;
}

@addMethod(CR4Player)
public function LRDebug_OnModifierKeyPressed(action: SInputAction): bool {
    if (
        lrDebugLabels &&
        (IsPressed(action) || IsReleased(action))
    ) {
        LogChannel('LRDebug', "LRDebug_ModifierKeyPressed");
        lrDebugLabelManager.RegenerateNearbyOneliners();
    }

    return false;
}

@addMethod(CR4Player)
public function LRDebug_OnAltPressed(action: SInputAction): bool {
    if (
        lrDebugLabels &&
        (IsPressed(action) || IsReleased(action))
    ) {
        lrDebugLabelManager.RegenerateNearbyOneliners();
    }

    return false;
}

@addMethod(CR4Player)
public function LRDebug_OnInputToggleLabelPaths(action: SInputAction): bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    lrDebugLabelManager.TogglePathLabels();
    return true;
}

/*
 * Input: Attributes
 */

@addMethod(CR4Player)
public function LRDebug_OnInputCycleAttrPrev(action: SInputAction): bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    lrDebugLabelManager.CycleSelectedAttribute(lrDebugAttrEditor, -1);
    return true;
}

@addMethod(CR4Player)
public function LRDebug_OnInputCycleAttrNext(action: SInputAction): bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    lrDebugLabelManager.CycleSelectedAttribute(lrDebugAttrEditor, 1);
    return true;
}

@addMethod(CR4Player)
public function LRDebug_OnInputCycleLight(action: SInputAction): bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    lrDebugLabelManager.SwapLightSelection(lrDebugAttrEditor);
    return true;
}

@addField(CInputManager) public var lrDebug: LRDebug_Input;

@wrapMethod(CR4IngameMenu)
function OnConfigUI() {
    var iManager: CInputManager = theInput;

    wrappedMethod();

    iManager.lrDebug = new LRDebug_Input in iManager;
}

@addMethod(CR4Player)
public function LRDebug_OnInputToggleRewriter(action: SInputAction): bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    lrDebugLabelManager.ToggleRewriterOnTarget();
    return true;
}

@addMethod(CR4Player)
public function LRDebug_OnInputExportEdited(action: SInputAction): bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    LRDebug_ExportEditedLights();
    return true;
}

@addMethod(CR4Player)
public function LRDebug_OnInputResetLight(action: SInputAction): bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    lrDebugLabelManager.ResetTarget();
    return true;
}

@addMethod(CR4Player)
public function LRDebug_OnInputSolveSpacing(action: SInputAction): bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    theGame.lightRewrite.ApplySpacing();
    LogChannel('LRDebug', "LRDebug spacing: re-spaced all lights");
    return true;
}

/*
 * Analogue input handlers
 */

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

/** Spot mode hold-edits inner angle; point mode toggles the bool */
@addMethod(CR4Player)
public function LRDebug_OnUseSpotlightColorModifier(action: SInputAction): bool {
    if (lrDebugLabelManager.GetTargetLightType(lrDebugAttrEditor) == 'spot') {
        return LRDebug_EnterAdjust(action, 6);
    }
    return LRDebug_ToggleAttr(action, 6);
}

/** Spot mode hold-edits outer angle; point mode toggles the bool */
@addMethod(CR4Player)
public function LRDebug_OnAlignPointLightsModifier(action: SInputAction): bool {
    if (lrDebugLabelManager.GetTargetLightType(lrDebugAttrEditor) == 'spot') {
        return LRDebug_EnterAdjust(action, 7);
    }
    return LRDebug_ToggleAttr(action, 7);
}

@addMethod(CR4Player)
public function LRDebug_OnAlignOffsetZModifier(action: SInputAction): bool {
    return LRDebug_EnterAdjust(action, 8);
}

@addMethod(CR4Player)
public function LRDebug_OnSoftnessModifier(action: SInputAction): bool {
    return LRDebug_EnterAdjust(action, 13);
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

@addMethod(CR4Player)
public function LRDebug_ToggleAttr(action: SInputAction, attrIndex: int): bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    lrDebugAttrEditor.SetAttributeIndex(attrIndex);
    lrDebugLabelManager.ApplyToggle(lrDebugAttrEditor);
    return true;
}

/** Holding Alt while editing the offset turns vertical mouse movement into XY dragging instead of Z adjustment */
@addMethod(CR4Player)
public function LRDebug_MovingOffsetXY(): bool {
    return lrDebugAttrEditor.IsEditingOffset()
        && theInput.IsActionPressed('ShowDeveloperModeAlt');
}

@addMethod(CR4Player)
public function LRDebug_OnMouseAxisX(action: SInputAction): bool {
    var modifier: float = 1.0;

    if (!lrDebugAdjusting || action.value == 0.0 || !thePlayer) return false;
    if (!LRDebug_MovingOffsetXY()) return false;

    if (theInput.IsActionPressed('LRDebug_CtrlModifier')) {
        modifier = 0.2;
    }

    lrDebugLabelManager.MoveTargetXY(
        action.value * theInput.lrDebug.ADJUST_AXIS_SENSITIVITY * modifier,
        0.0,
        lrDebugAttrEditor
    );
    return true;
}

@addMethod(CR4Player)
public function LRDebug_OnMouseAxisY(action: SInputAction): bool {
    var modifier: float = 1.0;

    if (!lrDebugAdjusting || action.value == 0.0 || !thePlayer) return false;

    if (theInput.IsActionPressed('LRDebug_CtrlModifier')) {
        modifier = 0.2;
    }

    if (LRDebug_MovingOffsetXY()) {
        lrDebugLabelManager.MoveTargetXY(
            0.0,
            -action.value * theInput.lrDebug.ADJUST_AXIS_SENSITIVITY * modifier,
            lrDebugAttrEditor
        );
        return true;
    }

    lrDebugLabelManager.ApplyContinuousAdjustment(
        -action.value * theInput.lrDebug.ADJUST_AXIS_SENSITIVITY * modifier,
        lrDebugAttrEditor
    );
    return true;
}
