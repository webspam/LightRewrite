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
        gameConfig = theGame.GetInGameConfigWrapper();
        generalGroupId = gameConfig.GetGroupIdx(GENERAL_GROUP);

        overrideGroups = LoadLightRewriteOverrides(this);

        profileOptions.PushBack(NONE_PRESET_LABEL);
        FindLightRewriteProfileNames(profileOptions);
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
    public function EnsureGameConfigIsInitialised() {
        var initVersion: int = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, INIT_VERSION), 0);

        if (initVersion == CONFIG_VERSION) return;

        LogLightRewrite("Migrating config from version " + initVersion + " to " + CONFIG_VERSION);

        // Never initialised - write defaults for the current settings.
        if (initVersion == 0) {
            gameConfig.SetVarValue(GENERAL_GROUP, ENABLED, isEnabled);
            gameConfig.SetVarValue(GENERAL_GROUP, SPACING_MODE, spacingMode);
            gameConfig.SetVarValue(GENERAL_GROUP, SPACING_COUNT, spacingCount);
            gameConfig.SetVarValue(GENERAL_GROUP, SPACING_BUDGET, spacingBudget);
        }

        gameConfig.SetVarValue(GENERAL_GROUP, INIT_VERSION, CONFIG_VERSION);
        theGame.SaveUserSettings();
    }

    public function ReadGameConfig() {
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
    }

    // To be called for every option-change event.
    // Filters to this mod's groups before updating cached settings.
    public function OptionValueChanged(groupId: int, optionName: name, optionValue: string) {
        var wasEnabled: bool = isEnabled;

        if (IsMyModSettingsGroup(groupId)) {
            ReadGameConfig();

            if (optionName == SPACING_MODE) UpdateSpacingMenuDisabledState();

            // ForceProcessFlashStorage() inside UpdateSpacingMenuDisabledState resets dynamic
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

        UpdateSpacingMenuDisabledState();
        ReplacePresetMenuOptions();
    }

    private function ShouldRefreshProfileMenu(optionName: name): bool {
        return optionName == SPACING_MODE;
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

    // Gets an array of every tag that the mod might add to a valid CGameplayEntity light source
    public function GetAllLightSourceTags(): array<name> {
        var tags: array<name>;
        var overrides: array<CLightRewriteSourceParams>;
        var i, j, count, overrideCount: int;

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

    // Finds the params for a given entity.
    public function FindParamsForEntity(entity: CGameplayEntity): CLightRewriteSourceParams {
        var params: CLightRewriteSourceParams = NULL;
        var i, count: int;

        // Build params object by applying all overrides that match the entity and selected profile
        if (currentProfile == NONE_PRESET_LABEL) return NULL;

        count = overrideGroups.Size();
        for (i = 0; i < count; i += 1) {
            if (overrideGroups[i].profileName != currentProfile) continue;

            params = overrideGroups[i].Apply(entity, params);
        }

        return params;
    }
}
