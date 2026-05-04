/*
 * Caches LightRewrite settings from the in-game mod menu.
 */
class CLightRewriteSettings {
    // The current XML config version
    private const var CONFIG_VERSION : int;            default CONFIG_VERSION = 10;

    // Group name constants (must match XML Group id values)
    private const var GENERAL_GROUP : name;            default GENERAL_GROUP = 'LightRewrite_General';

    // Label key constants (must match XML Var id values)
    private const var CURRENT_PRESET_LABEL : string;    default CURRENT_PRESET_LABEL    = 'LightRewrite_CurrentProfile';
    private const var NONE_PRESET_LABEL : string;        default NONE_PRESET_LABEL        = 'LightRewrite_None';

    // Setting name constants (must match XML Var id values)
    private const var ENABLED : name;                  default ENABLED                = 'Enabled';
    private const var INIT_VERSION : name;             default INIT_VERSION           = 'InitVersion';
    private const var CURRENT_PRESET : name;            default CURRENT_PRESET          = 'CurrentProfile';

    // Internal group IDs resolved at init time
    private var generalGroupId  : int;

    private var gameConfig : CInGameConfigWrapper;

    // Light rewrite parameters
    public var isEnabled : bool;                       default isEnabled                = true;

    // Runtime params for each light source type
    public var candleParams : CLightRewriteSourceParams;
    public var torchParams : CLightRewriteSourceParams;
    public var brazierParams : CLightRewriteSourceParams;
    public var candelabraParams : CLightRewriteSourceParams;
    public var campfireParams : CLightRewriteSourceParams;
    public var chandelierParams : CLightRewriteSourceParams;

    // Flash config menu settings for each light source type
    private var candleMenu : CLightRewriteSourceMenu;
    private var torchMenu : CLightRewriteSourceMenu;
    private var brazierMenu : CLightRewriteSourceMenu;
    private var candelabraMenu : CLightRewriteSourceMenu;
    private var campfireMenu : CLightRewriteSourceMenu;
    private var chandelierMenu : CLightRewriteSourceMenu;

    private var lightSourceParams : array<CLightRewriteSourceParams>;
    private var lightSourceMenu : array<CLightRewriteSourceMenu>;

    private var loadedOverrides : array<CLightRewriteSourceParams>;

    // Lazy constructor. Resolves group IDs from the config wrapper.
    public function Init() {
        var loadedParams : array<CLightRewriteSourceParams>;
        var i, count : int;

        gameConfig = theGame.GetInGameConfigWrapper();
        generalGroupId = gameConfig.GetGroupIdx(GENERAL_GROUP);

        loadedParams = LoadLightRewriteParams(this);
        loadedOverrides = LoadLightRewriteOverrides(this);

        count = loadedParams.Size();
        for (i = 0; i < count; i += 1) {
            switch (loadedParams[i].tag) {
                case 'LR_Candle':     candleParams = loadedParams[i];     break;
                case 'LR_Torch':      torchParams = loadedParams[i];      break;
                case 'LR_Brazier':    brazierParams = loadedParams[i];    break;
                case 'LR_Candelabra': candelabraParams = loadedParams[i]; break;
                case 'LR_Campfire':   campfireParams = loadedParams[i];   break;
                case 'LR_Chandelier': chandelierParams = loadedParams[i]; break;
            }
        }

        candleMenu = new CLightRewriteMenuCandle in this;
        torchMenu = new CLightRewriteMenuTorch in this;
        brazierMenu = new CLightRewriteMenuBrazier in this;
        candelabraMenu = new CLightRewriteMenuCandelabra in this;
        campfireMenu = new CLightRewriteMenuCampfire in this;
        chandelierMenu = new CLightRewriteMenuChandelier in this;

        lightSourceParams.PushBack(candleParams);
        lightSourceParams.PushBack(torchParams);
        lightSourceParams.PushBack(brazierParams);
        lightSourceParams.PushBack(candelabraParams);
        lightSourceParams.PushBack(campfireParams);
        lightSourceParams.PushBack(chandelierParams);

        lightSourceMenu.PushBack(candleMenu);
        lightSourceMenu.PushBack(torchMenu);
        lightSourceMenu.PushBack(brazierMenu);
        lightSourceMenu.PushBack(candelabraMenu);
        lightSourceMenu.PushBack(campfireMenu);
        lightSourceMenu.PushBack(chandelierMenu);
    }

    public function GetEnabledOptionId() : name { return ENABLED; }

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

        LogLightRewrite("Migrating config from version " + initVersion + " to " + CONFIG_VERSION);

        // Never initialised - write the v1 defaults, then apply the same migrations below.
        if (initVersion == 0) {
            gameConfig.SetVarValue(GENERAL_GROUP, ENABLED, isEnabled);
            gameConfig.SetVarValue(GENERAL_GROUP, candleMenu.TAG_BRIGHTNESS, candleParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, candleMenu.TAG_RADIUS, candleParams.radius);
            gameConfig.SetVarValue(GENERAL_GROUP, torchMenu.TAG_BRIGHTNESS, torchParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, torchMenu.TAG_RADIUS, torchParams.radius);
        }

        // v1 → v2: promote the old global attenuation value to both per-source keys.
        if (initVersion <= 1) {
            oldAttenuation = gameConfig.GetVarValue(GENERAL_GROUP, 'Attenuation');

            if (StringToFloat(oldAttenuation, -1.f) != -1.f) {
                gameConfig.SetVarValue(GENERAL_GROUP, candleMenu.TAG_ATTENUATION, oldAttenuation);
                gameConfig.SetVarValue(GENERAL_GROUP, torchMenu.TAG_ATTENUATION, oldAttenuation);
            } else {
                gameConfig.SetVarValue(GENERAL_GROUP, candleMenu.TAG_ATTENUATION, candleParams.attenuation);
                gameConfig.SetVarValue(GENERAL_GROUP, torchMenu.TAG_ATTENUATION, torchParams.attenuation);
            }
        }

        // v2 → v3: add per-source colour override settings.
        if (initVersion <= 2) {
            gameConfig.SetVarValue(GENERAL_GROUP, candleMenu.TAG_OVERRIDE_COLOUR, candleParams.hasColour);
            gameConfig.SetVarValue(GENERAL_GROUP, candleMenu.TAG_RED, candleParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, candleMenu.TAG_GREEN, candleParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, candleMenu.TAG_BLUE, candleParams.color.Blue);
            gameConfig.SetVarValue(GENERAL_GROUP, torchMenu.TAG_OVERRIDE_COLOUR, torchParams.hasColour);
            gameConfig.SetVarValue(GENERAL_GROUP, torchMenu.TAG_RED, torchParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, torchMenu.TAG_GREEN, torchParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, torchMenu.TAG_BLUE, torchParams.color.Blue);
        }

        // v3 → v4: add brazier light source settings.
        if (initVersion <= 3) {
            gameConfig.SetVarValue(GENERAL_GROUP, brazierMenu.TAG_BRIGHTNESS, brazierParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, brazierMenu.TAG_RADIUS, brazierParams.radius);
            gameConfig.SetVarValue(GENERAL_GROUP, brazierMenu.TAG_ATTENUATION, brazierParams.attenuation);
            gameConfig.SetVarValue(GENERAL_GROUP, brazierMenu.TAG_OVERRIDE_COLOUR, brazierParams.hasColour);
            gameConfig.SetVarValue(GENERAL_GROUP, brazierMenu.TAG_RED, brazierParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, brazierMenu.TAG_GREEN, brazierParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, brazierMenu.TAG_BLUE, brazierParams.color.Blue);
        }

        // v4 → v5: add candelabra and campfire light source settings.
        if (initVersion <= 4) {
            gameConfig.SetVarValue(GENERAL_GROUP, candelabraMenu.TAG_BRIGHTNESS, candelabraParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, candelabraMenu.TAG_RADIUS, candelabraParams.radius);
            gameConfig.SetVarValue(GENERAL_GROUP, candelabraMenu.TAG_ATTENUATION, candelabraParams.attenuation);
            gameConfig.SetVarValue(GENERAL_GROUP, candelabraMenu.TAG_OVERRIDE_COLOUR, candelabraParams.hasColour);
            gameConfig.SetVarValue(GENERAL_GROUP, candelabraMenu.TAG_RED, candelabraParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, candelabraMenu.TAG_GREEN, candelabraParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, candelabraMenu.TAG_BLUE, candelabraParams.color.Blue);
            gameConfig.SetVarValue(GENERAL_GROUP, campfireMenu.TAG_BRIGHTNESS, campfireParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, campfireMenu.TAG_RADIUS, campfireParams.radius);
            gameConfig.SetVarValue(GENERAL_GROUP, campfireMenu.TAG_ATTENUATION, campfireParams.attenuation);
            gameConfig.SetVarValue(GENERAL_GROUP, campfireMenu.TAG_OVERRIDE_COLOUR, campfireParams.hasColour);
            gameConfig.SetVarValue(GENERAL_GROUP, campfireMenu.TAG_RED, campfireParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, campfireMenu.TAG_GREEN, campfireParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, campfireMenu.TAG_BLUE, campfireParams.color.Blue);
        }

        // v5 → v6: promote global shadow settings to per-source keys.
        if (initVersion <= 5) {
            oldShadowFadeDistance = gameConfig.GetVarValue(GENERAL_GROUP, 'ShadowFadeDistance');
            oldShadowFadeRange = gameConfig.GetVarValue(GENERAL_GROUP, 'ShadowFadeRange');
            oldShadowBlendFactor = gameConfig.GetVarValue(GENERAL_GROUP, 'ShadowBlendFactor');

            if (StringToFloat(oldShadowFadeDistance, -1.f) != -1.f) {
                gameConfig.SetVarValue(GENERAL_GROUP, candleMenu.TAG_SHADOW_DISTANCE, oldShadowFadeDistance);
                gameConfig.SetVarValue(GENERAL_GROUP, torchMenu.TAG_SHADOW_DISTANCE, oldShadowFadeDistance);
                gameConfig.SetVarValue(GENERAL_GROUP, candelabraMenu.TAG_SHADOW_DISTANCE, oldShadowFadeDistance);
                gameConfig.SetVarValue(GENERAL_GROUP, campfireMenu.TAG_SHADOW_DISTANCE, oldShadowFadeDistance);
            } else {
                gameConfig.SetVarValue(GENERAL_GROUP, candleMenu.TAG_SHADOW_DISTANCE, candleParams.shadowFadeDistance);
                gameConfig.SetVarValue(GENERAL_GROUP, torchMenu.TAG_SHADOW_DISTANCE, torchParams.shadowFadeDistance);
                gameConfig.SetVarValue(GENERAL_GROUP, candelabraMenu.TAG_SHADOW_DISTANCE, candelabraParams.shadowFadeDistance);
                gameConfig.SetVarValue(GENERAL_GROUP, campfireMenu.TAG_SHADOW_DISTANCE, campfireParams.shadowFadeDistance);
            }
            gameConfig.SetVarValue(GENERAL_GROUP, brazierMenu.TAG_SHADOW_DISTANCE, brazierParams.shadowFadeDistance);

            if (StringToFloat(oldShadowFadeRange, -1.f) != -1.f) {
                gameConfig.SetVarValue(GENERAL_GROUP, candleMenu.TAG_SHADOW_RANGE, oldShadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, torchMenu.TAG_SHADOW_RANGE, oldShadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, brazierMenu.TAG_SHADOW_RANGE, oldShadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, candelabraMenu.TAG_SHADOW_RANGE, oldShadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, campfireMenu.TAG_SHADOW_RANGE, oldShadowFadeRange);
            } else {
                gameConfig.SetVarValue(GENERAL_GROUP, candleMenu.TAG_SHADOW_RANGE, candleParams.shadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, torchMenu.TAG_SHADOW_RANGE, torchParams.shadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, brazierMenu.TAG_SHADOW_RANGE, brazierParams.shadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, candelabraMenu.TAG_SHADOW_RANGE, candelabraParams.shadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, campfireMenu.TAG_SHADOW_RANGE, campfireParams.shadowFadeRange);
            }

            if (StringToFloat(oldShadowBlendFactor, -1.f) != -1.f) {
                gameConfig.SetVarValue(GENERAL_GROUP, candleMenu.TAG_SHADOW_BLEND, oldShadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, torchMenu.TAG_SHADOW_BLEND, oldShadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, brazierMenu.TAG_SHADOW_BLEND, oldShadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, candelabraMenu.TAG_SHADOW_BLEND, oldShadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, campfireMenu.TAG_SHADOW_BLEND, oldShadowBlendFactor);
            } else {
                gameConfig.SetVarValue(GENERAL_GROUP, candleMenu.TAG_SHADOW_BLEND, candleParams.shadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, torchMenu.TAG_SHADOW_BLEND, torchParams.shadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, brazierMenu.TAG_SHADOW_BLEND, brazierParams.shadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, candelabraMenu.TAG_SHADOW_BLEND, candelabraParams.shadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, campfireMenu.TAG_SHADOW_BLEND, campfireParams.shadowBlendFactor);
            }
        }

        // v6 → v7: add chandelier light source settings.
        if (initVersion <= 6) {
            gameConfig.SetVarValue(GENERAL_GROUP, chandelierMenu.TAG_BRIGHTNESS, chandelierParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, chandelierMenu.TAG_RADIUS, chandelierParams.radius);
            gameConfig.SetVarValue(GENERAL_GROUP, chandelierMenu.TAG_ATTENUATION, chandelierParams.attenuation);
            gameConfig.SetVarValue(GENERAL_GROUP, chandelierMenu.TAG_SHADOW_DISTANCE, chandelierParams.shadowFadeDistance);
            gameConfig.SetVarValue(GENERAL_GROUP, chandelierMenu.TAG_SHADOW_RANGE, chandelierParams.shadowFadeRange);
            gameConfig.SetVarValue(GENERAL_GROUP, chandelierMenu.TAG_SHADOW_BLEND, chandelierParams.shadowBlendFactor);
            gameConfig.SetVarValue(GENERAL_GROUP, chandelierMenu.TAG_OVERRIDE_COLOUR, chandelierParams.hasColour);
            gameConfig.SetVarValue(GENERAL_GROUP, chandelierMenu.TAG_RED, chandelierParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, chandelierMenu.TAG_GREEN, chandelierParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, chandelierMenu.TAG_BLUE, chandelierParams.color.Blue);
        }

        // v7 → v8: add per-source enable settings.
        if (initVersion <= 7) {
            count = lightSourceMenu.Size();
            for (i = 0; i < count; i += 1) {
                gameConfig.SetVarValue(GENERAL_GROUP, lightSourceMenu[i].TAG_ENABLED, lightSourceParams[i].enabled);
            }
        }

        // v8 → v9: add candle point-light alignment setting.
        if (initVersion <= 8) {
            gameConfig.SetVarValue(GENERAL_GROUP, candleMenu.TAG_ALIGN_POINT_LIGHTS, candleParams.alignPointLights);
        }

        // v9 → v10: Disable menu overrides by default.
        if (initVersion <= 9) {
            gameConfig.SetVarValue(GENERAL_GROUP, candleMenu.TAG_ENABLED, false);
            gameConfig.SetVarValue(GENERAL_GROUP, torchMenu.TAG_ENABLED, false);
            gameConfig.SetVarValue(GENERAL_GROUP, brazierMenu.TAG_ENABLED, false);
            gameConfig.SetVarValue(GENERAL_GROUP, candelabraMenu.TAG_ENABLED, false);
            gameConfig.SetVarValue(GENERAL_GROUP, campfireMenu.TAG_ENABLED, false);
            gameConfig.SetVarValue(GENERAL_GROUP, chandelierMenu.TAG_ENABLED, false);
        }

        gameConfig.SetVarValue(GENERAL_GROUP, INIT_VERSION, CONFIG_VERSION);
        theGame.SaveUserSettings();
    }

    // Delegates to W3GameParams.ReadLightRewriteConfig(), which can write to
    // its own fields directly.
    public function ReadGameConfig() {
        var i, count : int;

        isEnabled = gameConfig.GetVarValue(GENERAL_GROUP, ENABLED);

        count = lightSourceMenu.Size();
        for (i = 0; i < count; i += 1) {
            lightSourceMenu[i].ReadGameConfig(gameConfig, GENERAL_GROUP, lightSourceParams[i]);
        }
    }

    // To be called for every option-change event.
    // Filters to this mod's groups before updating cached settings.
    public function OptionValueChanged(groupId : int, optionName : name, optionValue : string) {
        var wasEnabled : bool = isEnabled;
        var i, count : int;

        if (IsMyModSettingsGroup(groupId)) {
            ReadGameConfig();

            count = lightSourceMenu.Size();
            for (i = 0; i < count; i += 1) {
                lightSourceMenu[i].OptionValueChanged(optionName, lightSourceParams[i]);
            }

            // ForceProcessFlashStorage() inside UpdateMenuDisabledState resets dynamic
            // option lists back to XML defaults, so we must restore them afterwards.
            ReplacePresetMenuOptions();

            // We've just turned the mod off
            if (isEnabled != wasEnabled && !isEnabled) {
                theGame.lightRewrite.DisableLightRewrite();
            }

            // Some change was made, and the mod is enabled
            else if (isEnabled) {
                theGame.lightRewrite.RewriteAllLightSources();
            }
        }
    }

    // Configures the active game settings menu. Should be called after the menu is opened.
    public function ConfigureModMenu() {
        UpdateAllGroupsDisabledState();
        ReplacePresetMenuOptions();
    }

    private function ReplacePresetMenuOptions() {
        var optionKeys : array<name>;

        optionKeys.PushBack('LightRewrite_None');
        FindLightRewriteProfileNames(optionKeys);

        LR_ReplaceFlashMenuOptions(CURRENT_PRESET, CURRENT_PRESET_LABEL, GENERAL_GROUP, optionKeys);
    }

    private function UpdateAllGroupsDisabledState() {
        var i, count : int;

        count = lightSourceMenu.Size();
        for (i = 0; i < count; i += 1) {
            lightSourceMenu[i].UpdateMenuDisabledState(lightSourceParams[i]);
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

    // Finds the params for a given entity.
    public function FindParamsForEntity(entity : CGameplayEntity) : CLightRewriteSourceParams {
        var params : CLightRewriteSourceParams = NULL;
        var matched : CLightRewriteSourceParams = NULL;
        var i, count : int;

        var editorPath : string = entity.ToString();
        var fileName : string = StrAfterLast(editorPath, StrChar(92));

        if (StrFindFirst(fileName, "candelabra") != -1) {
            params = candelabraParams;
        }
        else if (StrFindFirst(fileName, "chandelier") != -1) {
            params = chandelierParams;
        }
        else if (StrFindFirst(fileName, "candle") != -1) {
            params = candleParams;
        }
        else if (StrFindFirst(fileName, "torch") != -1) {
            params = torchParams;
        }
        else if (StrFindFirst(fileName, "brazier") != -1) {
            params = brazierParams;
        }
        else if (StrFindFirst(fileName, "campfire") != -1) {
            params = campfireParams;
        }

        if (params) {
            if (!params.menuOverrideActive) {
                count = loadedOverrides.Size();
                for (i = 0; i < count; i += 1) {
                    if (loadedOverrides[i].MatchesEntity(entity)) {
                        matched = loadedOverrides[i];
                    }
                }
            }

            if (matched) {
                params = (CLightRewriteSourceParams)params.Clone(entity);
                matched.ApplyTo(params);
                LogLightRewrite("[XmlConfig] Applied override '" + matched.displayName + "' to " + editorPath);
            }
        }

        return params;
    }
}
