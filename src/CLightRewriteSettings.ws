/*
 * Caches LightRewrite settings from the in-game mod menu.
 */
class CLightRewriteSettings {
    // The current XML config version
    private const var CONFIG_VERSION : int;            default CONFIG_VERSION = 6;
    
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

    public var candleParams : CLightRewriteSourceParams;
    public var torchParams : CLightRewriteSourceParams;
    public var brazierParams : CLightRewriteSourceParams;
    public var candelabraParams : CLightRewriteSourceParams;
    public var campfireParams : CLightRewriteSourceParams;

    // Lazy constructor. Resolves group IDs from the config wrapper.
    public function Init() {
        gameConfig      = theGame.GetInGameConfigWrapper();
        generalGroupId  = gameConfig.GetGroupIdx(GENERAL_GROUP);

        candleParams = new CLightRewriteParamsCandle in this;
        torchParams = new CLightRewriteParamsTorch in this;
        brazierParams = new CLightRewriteParamsBrazier in this;
        candelabraParams = new CLightRewriteParamsCandelabra in this;
        campfireParams = new CLightRewriteParamsCampfire in this;

        candleParams.Init();
        torchParams.Init();
        brazierParams.Init();
        candelabraParams.Init();
        campfireParams.Init();
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

        gameConfig.SetVarValue(GENERAL_GROUP, INIT_VERSION, CONFIG_VERSION);
        theGame.SaveUserSettings();
    }

    // Delegates to W3GameParams.ReadLightRewriteConfig(), which can write to
    // its own fields directly.
    public function ReadGameConfig() {
        EnsureGameConfigIsInitialised();

        isEnabled = gameConfig.GetVarValue(GENERAL_GROUP, ENABLED);

        candleParams.brightness = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, candleParams.TAG_BRIGHTNESS), candleParams.brightness);
        candleParams.radius = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, candleParams.TAG_RADIUS), candleParams.radius);
        candleParams.attenuation = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, candleParams.TAG_ATTENUATION), candleParams.attenuation);
        candleParams.shadowFadeDistance = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, candleParams.TAG_SHADOW_DISTANCE), candleParams.shadowFadeDistance);
        candleParams.shadowFadeRange = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, candleParams.TAG_SHADOW_RANGE), candleParams.shadowFadeRange);
        candleParams.shadowBlendFactor = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, candleParams.TAG_SHADOW_BLEND), candleParams.shadowBlendFactor);
        candleParams.shouldOverrideColour = gameConfig.GetVarValue(GENERAL_GROUP, candleParams.TAG_OVERRIDE_COLOUR);
        candleParams.color.Red = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, candleParams.TAG_RED), candleParams.color.Red);
        candleParams.color.Green = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, candleParams.TAG_GREEN), candleParams.color.Green);
        candleParams.color.Blue = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, candleParams.TAG_BLUE), candleParams.color.Blue);

        torchParams.brightness = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, torchParams.TAG_BRIGHTNESS), torchParams.brightness);
        torchParams.radius = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, torchParams.TAG_RADIUS), torchParams.radius);
        torchParams.attenuation = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, torchParams.TAG_ATTENUATION), torchParams.attenuation);
        torchParams.shadowFadeDistance = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, torchParams.TAG_SHADOW_DISTANCE), torchParams.shadowFadeDistance);
        torchParams.shadowFadeRange = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, torchParams.TAG_SHADOW_RANGE), torchParams.shadowFadeRange);
        torchParams.shadowBlendFactor = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, torchParams.TAG_SHADOW_BLEND), torchParams.shadowBlendFactor);
        torchParams.shouldOverrideColour = gameConfig.GetVarValue(GENERAL_GROUP, torchParams.TAG_OVERRIDE_COLOUR);
        torchParams.color.Red = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, torchParams.TAG_RED), torchParams.color.Red);
        torchParams.color.Green = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, torchParams.TAG_GREEN), torchParams.color.Green);
        torchParams.color.Blue = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, torchParams.TAG_BLUE), torchParams.color.Blue);

        brazierParams.brightness = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, brazierParams.TAG_BRIGHTNESS), brazierParams.brightness);
        brazierParams.radius = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, brazierParams.TAG_RADIUS), brazierParams.radius);
        brazierParams.attenuation = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, brazierParams.TAG_ATTENUATION), brazierParams.attenuation);
        brazierParams.shadowFadeDistance = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, brazierParams.TAG_SHADOW_DISTANCE), brazierParams.shadowFadeDistance);
        brazierParams.shadowFadeRange = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, brazierParams.TAG_SHADOW_RANGE), brazierParams.shadowFadeRange);
        brazierParams.shadowBlendFactor = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, brazierParams.TAG_SHADOW_BLEND), brazierParams.shadowBlendFactor);
        brazierParams.shouldOverrideColour = gameConfig.GetVarValue(GENERAL_GROUP, brazierParams.TAG_OVERRIDE_COLOUR);
        brazierParams.color.Red = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, brazierParams.TAG_RED), brazierParams.color.Red);
        brazierParams.color.Green = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, brazierParams.TAG_GREEN), brazierParams.color.Green);
        brazierParams.color.Blue = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, brazierParams.TAG_BLUE), brazierParams.color.Blue);

        candelabraParams.brightness = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, candelabraParams.TAG_BRIGHTNESS), candelabraParams.brightness);
        candelabraParams.radius = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, candelabraParams.TAG_RADIUS), candelabraParams.radius);
        candelabraParams.attenuation = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, candelabraParams.TAG_ATTENUATION), candelabraParams.attenuation);
        candelabraParams.shadowFadeDistance = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, candelabraParams.TAG_SHADOW_DISTANCE), candelabraParams.shadowFadeDistance);
        candelabraParams.shadowFadeRange = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, candelabraParams.TAG_SHADOW_RANGE), candelabraParams.shadowFadeRange);
        candelabraParams.shadowBlendFactor = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, candelabraParams.TAG_SHADOW_BLEND), candelabraParams.shadowBlendFactor);
        candelabraParams.shouldOverrideColour = gameConfig.GetVarValue(GENERAL_GROUP, candelabraParams.TAG_OVERRIDE_COLOUR);
        candelabraParams.color.Red = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, candelabraParams.TAG_RED), candelabraParams.color.Red);
        candelabraParams.color.Green = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, candelabraParams.TAG_GREEN), candelabraParams.color.Green);
        candelabraParams.color.Blue = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, candelabraParams.TAG_BLUE), candelabraParams.color.Blue);

        campfireParams.brightness = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, campfireParams.TAG_BRIGHTNESS), campfireParams.brightness);
        campfireParams.radius = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, campfireParams.TAG_RADIUS), campfireParams.radius);
        campfireParams.attenuation = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, campfireParams.TAG_ATTENUATION), campfireParams.attenuation);
        campfireParams.shadowFadeDistance = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, campfireParams.TAG_SHADOW_DISTANCE), campfireParams.shadowFadeDistance);
        campfireParams.shadowFadeRange = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, campfireParams.TAG_SHADOW_RANGE), campfireParams.shadowFadeRange);
        campfireParams.shadowBlendFactor = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, campfireParams.TAG_SHADOW_BLEND), campfireParams.shadowBlendFactor);
        campfireParams.shouldOverrideColour = gameConfig.GetVarValue(GENERAL_GROUP, campfireParams.TAG_OVERRIDE_COLOUR);
        campfireParams.color.Red = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, campfireParams.TAG_RED), campfireParams.color.Red);
        campfireParams.color.Green = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, campfireParams.TAG_GREEN), campfireParams.color.Green);
        campfireParams.color.Blue = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, campfireParams.TAG_BLUE), campfireParams.color.Blue);
    }

    // To be called for every option-change event.
    // Filters to this mod's groups before updating cached settings.
    public function OptionValueChanged(groupId : int, optionName : name, optionValue : string) {
        var wasEnabled : bool = isEnabled;

        if (IsMyModSettingsGroup(groupId)) {
            ReadGameConfig();

            if (optionName == candleParams.TAG_OVERRIDE_COLOUR || optionName == torchParams.TAG_OVERRIDE_COLOUR || brazierParams.TAG_OVERRIDE_COLOUR
                || candelabraParams.TAG_OVERRIDE_COLOUR || campfireParams.TAG_OVERRIDE_COLOUR) {
                UpdateColourSliderDisabledState();
            }

            // If we've just turned the mod off, disable all nearby entities.
            if (isEnabled != wasEnabled && !isEnabled) {
                DisableAllNearbyEntities();
            }

            // Otherwise, if we changed any setting AND the mod is enabled, run the light rewrite.
            else if (isEnabled) {
                EnableAllNearbyEntities();
            }
        }
    }

    // Configures the active game settings menu. Should be called after the menu is opened.
    public function ConfigureModMenu() {
        UpdateColourSliderDisabledState();
    }

    private function UpdateColourSliderDisabledState() {
        var flashValueStorage : CScriptedFlashValueStorage;
        var dataArray : CScriptedFlashArray;

        flashValueStorage = theGame.GetGuiManager().GetRootMenu().GetSubMenu().GetMenuFlashValueStorage();
        dataArray = flashValueStorage.CreateTempFlashArray();

        SetOptionDisabledState(flashValueStorage, dataArray, candleParams.TAG_RED, !candleParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, candleParams.TAG_GREEN, !candleParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, candleParams.TAG_BLUE, !candleParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, torchParams.TAG_RED, !torchParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, torchParams.TAG_GREEN, !torchParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, torchParams.TAG_BLUE, !torchParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, brazierParams.TAG_RED, !brazierParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, brazierParams.TAG_GREEN, !brazierParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, brazierParams.TAG_BLUE, !brazierParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, candelabraParams.TAG_RED, !candelabraParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, candelabraParams.TAG_GREEN, !candelabraParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, candelabraParams.TAG_BLUE, !candelabraParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, campfireParams.TAG_RED, !campfireParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, campfireParams.TAG_GREEN, !campfireParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, campfireParams.TAG_BLUE, !campfireParams.shouldOverrideColour);

        flashValueStorage.SetFlashArray("options.update_disabled", dataArray);
        theGame.GetGuiManager().ForceProcessFlashStorage();
    }

    private function SetOptionDisabledState(
        flashValueStorage : CScriptedFlashValueStorage,
        out dataArray : CScriptedFlashArray,
        optionName : name,
        value : bool
    ) {
        var dataObject : CScriptedFlashObject = flashValueStorage.CreateTempFlashObject();

        dataObject.SetMemberFlashUInt("tag", NameToFlashUInt(optionName));
        dataObject.SetMemberFlashBool("disabled", value);
        dataArray.PushBackFlashObject(dataObject);
    }

    private function EnableAllNearbyEntities() {
        var i, count : int;
        var entities : array<CGameplayEntity>;

        GetAllLightSourceEntities(entities);
        count = entities.Size();

        LogLightRewrite("Enabling Light Rewrite for " + count + " entities");

        for (i = 0; i < count; i += 1) {
            entities[i].CandleLightRewrite();
        }
    }

    private function DisableAllNearbyEntities() {
        var i, count : int;
        var entities : array<CGameplayEntity>;

        GetAllLightSourceEntities(entities);
        count = entities.Size();

        LogLightRewrite("Disabling Light Rewrite for " + count + " entities");

        for (i = 0; i < count; i += 1) {
            entities[i].DisableLightRewrite();
        }
    }

    private function GetAllLightSourceEntities(out entities : array<CGameplayEntity>) {
        var tags : array<name>;
        var nodes : array<CNode>;
        var entity : CGameplayEntity;
        var i : int;
        var count : int;

        tags.PushBack(candleParams.tag);
        tags.PushBack(torchParams.tag);
        tags.PushBack(brazierParams.tag);
        tags.PushBack(candelabraParams.tag);
        tags.PushBack(campfireParams.tag);
   
        theGame.GetNodesByTags(tags, nodes);
        count = nodes.Size();

        for (i = 0; i < count; i += 1) {
            entity = (CGameplayEntity)nodes[i];
            if (entity) entities.PushBack(entity);
        }
    }
}
