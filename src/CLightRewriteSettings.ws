/*
 * Caches LightRewrite settings from the in-game mod menu.
 */
class CLightRewriteSettings {
    // The current XML config version
    private const var CONFIG_VERSION : int;            default CONFIG_VERSION = 9;

    // Group name constants (must match XML Group id values)
    private const var GENERAL_GROUP : name;            default GENERAL_GROUP = 'LightRewrite_General';

    // Setting name constants (must match XML Var id values)
    private const var ENABLED : name;                  default ENABLED                = 'Enabled';
    private const var INIT_VERSION : name;             default INIT_VERSION           = 'InitVersion';

    // Internal group IDs resolved at init time
    private var generalGroupId  : int;

    private var gameConfig : CInGameConfigWrapper;

    // Light rewrite parameters
    public var isEnabled : bool;                       default isEnabled                = true;

    public var candleParams : CLightRewriteParamsCandle;
    public var torchParams : CLightRewriteSourceParams;
    public var brazierParams : CLightRewriteSourceParams;
    public var candelabraParams : CLightRewriteSourceParams;
    public var campfireParams : CLightRewriteSourceParams;
    public var chandelierParams : CLightRewriteSourceParams;

    private var lightSourceParams : array<CLightRewriteSourceParams>;

    // Lazy constructor. Resolves group IDs from the config wrapper.
    public function Init() {
        var i, count : int;

        gameConfig      = theGame.GetInGameConfigWrapper();
        generalGroupId  = gameConfig.GetGroupIdx(GENERAL_GROUP);

        candleParams = new CLightRewriteParamsCandle in this;
        torchParams = new CLightRewriteParamsTorch in this;
        brazierParams = new CLightRewriteParamsBrazier in this;
        candelabraParams = new CLightRewriteParamsCandelabra in this;
        campfireParams = new CLightRewriteParamsCampfire in this;
        chandelierParams = new CLightRewriteParamsChandelier in this;

        lightSourceParams.PushBack(candleParams);
        lightSourceParams.PushBack(torchParams);
        lightSourceParams.PushBack(brazierParams);
        lightSourceParams.PushBack(candelabraParams);
        lightSourceParams.PushBack(campfireParams);
        lightSourceParams.PushBack(chandelierParams);

        count = lightSourceParams.Size();
        for (i = 0; i < count; i += 1) {
            lightSourceParams[i].Init();
        }
    }

    // Returns true if groupId belongs to one of this mod's settings groups.
    // Used to filter out option-change events fired by other mods.
    public function IsMyModSettingsGroup(groupId : int) : bool {
        return groupId == generalGroupId;
    }

    // If mod config has never been initialised, set the default values and save them.
    // Handles migration from older versions by writing any keys added since the stored version.
    public function EnsureGameConfigIsInitialised() {
        var oldAttenuation : string;
        var oldShadowFadeDistance : string;
        var oldShadowFadeRange : string;
        var oldShadowBlendFactor : string;
        var i, count : int;
        var initVersion : int = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, INIT_VERSION), 0);

        if (initVersion == CONFIG_VERSION) return;

        // Never initialised - write the v1 defaults, then apply the same migrations below.
        if (initVersion == 0) {
            gameConfig.SetVarValue(GENERAL_GROUP, ENABLED, isEnabled);
            gameConfig.SetVarValue(GENERAL_GROUP, candleParams.TAG_BRIGHTNESS, candleParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, candleParams.TAG_RADIUS, candleParams.radius);
            gameConfig.SetVarValue(GENERAL_GROUP, torchParams.TAG_BRIGHTNESS, torchParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, torchParams.TAG_RADIUS, torchParams.radius);
        }

        // v1 → v2: promote the old global attenuation value to both per-source keys.
        if (initVersion <= 1) {
            oldAttenuation = gameConfig.GetVarValue(GENERAL_GROUP, 'Attenuation');

            if (StringToFloat(oldAttenuation, -1.f) != -1.f) {
                gameConfig.SetVarValue(GENERAL_GROUP, candleParams.TAG_ATTENUATION, oldAttenuation);
                gameConfig.SetVarValue(GENERAL_GROUP, torchParams.TAG_ATTENUATION, oldAttenuation);
            } else {
                gameConfig.SetVarValue(GENERAL_GROUP, candleParams.TAG_ATTENUATION, candleParams.attenuation);
                gameConfig.SetVarValue(GENERAL_GROUP, torchParams.TAG_ATTENUATION, torchParams.attenuation);
            }
        }

        // v2 → v3: add per-source colour override settings.
        if (initVersion <= 2) {
            gameConfig.SetVarValue(GENERAL_GROUP, candleParams.TAG_OVERRIDE_COLOUR, candleParams.shouldOverrideColour);
            gameConfig.SetVarValue(GENERAL_GROUP, candleParams.TAG_RED, candleParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, candleParams.TAG_GREEN, candleParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, candleParams.TAG_BLUE, candleParams.color.Blue);
            gameConfig.SetVarValue(GENERAL_GROUP, torchParams.TAG_OVERRIDE_COLOUR, torchParams.shouldOverrideColour);
            gameConfig.SetVarValue(GENERAL_GROUP, torchParams.TAG_RED, torchParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, torchParams.TAG_GREEN, torchParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, torchParams.TAG_BLUE, torchParams.color.Blue);
        }

        // v3 → v4: add brazier light source settings.
        if (initVersion <= 3) {
            gameConfig.SetVarValue(GENERAL_GROUP, brazierParams.TAG_BRIGHTNESS, brazierParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, brazierParams.TAG_RADIUS, brazierParams.radius);
            gameConfig.SetVarValue(GENERAL_GROUP, brazierParams.TAG_ATTENUATION, brazierParams.attenuation);
            gameConfig.SetVarValue(GENERAL_GROUP, brazierParams.TAG_OVERRIDE_COLOUR, brazierParams.shouldOverrideColour);
            gameConfig.SetVarValue(GENERAL_GROUP, brazierParams.TAG_RED, brazierParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, brazierParams.TAG_GREEN, brazierParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, brazierParams.TAG_BLUE, brazierParams.color.Blue);
        }

        // v4 → v5: add candelabra and campfire light source settings.
        if (initVersion <= 4) {
            gameConfig.SetVarValue(GENERAL_GROUP, candelabraParams.TAG_BRIGHTNESS, candelabraParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, candelabraParams.TAG_RADIUS, candelabraParams.radius);
            gameConfig.SetVarValue(GENERAL_GROUP, candelabraParams.TAG_ATTENUATION, candelabraParams.attenuation);
            gameConfig.SetVarValue(GENERAL_GROUP, candelabraParams.TAG_OVERRIDE_COLOUR, candelabraParams.shouldOverrideColour);
            gameConfig.SetVarValue(GENERAL_GROUP, candelabraParams.TAG_RED, candelabraParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, candelabraParams.TAG_GREEN, candelabraParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, candelabraParams.TAG_BLUE, candelabraParams.color.Blue);
            gameConfig.SetVarValue(GENERAL_GROUP, campfireParams.TAG_BRIGHTNESS, campfireParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, campfireParams.TAG_RADIUS, campfireParams.radius);
            gameConfig.SetVarValue(GENERAL_GROUP, campfireParams.TAG_ATTENUATION, campfireParams.attenuation);
            gameConfig.SetVarValue(GENERAL_GROUP, campfireParams.TAG_OVERRIDE_COLOUR, campfireParams.shouldOverrideColour);
            gameConfig.SetVarValue(GENERAL_GROUP, campfireParams.TAG_RED, campfireParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, campfireParams.TAG_GREEN, campfireParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, campfireParams.TAG_BLUE, campfireParams.color.Blue);
        }

        // v5 → v6: promote global shadow settings to per-source keys.
        if (initVersion <= 5) {
            oldShadowFadeDistance = gameConfig.GetVarValue(GENERAL_GROUP, 'ShadowFadeDistance');
            oldShadowFadeRange = gameConfig.GetVarValue(GENERAL_GROUP, 'ShadowFadeRange');
            oldShadowBlendFactor = gameConfig.GetVarValue(GENERAL_GROUP, 'ShadowBlendFactor');

            if (StringToFloat(oldShadowFadeDistance, -1.f) != -1.f) {
                gameConfig.SetVarValue(GENERAL_GROUP, candleParams.TAG_SHADOW_DISTANCE, oldShadowFadeDistance);
                gameConfig.SetVarValue(GENERAL_GROUP, torchParams.TAG_SHADOW_DISTANCE, oldShadowFadeDistance);
                gameConfig.SetVarValue(GENERAL_GROUP, candelabraParams.TAG_SHADOW_DISTANCE, oldShadowFadeDistance);
                gameConfig.SetVarValue(GENERAL_GROUP, campfireParams.TAG_SHADOW_DISTANCE, oldShadowFadeDistance);
            } else {
                gameConfig.SetVarValue(GENERAL_GROUP, candleParams.TAG_SHADOW_DISTANCE, candleParams.shadowFadeDistance);
                gameConfig.SetVarValue(GENERAL_GROUP, torchParams.TAG_SHADOW_DISTANCE, torchParams.shadowFadeDistance);
                gameConfig.SetVarValue(GENERAL_GROUP, candelabraParams.TAG_SHADOW_DISTANCE, candelabraParams.shadowFadeDistance);
                gameConfig.SetVarValue(GENERAL_GROUP, campfireParams.TAG_SHADOW_DISTANCE, campfireParams.shadowFadeDistance);
            }
            gameConfig.SetVarValue(GENERAL_GROUP, brazierParams.TAG_SHADOW_DISTANCE, brazierParams.shadowFadeDistance);

            if (StringToFloat(oldShadowFadeRange, -1.f) != -1.f) {
                gameConfig.SetVarValue(GENERAL_GROUP, candleParams.TAG_SHADOW_RANGE, oldShadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, torchParams.TAG_SHADOW_RANGE, oldShadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, brazierParams.TAG_SHADOW_RANGE, oldShadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, candelabraParams.TAG_SHADOW_RANGE, oldShadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, campfireParams.TAG_SHADOW_RANGE, oldShadowFadeRange);
            } else {
                gameConfig.SetVarValue(GENERAL_GROUP, candleParams.TAG_SHADOW_RANGE, candleParams.shadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, torchParams.TAG_SHADOW_RANGE, torchParams.shadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, brazierParams.TAG_SHADOW_RANGE, brazierParams.shadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, candelabraParams.TAG_SHADOW_RANGE, candelabraParams.shadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, campfireParams.TAG_SHADOW_RANGE, campfireParams.shadowFadeRange);
            }

            if (StringToFloat(oldShadowBlendFactor, -1.f) != -1.f) {
                gameConfig.SetVarValue(GENERAL_GROUP, candleParams.TAG_SHADOW_BLEND, oldShadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, torchParams.TAG_SHADOW_BLEND, oldShadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, brazierParams.TAG_SHADOW_BLEND, oldShadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, candelabraParams.TAG_SHADOW_BLEND, oldShadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, campfireParams.TAG_SHADOW_BLEND, oldShadowBlendFactor);
            } else {
                gameConfig.SetVarValue(GENERAL_GROUP, candleParams.TAG_SHADOW_BLEND, candleParams.shadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, torchParams.TAG_SHADOW_BLEND, torchParams.shadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, brazierParams.TAG_SHADOW_BLEND, brazierParams.shadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, candelabraParams.TAG_SHADOW_BLEND, candelabraParams.shadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, campfireParams.TAG_SHADOW_BLEND, campfireParams.shadowBlendFactor);
            }
        }

        // v6 → v7: add chandelier light source settings.
        if (initVersion <= 6) {
            gameConfig.SetVarValue(GENERAL_GROUP, chandelierParams.TAG_BRIGHTNESS, chandelierParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, chandelierParams.TAG_RADIUS, chandelierParams.radius);
            gameConfig.SetVarValue(GENERAL_GROUP, chandelierParams.TAG_ATTENUATION, chandelierParams.attenuation);
            gameConfig.SetVarValue(GENERAL_GROUP, chandelierParams.TAG_SHADOW_DISTANCE, chandelierParams.shadowFadeDistance);
            gameConfig.SetVarValue(GENERAL_GROUP, chandelierParams.TAG_SHADOW_RANGE, chandelierParams.shadowFadeRange);
            gameConfig.SetVarValue(GENERAL_GROUP, chandelierParams.TAG_SHADOW_BLEND, chandelierParams.shadowBlendFactor);
            gameConfig.SetVarValue(GENERAL_GROUP, chandelierParams.TAG_OVERRIDE_COLOUR, chandelierParams.shouldOverrideColour);
            gameConfig.SetVarValue(GENERAL_GROUP, chandelierParams.TAG_RED, chandelierParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, chandelierParams.TAG_GREEN, chandelierParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, chandelierParams.TAG_BLUE, chandelierParams.color.Blue);
        }

        // v7 → v8: add per-source enable settings.
        if (initVersion <= 7) {
            count = lightSourceParams.Size();
            for (i = 0; i < count; i += 1) {
                gameConfig.SetVarValue(GENERAL_GROUP, lightSourceParams[i].TAG_ENABLED, lightSourceParams[i].enabled);
            }
        }

        // v8 → v9: add candle point-light alignment setting.
        if (initVersion <= 8) {
            gameConfig.SetVarValue(GENERAL_GROUP, candleParams.TAG_ALIGN_POINT_LIGHTS, candleParams.alignPointLights);
        }

        gameConfig.SetVarValue(GENERAL_GROUP, INIT_VERSION, CONFIG_VERSION);
        theGame.SaveUserSettings();
    }

    // Delegates to W3GameParams.ReadLightRewriteConfig(), which can write to
    // its own fields directly.
    public function ReadGameConfig() {
        var i, count : int;

        EnsureGameConfigIsInitialised();

        isEnabled = gameConfig.GetVarValue(GENERAL_GROUP, ENABLED);

        count = lightSourceParams.Size();
        for (i = 0; i < count; i += 1) {
            lightSourceParams[i].ReadGameConfig(gameConfig, GENERAL_GROUP);
        }
    }

    // To be called for every option-change event.
    // Filters to this mod's groups before updating cached settings.
    public function OptionValueChanged(groupId : int, optionName : name, optionValue : string) {
        var wasEnabled : bool = isEnabled;
        var i, count : int;

        if (IsMyModSettingsGroup(groupId)) {
            ReadGameConfig();

            count = lightSourceParams.Size();
            for (i = 0; i < count; i += 1) {
                lightSourceParams[i].OptionValueChanged(optionName);
            }

            // We've just turned the mod off
            if (isEnabled != wasEnabled && !isEnabled) {
                theGame.lightRewriter.DisableLightRewrite();
            }

            // Some change was made, and the mod is enabled
            else if (isEnabled) {
                theGame.lightRewriter.RewriteAllLightSources();
            }
        }
    }

    // Configures the active game settings menu. Should be called after the menu is opened.
    public function ConfigureModMenu() {
        UpdateAllGroupsDisabledState();
    }

    private function UpdateAllGroupsDisabledState() {
        var i, count : int;

        count = lightSourceParams.Size();
        for (i = 0; i < count; i += 1) {
            lightSourceParams[i].UpdateMenuDisabledState();
        }
    }

    // Gets an array of every tag that the mod might add to a valid CGameplayEntity light source
    public function GetAllLightSourceTags() : array<name> {
        var tags : array<name>;
        var i, count : int;

        count = lightSourceParams.Size();
        for (i = 0; i < count; i += 1) {
            tags.PushBack(lightSourceParams[i].tag);
        }

        return tags;
    }

    public function GetParamsForType(lightType : ELightRewriteType) : CLightRewriteSourceParams {
        switch (lightType) {
            case LRT_Candle:      return candleParams;
            case LRT_Torch:       return torchParams;
            case LRT_Brazier:     return brazierParams;
            case LRT_Candelabra:  return candelabraParams;
            case LRT_Campfire:    return campfireParams;
            case LRT_Chandelier:  return chandelierParams;
            default:              return NULL;
        }
    }
}
