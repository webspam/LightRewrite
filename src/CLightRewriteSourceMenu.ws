/*
 * Base class for per-light-source Flash config menu settings.
 */
class CLightRewriteSourceMenu {
    // Mod settings IDs (must match XML Var id values)
    public const var TAG_ENABLED           : name;
    public const var TAG_BRIGHTNESS        : name;
    public const var TAG_RADIUS            : name;
    public const var TAG_ATTENUATION       : name;
    public const var TAG_SHADOW_DISTANCE   : name;
    public const var TAG_SHADOW_RANGE      : name;
    public const var TAG_SHADOW_BLEND      : name;
    public const var TAG_OVERRIDE_COLOUR   : name;
    public const var TAG_RED               : name;
    public const var TAG_GREEN             : name;
    public const var TAG_BLUE              : name;
    public const var TAG_ALIGN_POINT_LIGHTS: name;

    // Reads the game config for this light source into the supplied params object.
    public function ReadGameConfig(
        gameConfig: CInGameConfigWrapper,
        groupTag: name,
        params: CLightRewriteSourceParams
    ) {
        params.enabled.value = gameConfig.GetVarValue(groupTag, TAG_ENABLED);

        params.brightness.has = true;
        params.brightness.value = StringToFloat(gameConfig.GetVarValue(groupTag, TAG_BRIGHTNESS), params.brightness.value);

        params.radius.has = true;
        params.radius.value = StringToFloat(gameConfig.GetVarValue(groupTag, TAG_RADIUS), params.radius.value);

        params.attenuation.has = true;
        params.attenuation.value = StringToFloat(gameConfig.GetVarValue(groupTag, TAG_ATTENUATION), params.attenuation.value);

        params.shadowFadeDistance.has = true;
        params.shadowFadeDistance.value = StringToFloat(gameConfig.GetVarValue(groupTag, TAG_SHADOW_DISTANCE), params.shadowFadeDistance.value);

        params.shadowFadeRange.has = true;
        params.shadowFadeRange.value = StringToFloat(gameConfig.GetVarValue(groupTag, TAG_SHADOW_RANGE), params.shadowFadeRange.value);

        params.shadowBlendFactor.has = true;
        params.shadowBlendFactor.value = StringToFloat(gameConfig.GetVarValue(groupTag, TAG_SHADOW_BLEND), params.shadowBlendFactor.value);

        params.color.has = gameConfig.GetVarValue(groupTag, TAG_OVERRIDE_COLOUR);
        params.color.value.Red = StringToInt(gameConfig.GetVarValue(groupTag, TAG_RED), params.color.value.Red);
        params.color.value.Green = StringToInt(gameConfig.GetVarValue(groupTag, TAG_GREEN), params.color.value.Green);
        params.color.value.Blue = StringToInt(gameConfig.GetVarValue(groupTag, TAG_BLUE), params.color.value.Blue);
    }

    // Reacts to menu option changes if the changed option is relevant to this source.
    // Designed to be called for every option-change event.
    public function OptionValueChanged(optionName: name, params: CLightRewriteSourceParams) {
        if (optionName == TAG_ENABLED || optionName == TAG_OVERRIDE_COLOUR) {
            UpdateMenuDisabledState(params);
        }
        if (optionName == TAG_ENABLED) theGame.lightRewrite.SetGlobalOverride(params);
    }

    // Updates the disabled state of all options in this source's settings group.
    public function UpdateMenuDisabledState(params: CLightRewriteSourceParams) {
        var flashValueStorage: CScriptedFlashValueStorage;
        var dataArray: CScriptedFlashArray;

        flashValueStorage = theGame.GetGuiManager().GetRootMenu().GetSubMenu().GetMenuFlashValueStorage();
        dataArray = flashValueStorage.CreateTempFlashArray();

        LR_SetMenuOptionDisabled(
            flashValueStorage,
            dataArray,
            TAG_BRIGHTNESS,
            !params.enabled.value
        );
        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_RADIUS, !params.enabled.value);
        LR_SetMenuOptionDisabled(
            flashValueStorage,
            dataArray,
            TAG_ATTENUATION,
            !params.enabled.value
        );
        LR_SetMenuOptionDisabled(
            flashValueStorage,
            dataArray,
            TAG_SHADOW_DISTANCE,
            !params.enabled.value
        );
        LR_SetMenuOptionDisabled(
            flashValueStorage,
            dataArray,
            TAG_SHADOW_RANGE,
            !params.enabled.value
        );
        LR_SetMenuOptionDisabled(
            flashValueStorage,
            dataArray,
            TAG_SHADOW_BLEND,
            !params.enabled.value
        );
        LR_SetMenuOptionDisabled(
            flashValueStorage,
            dataArray,
            TAG_OVERRIDE_COLOUR,
            !params.enabled.value
        );
        LR_SetMenuOptionDisabled(
            flashValueStorage,
            dataArray,
            TAG_RED,
            !params.enabled.value || !params.color.has
        );
        LR_SetMenuOptionDisabled(
            flashValueStorage,
            dataArray,
            TAG_GREEN,
            !params.enabled.value || !params.color.has
        );
        LR_SetMenuOptionDisabled(
            flashValueStorage,
            dataArray,
            TAG_BLUE,
            !params.enabled.value || !params.color.has
        );

        UpdateSpecialMenuDisabledState(flashValueStorage, dataArray, params);

        flashValueStorage.SetFlashArray("options.update_disabled", dataArray);
        theGame.GetGuiManager().ForceProcessFlashStorage();
    }

    // Virtual - override to add any additional options to the disabled state update.
    protected function UpdateSpecialMenuDisabledState(
        flashValueStorage: CScriptedFlashValueStorage,
        dataArray: CScriptedFlashArray,
        params: CLightRewriteSourceParams
    ) {}
}
