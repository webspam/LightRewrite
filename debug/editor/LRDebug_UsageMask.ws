enum ELRDebug_LUM_FlagState {
    LRDebug_LUM_Unset,
    LRDebug_LUM_On,
    LRDebug_LUM_Off
}

function LRDebug_GetUsageFlagState(
    edit: SLightRewriteUsageMaskEdit,
    flag: ELightRewriteUsageMask
): ELRDebug_LUM_FlagState {
    var bit: int = (int)flag;

    if ((edit.setBits & bit) != 0) return LRDebug_LUM_On;
    if ((edit.clearBits & bit) != 0) return LRDebug_LUM_Off;
    return LRDebug_LUM_Unset;
}

function LRDebug_WithUsageFlagState(
    edit: SLightRewriteUsageMaskEdit,
    flag: ELightRewriteUsageMask,
    flagState: ELRDebug_LUM_FlagState
): SLightRewriteUsageMaskEdit {
    var bit: int = (int)flag;

    edit.setBits = LR_ClearBits(edit.setBits, bit);
    edit.clearBits = LR_ClearBits(edit.clearBits, bit);
    if (flagState == LRDebug_LUM_Unset) return edit;

    if (flagState == LRDebug_LUM_On) edit.setBits = edit.setBits | bit;
    else edit.clearBits = edit.clearBits | bit;
    return edit;
}

function LRDebug_NextUsageFlagState(flagState: ELRDebug_LUM_FlagState): ELRDebug_LUM_FlagState {
    switch (flagState) {
        case LRDebug_LUM_Unset:  return LRDebug_LUM_On;
        case LRDebug_LUM_On:     return LRDebug_LUM_Off;
        default:                 return LRDebug_LUM_Unset;
    }
}

function LRDebug_NextVisibleUsageFlagState(
    effectiveState: ELRDebug_LUM_FlagState,
    inheritedState: ELRDebug_LUM_FlagState
): ELRDebug_LUM_FlagState {
    var nextState: ELRDebug_LUM_FlagState = LRDebug_NextUsageFlagState(effectiveState);

    if (nextState == LRDebug_LUM_Unset && inheritedState == effectiveState) {
        nextState = LRDebug_NextUsageFlagState(nextState);
    }
    return nextState;
}

function LRDebug_InheritedUsageMask(
    params: CLightRewriteSourceParams,
    type: name
): SLightRewriteUsageMaskEdit {
    var unset: SLightRewriteUsageMaskEdit;

    if (!params) return unset;
    if (type != 'spot') return params.usageMask;
    if (!params.spotlight || params.spotlight.spawn) return unset;

    return params.spotlight.usageMask;
}

function LRDebug_EffectiveUsageMask(
    params: CLightRewriteSourceParams,
    type: name,
    index: int
): SLightRewriteUsageMaskEdit {
    var unset: SLightRewriteUsageMaskEdit;
    var spotParams: CLightRewriteSpotlightParams;

    if (!params) return unset;
    if (type != 'spot') return params.GetEffectivePointLightParams(index).usageMask;

    spotParams = params.GetEffectiveSpotLightParams(index);
    if (!spotParams) return unset;
    return spotParams.usageMask;
}

function LRDebug_UsageFlagUndoLabel(flag: ELightRewriteUsageMask): string {
    switch (flag) {
        case LRLUM_ExcludeFromSceneRender:  return "LUM exclude from scene";
        case LRLUM_RenderToEnvProbe:        return "LUM env probe";
        case LRLUM_InteriorOnly:            return "LUM interior only";
        case LRLUM_ExteriorOnly:            return "LUM exterior only";
    }
    return "LUM";
}
