/*
 * Caches LightRewrite settings from the in-game mod menu.
 */
class CLightRewriteSettings {
    // The current XML config version
    private const var CONFIG_VERSION      : int;     default CONFIG_VERSION = 12;
    // Group name constants (must match XML Group id values)
    private const var GENERAL_GROUP       : name;    default GENERAL_GROUP = 'LightRewrite_General';
    // Label key constants (must match XML Var id values)
    private const var CURRENT_PRESET_LABEL: string;  default CURRENT_PRESET_LABEL = 'LightRewrite_CurrentProfile';
    private const var NONE_PRESET_LABEL   : name;    default NONE_PRESET_LABEL = 'LightRewrite_None';
    // Setting name constants (must match XML Var id values)
    private const var ENABLED             : name;    default ENABLED = 'Enabled';
    private const var INIT_VERSION        : name;    default INIT_VERSION = 'InitVersion';
    private const var CURRENT_PRESET      : name;    default CURRENT_PRESET = 'CurrentProfile';
    private const var SPACING_MODE        : name;    default SPACING_MODE = 'SpacingMode';
    private const var SPACING_COUNT       : name;    default SPACING_COUNT = 'SpacingCount';
    private const var SPACING_BUDGET      : name;    default SPACING_BUDGET = 'SpacingBudget';

    // Internal group IDs resolved at init time
    private var generalGroupId: int;
    private var gameConfig    : CInGameConfigWrapper;

    // Light rewrite parameters
    public var isEnabled: bool;  default isEnabled = true;
    private var currentProfile: name;

    // Each spacing mode draws its amount from its own slider; see GetActiveSpacingAmountVar
    private var spacingMode  : int;    default spacingMode = 0;
    private var spacingCount : float;  default spacingCount = 2.0;
    private var spacingBudget: float;  default spacingBudget = 4.0;

    // Runtime params for each light source type
    public var candleParams    : CLightRewriteSourceParams;
    public var torchParams     : CLightRewriteSourceParams;
    public var brazierParams   : CLightRewriteSourceParams;
    public var candelabraParams: CLightRewriteSourceParams;
    public var campfireParams  : CLightRewriteSourceParams;
    public var chandelierParams: CLightRewriteSourceParams;

    // Flash config menu settings for each light source type
    private var candleMenu    : CLightRewriteSourceMenu;
    private var torchMenu     : CLightRewriteSourceMenu;
    private var brazierMenu   : CLightRewriteSourceMenu;
    private var candelabraMenu: CLightRewriteSourceMenu;
    private var campfireMenu  : CLightRewriteSourceMenu;
    private var chandelierMenu: CLightRewriteSourceMenu;

    private var lightSourceParams: array<CLightRewriteSourceParams>;
    private var lightSourceMenu  : array<CLightRewriteSourceMenu>;

    // All override groups loaded from XML files, sorted by weight
    private var overrideGroups: array<CLightRewriteOverrideGroup>;

    // Profile names in dropdown order, built once at init from XML
    private var profileOptions: array<name>;
    private var profileIndex  : int;

    // Index of the profile that was selected when the menu was opened
    private var previousProfile: int;

    // Spacing mode and amount that were selected when the menu was opened
    private var previousSpacingMode  : int;
    private var previousSpacingAmount: float;

    // Lazy constructor. Resolves group IDs from the config wrapper.
    public function Init() {
        var loadedParams: array<CLightRewriteSourceParams>;
        var i, count: int;

        gameConfig = theGame.GetInGameConfigWrapper();
        generalGroupId = gameConfig.GetGroupIdx(GENERAL_GROUP);

        loadedParams = LoadLightRewriteParams(this);
        overrideGroups = LoadLightRewriteOverrides(this);

        profileOptions.PushBack(NONE_PRESET_LABEL);
        FindLightRewriteProfileNames(profileOptions);

        count = loadedParams.Size();
        for (i = 0; i < count; i += 1) {
            switch (loadedParams[i].tag) {
                case 'LR_Candle':      candleParams = loadedParams[i];      break;
                case 'LR_Torch':       torchParams = loadedParams[i];       break;
                case 'LR_Brazier':     brazierParams = loadedParams[i];     break;
                case 'LR_Candelabra':  candelabraParams = loadedParams[i];  break;
                case 'LR_Campfire':    campfireParams = loadedParams[i];    break;
                case 'LR_Chandelier':  chandelierParams = loadedParams[i];  break;
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

    public function GetEnabledOptionId(): name {
        return ENABLED;
    }

    public function GetSpacingMode(): LR_ELightSpaceMode {
        switch (spacingMode) {
            case 1:   return LR_LSM_DistanceClamp;
            case 2:   return LR_LSM_RelaxCount;
            case 3:   return LR_LSM_RelaxVolume;
            default:  return LR_LSM_Off;
        }
    }

    public function GetSpacingAmount(): float {
        if (GetActiveSpacingAmountVar() == SPACING_BUDGET) return spacingBudget;
        return spacingCount;
    }

    // The amount slider that backs the current spacing mode; '' when the mode takes no amount
    private function GetActiveSpacingAmountVar(): name {
        switch (GetSpacingMode()) {
            // Both count the overlaps a light may keep, so they share the one slider
            case LR_LSM_DistanceClamp:
            case LR_LSM_RelaxCount:   return SPACING_COUNT;
            case LR_LSM_RelaxVolume:  return SPACING_BUDGET;
            default:                  return '';
        }
    }

    // Returns true if groupId belongs to one of this mod's settings groups.
    // Used to filter out option-change events fired by other mods.
    public function IsMyModSettingsGroup(groupId: int): bool {
        return groupId == generalGroupId;
    }

    // If mod config has never been initialised, set the default values and save them.
    // Handles migration from older versions by writing any keys added since the stored version.
    public function EnsureGameConfigIsInitialised() {
        var oldAttenuation: string;
        var oldShadowFadeDistance: string;
        var oldShadowFadeRange: string;
        var oldShadowBlendFactor: string;
        var i, count: int;
        var initVersion: int = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, INIT_VERSION), 0);

        if (initVersion == CONFIG_VERSION) return;

        LogLightRewrite("Migrating config from version " + initVersion + " to " + CONFIG_VERSION);

        // Never initialised - write the v1 defaults, then apply the same migrations below.
        if (initVersion == 0) {
            gameConfig.SetVarValue(GENERAL_GROUP, ENABLED, isEnabled);
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                candleMenu.TAG_BRIGHTNESS,
                candleParams.brightness.value
            );
            gameConfig.SetVarValue(GENERAL_GROUP, candleMenu.TAG_RADIUS, candleParams.radius.value);
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                torchMenu.TAG_BRIGHTNESS,
                torchParams.brightness.value
            );
            gameConfig.SetVarValue(GENERAL_GROUP, torchMenu.TAG_RADIUS, torchParams.radius.value);
        }

        // v1 → v2: promote the old global attenuation value to both per-source keys.
        if (initVersion <= 1) {
            oldAttenuation = gameConfig.GetVarValue(GENERAL_GROUP, 'Attenuation');

            if (StringToFloat(oldAttenuation, -1.f) != -1.f) {
                gameConfig.SetVarValue(GENERAL_GROUP, candleMenu.TAG_ATTENUATION, oldAttenuation);
                gameConfig.SetVarValue(GENERAL_GROUP, torchMenu.TAG_ATTENUATION, oldAttenuation);
            }
            else {
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    candleMenu.TAG_ATTENUATION,
                    candleParams.attenuation.value
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    torchMenu.TAG_ATTENUATION,
                    torchParams.attenuation.value
                );
            }
        }

        // v2 → v3: add per-source colour override settings.
        if (initVersion <= 2) {
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                candleMenu.TAG_OVERRIDE_COLOUR,
                candleParams.color.has
            );
            gameConfig.SetVarValue(GENERAL_GROUP, candleMenu.TAG_RED, candleParams.color.value.Red);
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                candleMenu.TAG_GREEN,
                candleParams.color.value.Green
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                candleMenu.TAG_BLUE,
                candleParams.color.value.Blue
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                torchMenu.TAG_OVERRIDE_COLOUR,
                torchParams.color.has
            );
            gameConfig.SetVarValue(GENERAL_GROUP, torchMenu.TAG_RED, torchParams.color.value.Red);
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                torchMenu.TAG_GREEN,
                torchParams.color.value.Green
            );
            gameConfig.SetVarValue(GENERAL_GROUP, torchMenu.TAG_BLUE, torchParams.color.value.Blue);
        }

        // v3 → v4: add brazier light source settings.
        if (initVersion <= 3) {
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                brazierMenu.TAG_BRIGHTNESS,
                brazierParams.brightness.value
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                brazierMenu.TAG_RADIUS,
                brazierParams.radius.value
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                brazierMenu.TAG_ATTENUATION,
                brazierParams.attenuation.value
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                brazierMenu.TAG_OVERRIDE_COLOUR,
                brazierParams.color.has
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                brazierMenu.TAG_RED,
                brazierParams.color.value.Red
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                brazierMenu.TAG_GREEN,
                brazierParams.color.value.Green
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                brazierMenu.TAG_BLUE,
                brazierParams.color.value.Blue
            );
        }

        // v4 → v5: add candelabra and campfire light source settings.
        if (initVersion <= 4) {
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                candelabraMenu.TAG_BRIGHTNESS,
                candelabraParams.brightness.value
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                candelabraMenu.TAG_RADIUS,
                candelabraParams.radius.value
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                candelabraMenu.TAG_ATTENUATION,
                candelabraParams.attenuation.value
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                candelabraMenu.TAG_OVERRIDE_COLOUR,
                candelabraParams.color.has
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                candelabraMenu.TAG_RED,
                candelabraParams.color.value.Red
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                candelabraMenu.TAG_GREEN,
                candelabraParams.color.value.Green
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                candelabraMenu.TAG_BLUE,
                candelabraParams.color.value.Blue
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                campfireMenu.TAG_BRIGHTNESS,
                campfireParams.brightness.value
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                campfireMenu.TAG_RADIUS,
                campfireParams.radius.value
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                campfireMenu.TAG_ATTENUATION,
                campfireParams.attenuation.value
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                campfireMenu.TAG_OVERRIDE_COLOUR,
                campfireParams.color.has
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                campfireMenu.TAG_RED,
                campfireParams.color.value.Red
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                campfireMenu.TAG_GREEN,
                campfireParams.color.value.Green
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                campfireMenu.TAG_BLUE,
                campfireParams.color.value.Blue
            );
        }

        // v5 → v6: promote global shadow settings to per-source keys.
        if (initVersion <= 5) {
            oldShadowFadeDistance = gameConfig.GetVarValue(GENERAL_GROUP, 'ShadowFadeDistance');
            oldShadowFadeRange = gameConfig.GetVarValue(GENERAL_GROUP, 'ShadowFadeRange');
            oldShadowBlendFactor = gameConfig.GetVarValue(GENERAL_GROUP, 'ShadowBlendFactor');

            if (StringToFloat(oldShadowFadeDistance, -1.f) != -1.f) {
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    candleMenu.TAG_SHADOW_DISTANCE,
                    oldShadowFadeDistance
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    torchMenu.TAG_SHADOW_DISTANCE,
                    oldShadowFadeDistance
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    candelabraMenu.TAG_SHADOW_DISTANCE,
                    oldShadowFadeDistance
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    campfireMenu.TAG_SHADOW_DISTANCE,
                    oldShadowFadeDistance
                );
            }
            else {
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    candleMenu.TAG_SHADOW_DISTANCE,
                    candleParams.shadowFadeDistance.value
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    torchMenu.TAG_SHADOW_DISTANCE,
                    torchParams.shadowFadeDistance.value
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    candelabraMenu.TAG_SHADOW_DISTANCE,
                    candelabraParams.shadowFadeDistance.value
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    campfireMenu.TAG_SHADOW_DISTANCE,
                    campfireParams.shadowFadeDistance.value
                );
            }
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                brazierMenu.TAG_SHADOW_DISTANCE,
                brazierParams.shadowFadeDistance.value
            );

            if (StringToFloat(oldShadowFadeRange, -1.f) != -1.f) {
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    candleMenu.TAG_SHADOW_RANGE,
                    oldShadowFadeRange
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    torchMenu.TAG_SHADOW_RANGE,
                    oldShadowFadeRange
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    brazierMenu.TAG_SHADOW_RANGE,
                    oldShadowFadeRange
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    candelabraMenu.TAG_SHADOW_RANGE,
                    oldShadowFadeRange
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    campfireMenu.TAG_SHADOW_RANGE,
                    oldShadowFadeRange
                );
            }
            else {
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    candleMenu.TAG_SHADOW_RANGE,
                    candleParams.shadowFadeRange.value
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    torchMenu.TAG_SHADOW_RANGE,
                    torchParams.shadowFadeRange.value
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    brazierMenu.TAG_SHADOW_RANGE,
                    brazierParams.shadowFadeRange.value
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    candelabraMenu.TAG_SHADOW_RANGE,
                    candelabraParams.shadowFadeRange.value
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    campfireMenu.TAG_SHADOW_RANGE,
                    campfireParams.shadowFadeRange.value
                );
            }

            if (StringToFloat(oldShadowBlendFactor, -1.f) != -1.f) {
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    candleMenu.TAG_SHADOW_BLEND,
                    oldShadowBlendFactor
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    torchMenu.TAG_SHADOW_BLEND,
                    oldShadowBlendFactor
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    brazierMenu.TAG_SHADOW_BLEND,
                    oldShadowBlendFactor
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    candelabraMenu.TAG_SHADOW_BLEND,
                    oldShadowBlendFactor
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    campfireMenu.TAG_SHADOW_BLEND,
                    oldShadowBlendFactor
                );
            }
            else {
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    candleMenu.TAG_SHADOW_BLEND,
                    candleParams.shadowBlendFactor.value
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    torchMenu.TAG_SHADOW_BLEND,
                    torchParams.shadowBlendFactor.value
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    brazierMenu.TAG_SHADOW_BLEND,
                    brazierParams.shadowBlendFactor.value
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    candelabraMenu.TAG_SHADOW_BLEND,
                    candelabraParams.shadowBlendFactor.value
                );
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    campfireMenu.TAG_SHADOW_BLEND,
                    campfireParams.shadowBlendFactor.value
                );
            }
        }

        // v6 → v7: add chandelier light source settings.
        if (initVersion <= 6) {
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                chandelierMenu.TAG_BRIGHTNESS,
                chandelierParams.brightness.value
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                chandelierMenu.TAG_RADIUS,
                chandelierParams.radius.value
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                chandelierMenu.TAG_ATTENUATION,
                chandelierParams.attenuation.value
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                chandelierMenu.TAG_SHADOW_DISTANCE,
                chandelierParams.shadowFadeDistance.value
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                chandelierMenu.TAG_SHADOW_RANGE,
                chandelierParams.shadowFadeRange.value
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                chandelierMenu.TAG_SHADOW_BLEND,
                chandelierParams.shadowBlendFactor.value
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                chandelierMenu.TAG_OVERRIDE_COLOUR,
                chandelierParams.color.has
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                chandelierMenu.TAG_RED,
                chandelierParams.color.value.Red
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                chandelierMenu.TAG_GREEN,
                chandelierParams.color.value.Green
            );
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                chandelierMenu.TAG_BLUE,
                chandelierParams.color.value.Blue
            );
        }

        // v7 → v8: add per-source enable settings.
        if (initVersion <= 7) {
            count = lightSourceMenu.Size();
            for (i = 0; i < count; i += 1) {
                gameConfig.SetVarValue(
                    GENERAL_GROUP,
                    lightSourceMenu[i].TAG_ENABLED,
                    lightSourceParams[i].enabled.value
                );
            }
        }

        // v8 → v9: add candle point-light alignment setting.
        if (initVersion <= 8) {
            gameConfig.SetVarValue(
                GENERAL_GROUP,
                candleMenu.TAG_ALIGN_POINT_LIGHTS,
                candleParams.alignPointLights.value
            );
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

        // v10 → v11: add light spacing mode.
        if (initVersion <= 10) {
            gameConfig.SetVarValue(GENERAL_GROUP, SPACING_MODE, spacingMode);
        }

        // v11 → v12: split the spacing amount into a per-mode overlap count and budget.
        if (initVersion <= 11) {
            gameConfig.SetVarValue(GENERAL_GROUP, SPACING_COUNT, spacingCount);
            gameConfig.SetVarValue(GENERAL_GROUP, SPACING_BUDGET, spacingBudget);
        }

        gameConfig.SetVarValue(GENERAL_GROUP, INIT_VERSION, CONFIG_VERSION);
        theGame.SaveUserSettings();
    }

    // Delegates to W3GameParams.ReadLightRewriteConfig(), which can write to
    // its own fields directly.
    public function ReadGameConfig() {
        var i, count: int;

        isEnabled = gameConfig.GetVarValue(GENERAL_GROUP, ENABLED);

        profileIndex = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, CURRENT_PRESET), 0);
        if (profileIndex >= 0 && profileIndex < profileOptions.Size()) {
            currentProfile = profileOptions[profileIndex];
        }
        else {
            currentProfile = NONE_PRESET_LABEL;
        }

        spacingMode = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, SPACING_MODE), spacingMode);
        spacingCount = StringToFloat(
            gameConfig.GetVarValue(GENERAL_GROUP, SPACING_COUNT),
            spacingCount
        );
        spacingBudget = StringToFloat(
            gameConfig.GetVarValue(GENERAL_GROUP, SPACING_BUDGET),
            spacingBudget
        );

        count = lightSourceMenu.Size();
        for (i = 0; i < count; i += 1) {
            lightSourceMenu[i].ReadGameConfig(gameConfig, GENERAL_GROUP, lightSourceParams[i]);
        }
    }

    // To be called for every option-change event.
    // Filters to this mod's groups before updating cached settings.
    public function OptionValueChanged(groupId: int, optionName: name, optionValue: string) {
        var wasEnabled: bool = isEnabled;
        var i, count: int;

        if (IsMyModSettingsGroup(groupId)) {
            ReadGameConfig();

            count = lightSourceMenu.Size();
            for (i = 0; i < count; i += 1) {
                lightSourceMenu[i].OptionValueChanged(optionName, lightSourceParams[i]);
            }

            if (optionName == SPACING_MODE) UpdateSpacingMenuDisabledState();

            // ForceProcessFlashStorage() inside UpdateMenuDisabledState resets dynamic
            // option lists back to XML defaults, so we must restore them afterwards.
            if (ShouldRefreshProfileMenu(optionName)) {
                ReplacePresetMenuOptions();
            }

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

    // Apples pending settings changes.
    public function ApplyPendingChanges(): void {
        if (!(previousProfile >= 0)) previousProfile = 0;
        if (profileIndex != previousProfile) theGame.lightRewrite.ChangeProfile();
        else if (isEnabled && SpacingChanged()) theGame.lightRewrite.ApplySpacing();
    }

    private function SpacingChanged(): bool {
        return spacingMode != previousSpacingMode
            || GetSpacingAmount() != previousSpacingAmount;
    }

    // Configures the active game settings menu. Should be called after the menu is opened.
    public function ConfigureModMenu() {
        // Change detection: record the profile and spacing settings when the menu is opened
        previousProfile = profileIndex;
        previousSpacingMode = spacingMode;
        previousSpacingAmount = GetSpacingAmount();

        UpdateAllGroupsDisabledState();
        UpdateSpacingMenuDisabledState();
        ReplacePresetMenuOptions();
    }

    private function ShouldRefreshProfileMenu(optionName: name): bool {
        switch (optionName) {
            case SPACING_MODE:
            case candleMenu.TAG_ENABLED:
            case torchMenu.TAG_ENABLED:
            case brazierMenu.TAG_ENABLED:
            case candelabraMenu.TAG_ENABLED:
            case campfireMenu.TAG_ENABLED:
            case chandelierMenu.TAG_ENABLED:
            case candleMenu.TAG_OVERRIDE_COLOUR:
            case torchMenu.TAG_OVERRIDE_COLOUR:
            case brazierMenu.TAG_OVERRIDE_COLOUR:
            case candelabraMenu.TAG_OVERRIDE_COLOUR:
            case campfireMenu.TAG_OVERRIDE_COLOUR:
            case chandelierMenu.TAG_OVERRIDE_COLOUR:
                return true;
            default:
                return false;
        }
    }

    private function ReplacePresetMenuOptions() {
        var optionKeys: array<name>;

        optionKeys.PushBack(NONE_PRESET_LABEL);
        FindLightRewriteProfileNames(optionKeys);

        LR_ReplaceFlashMenuOptions(CURRENT_PRESET, CURRENT_PRESET_LABEL, GENERAL_GROUP, optionKeys);
    }

    // Ensures only the active mode's slider is enabled.
    private function UpdateSpacingMenuDisabledState() {
        var flashValueStorage: CScriptedFlashValueStorage;
        var dataArray: CScriptedFlashArray;
        var activeVar: name = GetActiveSpacingAmountVar();

        flashValueStorage = theGame.GetGuiManager().GetRootMenu().GetSubMenu().GetMenuFlashValueStorage();
        dataArray = flashValueStorage.CreateTempFlashArray();

        LR_SetMenuOptionDisabled(
            flashValueStorage,
            dataArray,
            SPACING_COUNT,
            activeVar != SPACING_COUNT
        );
        LR_SetMenuOptionDisabled(
            flashValueStorage,
            dataArray,
            SPACING_BUDGET,
            activeVar != SPACING_BUDGET
        );

        flashValueStorage.SetFlashArray("options.update_disabled", dataArray);
        theGame.GetGuiManager().ForceProcessFlashStorage();
    }

    private function UpdateAllGroupsDisabledState() {
        var i, count: int;

        count = lightSourceMenu.Size();
        for (i = 0; i < count; i += 1) {
            lightSourceMenu[i].UpdateMenuDisabledState(lightSourceParams[i]);
        }
    }

    // Gets an array of every tag that the mod might add to a valid CGameplayEntity light source
    public function GetAllLightSourceTags(): array<name> {
        var tags: array<name>;
        var overrides: array<CLightRewriteSourceParams>;
        var i, j, count, overrideCount: int;

        count = lightSourceParams.Size();
        for (i = 0; i < count; i += 1) {
            tags.PushBack(lightSourceParams[i].tag);
        }

        count = overrideGroups.Size();
        for (i = 0; i < count; i += 1) {
            overrides = overrideGroups[i].overrides;
            overrideCount = overrides.Size();
            for (j = 0; j < overrideCount; j += 1) {
                tags.PushBack(overrides[j].tag);
            }
        }

        return tags;
    }

    public function GetGlobalOverrideParams(type: ELightRewriteType): CLightRewriteSourceParams {
        switch (type) {
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
    public function FindParamsForEntity(entity: CGameplayEntity): CLightRewriteSourceParams {
        var params: CLightRewriteSourceParams = NULL;
        var i, count: int;

        // Build params object by applying all overrides that match the entity and selected profile
        if (currentProfile == NONE_PRESET_LABEL) return NULL;

        count = overrideGroups.Size();
        for (i = 0; i < count; i += 1) {
            if (overrideGroups[i].profileName != currentProfile) continue;

            overrideGroups[i].Apply(entity, params);
        }

        return params;
    }
}
