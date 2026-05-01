/*
 * Base class for per-light-source settings.
 */
class CLightRewriteSourceParams {
    // The tag that will identify this source in the game
    public const var tag : name;

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

    // Whether this light source type should be rewritten
    public var enabled : bool;

    // Light source brightness
    public var brightness : float;
    // The cutoff radius (sphere)
    public var radius : float;
    // Light attenuation - how quickly the light fades out with distance
    public var attenuation : float;
    // The distance the player is from a light source before the shadow starts to fade
    public var shadowFadeDistance : float;
    // The range of the shadow fade - how quickly the shadow fades out from shadowFadeDistance
    public var shadowFadeRange : float;
    public var shadowBlendFactor : float;

    // If we should override the light source colour
    public var shouldOverrideColour : bool;
    public var color : Color;

    // Whether to align point lights to the light source - *many* point lights have been moved manually
    public var alignPointLights : bool;
    // Offset to add when aligning point lights
    public var pointLightOffset : Vector;

    // Whether to copy the spotlight colour to point lights
    // By default, many candles use low-radius, very red point lights for a close-up glow offset from
    // the bluish scene lighting, and a spotlight for normal mid-range lighting.
    public var useSpotlightColor : bool;

    // Virtual constructor
    public function Init() {}

    // Reads the game config for this light source.
    public function ReadGameConfig(gameConfig : CInGameConfigWrapper, groupTag : name) {
        enabled = gameConfig.GetVarValue(groupTag, TAG_ENABLED);
        brightness = StringToFloat(gameConfig.GetVarValue(groupTag, TAG_BRIGHTNESS), brightness);
        radius = StringToFloat(gameConfig.GetVarValue(groupTag, TAG_RADIUS), radius);
        attenuation = StringToFloat(gameConfig.GetVarValue(groupTag, TAG_ATTENUATION), attenuation);
        shadowFadeDistance = StringToFloat(gameConfig.GetVarValue(groupTag, TAG_SHADOW_DISTANCE), shadowFadeDistance);
        shadowFadeRange = StringToFloat(gameConfig.GetVarValue(groupTag, TAG_SHADOW_RANGE), shadowFadeRange);
        shadowBlendFactor = StringToFloat(gameConfig.GetVarValue(groupTag, TAG_SHADOW_BLEND), shadowBlendFactor);
        shouldOverrideColour = gameConfig.GetVarValue(groupTag, TAG_OVERRIDE_COLOUR);
        color.Red = StringToInt(gameConfig.GetVarValue(groupTag, TAG_RED), color.Red);
        color.Green = StringToInt(gameConfig.GetVarValue(groupTag, TAG_GREEN), color.Green);
        color.Blue = StringToInt(gameConfig.GetVarValue(groupTag, TAG_BLUE), color.Blue);
    }

    // Reacts to menu option changes if the changed option is relevant to this source.
    // Designed to be called for every option-change event.
    public function OptionValueChanged(optionName : name) {
        if (optionName == TAG_ENABLED || optionName == TAG_OVERRIDE_COLOUR) UpdateMenuDisabledState();
    }

    // Updates the disabled state of all options in this source's settings group.
    public function UpdateMenuDisabledState() {
        var flashValueStorage : CScriptedFlashValueStorage;
        var dataArray : CScriptedFlashArray;

        flashValueStorage = theGame.GetGuiManager().GetRootMenu().GetSubMenu().GetMenuFlashValueStorage();
        dataArray = flashValueStorage.CreateTempFlashArray();

        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_BRIGHTNESS, !enabled);
        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_RADIUS, !enabled);
        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_ATTENUATION, !enabled);
        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_SHADOW_DISTANCE, !enabled);
        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_SHADOW_RANGE, !enabled);
        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_SHADOW_BLEND, !enabled);
        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_OVERRIDE_COLOUR, !enabled);
        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_RED, !enabled || !shouldOverrideColour);
        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_GREEN, !enabled || !shouldOverrideColour);
        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_BLUE, !enabled || !shouldOverrideColour);

        UpdateSpecialMenuDisabledState(flashValueStorage, dataArray);

        flashValueStorage.SetFlashArray("options.update_disabled", dataArray);
        theGame.GetGuiManager().ForceProcessFlashStorage();
    }

    // Virtual - override to add any additional options to the disabled state update.
    protected function UpdateSpecialMenuDisabledState(
        flashValueStorage : CScriptedFlashValueStorage,
        dataArray : CScriptedFlashArray
    ) {}
}
