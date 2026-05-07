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
    theInput.RegisterListener(this, 'LRDebug_OnSelectBrightness', 'LRDebug_SelectBrightness');
    theInput.RegisterListener(this, 'LRDebug_OnSelectRadius', 'LRDebug_SelectRadius');
    theInput.RegisterListener(this, 'LRDebug_OnSelectAttenuation', 'LRDebug_SelectAttenuation');
    theInput.RegisterListener(this, 'LRDebug_OnSelectShadowFadeDistance', 'LRDebug_SelectShadowFadeDistance');
    theInput.RegisterListener(this, 'LRDebug_OnSelectShadowFadeRange', 'LRDebug_SelectShadowFadeRange');
    theInput.RegisterListener(this, 'LRDebug_OnSelectShadowBlendFactor', 'LRDebug_SelectShadowBlendFactor');
    theInput.RegisterListener(this, 'LRDebug_OnSelectAlignOffsetZ', 'LRDebug_SelectAlignOffsetZ');
    theInput.RegisterListener(this, 'LRDebug_OnSelectOverrideColour', 'LRDebug_SelectOverrideColour');
    theInput.RegisterListener(this, 'LRDebug_OnSelectColourR', 'LRDebug_SelectColourR');
    theInput.RegisterListener(this, 'LRDebug_OnSelectColourG', 'LRDebug_SelectColourG');
    theInput.RegisterListener(this, 'LRDebug_OnSelectColourB', 'LRDebug_SelectColourB');
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

    if (theInput.IsActionPressed('ShowDeveloperModeAlt')) {
        lrDebugAttrEditor.CycleAttribute((int)SignF(action.value) * -1);
        lrDebugLabelManager.RefreshTargetOneliner();
        return true;
    }

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

// ---- Input: select attribute ----

@addMethod(CR4Player)
public function LRDebug_OnSelectBrightness(action : SInputAction) : bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    if (lrDebugLabels == true) {
        // lrDebugLabelManager.SelectBrightness();
        lrDebugAttrEditor.SetAttributeIndex(0);
        return true;
    }
    return false;
}

@addMethod(CR4Player)
public function LRDebug_OnSelectRadius(action : SInputAction) : bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    if (lrDebugLabels == true) {
        // lrDebugLabelManager.SelectRadius();
        lrDebugAttrEditor.SetAttributeIndex(1);
        return true;
    }
    return false;
}

@addMethod(CR4Player)
public function LRDebug_OnSelectAttenuation(action : SInputAction) : bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    if (lrDebugLabels == true) {
        // lrDebugLabelManager.SelectAttenuation();
        lrDebugAttrEditor.SetAttributeIndex(2);
        return true;
    }
    return false;
}

@addMethod(CR4Player)
public function LRDebug_OnSelectShadowFadeDistance(action : SInputAction) : bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    if (lrDebugLabels == true) {
        // lrDebugLabelManager.SelectShadowFadeDistance();
        lrDebugAttrEditor.SetAttributeIndex(3);
        return true;
    }
    return false;
}

@addMethod(CR4Player)
public function LRDebug_OnSelectShadowFadeRange(action : SInputAction) : bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    if (lrDebugLabels == true) {
        // lrDebugLabelManager.SelectShadowFadeRange();
        lrDebugAttrEditor.SetAttributeIndex(4);
        return true;
    }
    return false;
}

@addMethod(CR4Player)
public function LRDebug_OnSelectShadowBlendFactor(action : SInputAction) : bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    if (lrDebugLabels == true) {
        // lrDebugLabelManager.SelectShadowBlendFactor();
        lrDebugAttrEditor.SetAttributeIndex(5);
        return true;
    }
    return false;
}

@addMethod(CR4Player)
public function LRDebug_OnSelectAlignOffsetZ(action : SInputAction) : bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    if (lrDebugLabels == true) {
        // lrDebugLabelManager.SelectAlignOffsetZ();
        lrDebugAttrEditor.SetAttributeIndex(8);
        return true;
    }
    return false;
}

@addMethod(CR4Player)
public function LRDebug_OnSelectOverrideColour(action : SInputAction) : bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    if (lrDebugLabels == true) {
        // lrDebugLabelManager.SelectOverrideColour();
        lrDebugAttrEditor.SetAttributeIndex(9);
        return true;
    }
    return false;
}

@addMethod(CR4Player)
public function LRDebug_OnSelectColourR(action : SInputAction) : bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    if (lrDebugLabels == true) {
        // lrDebugLabelManager.SelectColourR();
        lrDebugAttrEditor.SetAttributeIndex(10);
        return true;
    }
    return false;
}

@addMethod(CR4Player)
public function LRDebug_OnSelectUseSpotlightColor(action : SInputAction) : bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    if (lrDebugLabels == true) {
        // lrDebugLabelManager.SelectUseSpotlightColor();
        lrDebugAttrEditor.SetAttributeIndex(11);
        return true;
    }
    return false;
}

@addMethod(CR4Player)
public function LRDebug_OnSelectAlignPointLights(action : SInputAction) : bool {
    if (!lrDebugLabels || !IsPressed(action) || !thePlayer) return false;

    if (lrDebugLabels == true) {
        // lrDebugLabelManager.SelectAlignPointLights();
        lrDebugAttrEditor.SetAttributeIndex(12);
        return true;
    }
    return false;
}
