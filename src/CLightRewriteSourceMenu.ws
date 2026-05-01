/*
 * Base class for per-light-source Flash config menu settings.
 */
class CLightRewriteSourceMenu {
    // Mod settings IDs (must match XML Var id values)
    public const var TAG_ENABLED : name;
    public const var TAG_BRIGHTNESS : name;
    public const var TAG_RADIUS : name;
    public const var TAG_ATTENUATION : name;
    public const var TAG_SHADOW_DISTANCE : name;
    public const var TAG_SHADOW_RANGE : name;
    public const var TAG_SHADOW_BLEND : name;
    public const var TAG_OVERRIDE_COLOUR : name;
    public const var TAG_RED : name;
    public const var TAG_GREEN : name;
    public const var TAG_BLUE : name;
    public const var TAG_ALIGN_POINT_LIGHTS : name;

    // Reads the game config for this light source into the supplied params object.
    public function ReadGameConfig(gameConfig : CInGameConfigWrapper, groupTag : name, params : CLightRewriteSourceParams) {
        params.enabled = gameConfig.GetVarValue(groupTag, TAG_ENABLED);
        params.brightness = StringToFloat(gameConfig.GetVarValue(groupTag, TAG_BRIGHTNESS), params.brightness);
        params.radius = StringToFloat(gameConfig.GetVarValue(groupTag, TAG_RADIUS), params.radius);
        params.attenuation = StringToFloat(gameConfig.GetVarValue(groupTag, TAG_ATTENUATION), params.attenuation);
        params.shadowFadeDistance = StringToFloat(gameConfig.GetVarValue(groupTag, TAG_SHADOW_DISTANCE), params.shadowFadeDistance);
        params.shadowFadeRange = StringToFloat(gameConfig.GetVarValue(groupTag, TAG_SHADOW_RANGE), params.shadowFadeRange);
        params.shadowBlendFactor = StringToFloat(gameConfig.GetVarValue(groupTag, TAG_SHADOW_BLEND), params.shadowBlendFactor);
        params.shouldOverrideColour = gameConfig.GetVarValue(groupTag, TAG_OVERRIDE_COLOUR);
        params.color.Red = StringToInt(gameConfig.GetVarValue(groupTag, TAG_RED), params.color.Red);
        params.color.Green = StringToInt(gameConfig.GetVarValue(groupTag, TAG_GREEN), params.color.Green);
        params.color.Blue = StringToInt(gameConfig.GetVarValue(groupTag, TAG_BLUE), params.color.Blue);
    }

    // Reacts to menu option changes if the changed option is relevant to this source.
    // Designed to be called for every option-change event.
    public function OptionValueChanged(optionName : name, params : CLightRewriteSourceParams) {
        if (optionName == TAG_ENABLED || optionName == TAG_OVERRIDE_COLOUR) UpdateMenuDisabledState(params);
    }

    // Updates the disabled state of all options in this source's settings group.
    public function UpdateMenuDisabledState(params : CLightRewriteSourceParams) {
        var flashValueStorage : CScriptedFlashValueStorage;
        var dataArray : CScriptedFlashArray;

        flashValueStorage = theGame.GetGuiManager().GetRootMenu().GetSubMenu().GetMenuFlashValueStorage();
        dataArray = flashValueStorage.CreateTempFlashArray();

        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_BRIGHTNESS, !params.enabled);
        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_RADIUS, !params.enabled);
        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_ATTENUATION, !params.enabled);
        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_SHADOW_DISTANCE, !params.enabled);
        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_SHADOW_RANGE, !params.enabled);
        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_SHADOW_BLEND, !params.enabled);
        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_OVERRIDE_COLOUR, !params.enabled);
        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_RED, !params.enabled || !params.shouldOverrideColour);
        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_GREEN, !params.enabled || !params.shouldOverrideColour);
        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_BLUE, !params.enabled || !params.shouldOverrideColour);

        UpdateSpecialMenuDisabledState(flashValueStorage, dataArray, params);

        flashValueStorage.SetFlashArray("options.update_disabled", dataArray);
        theGame.GetGuiManager().ForceProcessFlashStorage();
    }

    // Virtual - override to add any additional options to the disabled state update.
    protected function UpdateSpecialMenuDisabledState(
        flashValueStorage : CScriptedFlashValueStorage,
        dataArray : CScriptedFlashArray,
        params : CLightRewriteSourceParams
    ) {}
}
