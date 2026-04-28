/*
 * Caches LightRewrite settings from the in-game mod menu.
 */
class CLightRewriteSettings {
    // The current XML config version
    private const var CONFIG_VERSION : string;         default CONFIG_VERSION = "3";
    
    // Group name constants (must match XML Group id values)
    private const var GENERAL_GROUP : name;            default GENERAL_GROUP = 'LightRewrite_General';

    // Setting name constants (must match XML Var id values)
    private const var ENABLED : name;                  default ENABLED                = 'Enabled';
    private const var CANDLE_ATTENUATION : name;       default CANDLE_ATTENUATION     = 'CandleAttenuation';
    private const var TORCH_ATTENUATION : name;        default TORCH_ATTENUATION      = 'TorchAttenuation';
    private const var SHADOW_FADE_DISTANCE : name;     default SHADOW_FADE_DISTANCE   = 'ShadowFadeDistance';
    private const var SHADOW_FADE_RANGE : name;        default SHADOW_FADE_RANGE      = 'ShadowFadeRange';
    private const var SHADOW_BLEND_FACTOR : name;      default SHADOW_BLEND_FACTOR    = 'ShadowBlendFactor';
    private const var CANDLE_BRIGHTNESS : name;        default CANDLE_BRIGHTNESS      = 'CandleBrightness';
    private const var TORCH_BRIGHTNESS : name;         default TORCH_BRIGHTNESS       = 'TorchBrightness';
    private const var CANDLE_RADIUS : name;            default CANDLE_RADIUS          = 'CandleRadius';
    private const var TORCH_RADIUS : name;             default TORCH_RADIUS           = 'TorchRadius';
    private const var OVERRIDE_CANDLE_COLOUR : name;   default OVERRIDE_CANDLE_COLOUR = 'OverrideCandleColour';
    private const var CANDLE_COLOR_R : name;           default CANDLE_COLOR_R         = 'CandleColorR';
    private const var CANDLE_COLOR_G : name;           default CANDLE_COLOR_G         = 'CandleColorG';
    private const var CANDLE_COLOR_B : name;           default CANDLE_COLOR_B         = 'CandleColorB';
    private const var OVERRIDE_TORCH_COLOUR : name;    default OVERRIDE_TORCH_COLOUR  = 'OverrideTorchColour';
    private const var TORCH_COLOR_R : name;            default TORCH_COLOR_R          = 'TorchColorR';
    private const var TORCH_COLOR_G : name;            default TORCH_COLOR_G          = 'TorchColorG';
    private const var TORCH_COLOR_B : name;            default TORCH_COLOR_B          = 'TorchColorB';
    private const var INIT_VERSION : name;             default INIT_VERSION           = 'InitVersion';

    // Tags
    public const var TAG_LR_CANDLE : name;             default TAG_LR_CANDLE             = 'LR_Candle';
    public const var TAG_LR_TORCH : name;              default TAG_LR_TORCH              = 'LR_Torch';

    // Internal group IDs resolved at init time
    private var generalGroupId  : int;

    private var gameConfig : CInGameConfigWrapper;

    // Light rewrite parameters
    public var LR_ENABLED : bool;                      default LR_ENABLED                = true;
    public var LR_SHADOW_FADE_DISTANCE : float;        default LR_SHADOW_FADE_DISTANCE   = 10.f;
    public var LR_SHADOW_FADE_RANGE : float;           default LR_SHADOW_FADE_RANGE      = 3.f;
    public var LR_SHADOW_BLEND_FACTOR : float;         default LR_SHADOW_BLEND_FACTOR    = 1.f;

    public var LR_CANDLE_BRIGHTNESS : float;           default LR_CANDLE_BRIGHTNESS      = 5.5f;
    public var LR_CANDLE_RADIUS : float;               default LR_CANDLE_RADIUS          = 9.f;
    public var LR_CANDLE_ATTENUATION : float;          default LR_CANDLE_ATTENUATION     = 1.0f;
    public var LR_OVERRIDE_CANDLE_COLOUR : bool;       default LR_OVERRIDE_CANDLE_COLOUR = false;
    public var LR_CANDLE_COLOR_R : int;                default LR_CANDLE_COLOR_R         = 240;
    public var LR_CANDLE_COLOR_G : int;                default LR_CANDLE_COLOR_G         = 245;
    public var LR_CANDLE_COLOR_B : int;                default LR_CANDLE_COLOR_B         = 255;

    public var LR_TORCH_BRIGHTNESS : float;            default LR_TORCH_BRIGHTNESS       = 30.f;
    public var LR_TORCH_RADIUS : float;                default LR_TORCH_RADIUS           = 20.f;
    public var LR_TORCH_ATTENUATION : float;           default LR_TORCH_ATTENUATION      = 1.0f;
    public var LR_OVERRIDE_TORCH_COLOUR : bool;        default LR_OVERRIDE_TORCH_COLOUR  = false;
    public var LR_TORCH_COLOR_R : int;                 default LR_TORCH_COLOR_R          = 255;
    public var LR_TORCH_COLOR_G : int;                 default LR_TORCH_COLOR_G          = 255;
    public var LR_TORCH_COLOR_B : int;                 default LR_TORCH_COLOR_B          = 255;


    // Lazy constructor. Resolves group IDs from the config wrapper.
    public function Init() {
        gameConfig      = theGame.GetInGameConfigWrapper();
        generalGroupId  = gameConfig.GetGroupIdx(GENERAL_GROUP);
    }

    // Returns true if groupId belongs to one of this mod's settings groups.
    // Used to filter out option-change events fired by other mods.
    public function IsMyModSettingsGroup(groupId : int) : bool {
        return groupId == generalGroupId;
    }

    // If mod config has never been initialised, set the default values and save them.
    // Handles migration from older versions by writing any keys added since the stored version.
    public function EnsureGameConfigIsInitialised() {
        var initVersion : string = gameConfig.GetVarValue(GENERAL_GROUP, INIT_VERSION);
        var oldAttenuation : string;

        if (initVersion == CONFIG_VERSION) return;

        // v1 → v2: promote the old global attenuation value to both per-source keys.
        if (initVersion == "1") {
            oldAttenuation = gameConfig.GetVarValue(GENERAL_GROUP, 'Attenuation');

            if (StringToFloat(oldAttenuation, -1.f) != -1.f) {
                gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_ATTENUATION, oldAttenuation);
                gameConfig.SetVarValue(GENERAL_GROUP, TORCH_ATTENUATION, oldAttenuation);
            } else {
                gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_ATTENUATION, LR_CANDLE_ATTENUATION);
                gameConfig.SetVarValue(GENERAL_GROUP, TORCH_ATTENUATION, LR_TORCH_ATTENUATION);
            }
        }

        // v2 → v3: add per-source colour override settings.
        if (initVersion == "1" || initVersion == "2") {
            gameConfig.SetVarValue(GENERAL_GROUP, OVERRIDE_CANDLE_COLOUR, LR_OVERRIDE_CANDLE_COLOUR);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_COLOR_R, LR_CANDLE_COLOR_R);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_COLOR_G, LR_CANDLE_COLOR_G);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_COLOR_B, LR_CANDLE_COLOR_B);
            gameConfig.SetVarValue(GENERAL_GROUP, OVERRIDE_TORCH_COLOUR, LR_OVERRIDE_TORCH_COLOUR);
            gameConfig.SetVarValue(GENERAL_GROUP, TORCH_COLOR_R, LR_TORCH_COLOR_R);
            gameConfig.SetVarValue(GENERAL_GROUP, TORCH_COLOR_G, LR_TORCH_COLOR_G);
            gameConfig.SetVarValue(GENERAL_GROUP, TORCH_COLOR_B, LR_TORCH_COLOR_B);
        }

        // Never initialised - write all defaults.
        else if (!initVersion) {
            gameConfig.SetVarValue(GENERAL_GROUP, ENABLED, LR_ENABLED);
            gameConfig.SetVarValue(GENERAL_GROUP, SHADOW_FADE_DISTANCE, LR_SHADOW_FADE_DISTANCE);
            gameConfig.SetVarValue(GENERAL_GROUP, SHADOW_FADE_RANGE, LR_SHADOW_FADE_RANGE);
            gameConfig.SetVarValue(GENERAL_GROUP, SHADOW_BLEND_FACTOR, LR_SHADOW_BLEND_FACTOR);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_BRIGHTNESS, LR_CANDLE_BRIGHTNESS);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_RADIUS, LR_CANDLE_RADIUS);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_ATTENUATION, LR_CANDLE_ATTENUATION);
            gameConfig.SetVarValue(GENERAL_GROUP, TORCH_BRIGHTNESS, LR_TORCH_BRIGHTNESS);
            gameConfig.SetVarValue(GENERAL_GROUP, TORCH_RADIUS, LR_TORCH_RADIUS);
            gameConfig.SetVarValue(GENERAL_GROUP, TORCH_ATTENUATION, LR_TORCH_ATTENUATION);
            gameConfig.SetVarValue(GENERAL_GROUP, OVERRIDE_CANDLE_COLOUR, LR_OVERRIDE_CANDLE_COLOUR);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_COLOR_R, LR_CANDLE_COLOR_R);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_COLOR_G, LR_CANDLE_COLOR_G);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_COLOR_B, LR_CANDLE_COLOR_B);
            gameConfig.SetVarValue(GENERAL_GROUP, OVERRIDE_TORCH_COLOUR, LR_OVERRIDE_TORCH_COLOUR);
            gameConfig.SetVarValue(GENERAL_GROUP, TORCH_COLOR_R, LR_TORCH_COLOR_R);
            gameConfig.SetVarValue(GENERAL_GROUP, TORCH_COLOR_G, LR_TORCH_COLOR_G);
            gameConfig.SetVarValue(GENERAL_GROUP, TORCH_COLOR_B, LR_TORCH_COLOR_B);
        }

        gameConfig.SetVarValue(GENERAL_GROUP, INIT_VERSION, CONFIG_VERSION);
        theGame.SaveUserSettings();
    }

    // Delegates to W3GameParams.ReadLightRewriteConfig(), which can write to
    // its own fields directly.
    public function ReadGameConfig() {
        var val : string;

        EnsureGameConfigIsInitialised();

        LR_ENABLED = gameConfig.GetVarValue(GENERAL_GROUP, ENABLED);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CANDLE_BRIGHTNESS);
        if (val != "") LR_CANDLE_BRIGHTNESS = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CANDLE_RADIUS);
        if (val != "") LR_CANDLE_RADIUS = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CANDLE_ATTENUATION);
        if (val != "") LR_CANDLE_ATTENUATION = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, TORCH_BRIGHTNESS);
        if (val != "") LR_TORCH_BRIGHTNESS = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, TORCH_RADIUS);
        if (val != "") LR_TORCH_RADIUS = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, TORCH_ATTENUATION);
        if (val != "") LR_TORCH_ATTENUATION = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, SHADOW_FADE_DISTANCE);
        if (val != "") LR_SHADOW_FADE_DISTANCE = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, SHADOW_FADE_RANGE);
        if (val != "") LR_SHADOW_FADE_RANGE = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, SHADOW_BLEND_FACTOR);
        if (val != "") LR_SHADOW_BLEND_FACTOR = StringToFloat(val);

        LR_OVERRIDE_CANDLE_COLOUR = gameConfig.GetVarValue(GENERAL_GROUP, OVERRIDE_CANDLE_COLOUR);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CANDLE_COLOR_R);
        if (val != "") LR_CANDLE_COLOR_R = (int)StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CANDLE_COLOR_G);
        if (val != "") LR_CANDLE_COLOR_G = (int)StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CANDLE_COLOR_B);
        if (val != "") LR_CANDLE_COLOR_B = (int)StringToFloat(val);

        LR_OVERRIDE_TORCH_COLOUR = gameConfig.GetVarValue(GENERAL_GROUP, OVERRIDE_TORCH_COLOUR);

        val = gameConfig.GetVarValue(GENERAL_GROUP, TORCH_COLOR_R);
        if (val != "") LR_TORCH_COLOR_R = (int)StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, TORCH_COLOR_G);
        if (val != "") LR_TORCH_COLOR_G = (int)StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, TORCH_COLOR_B);
        if (val != "") LR_TORCH_COLOR_B = (int)StringToFloat(val);
    }

    // To be called for every option-change event.
    // Filters to this mod's groups before updating cached settings.
    public function OptionValueChanged(groupId : int, optionName : name, optionValue : string) {
        var isEnabled : bool = LR_ENABLED;

        if (IsMyModSettingsGroup(groupId)) {
            ReadGameConfig();

            if (optionName == OVERRIDE_CANDLE_COLOUR || optionName == OVERRIDE_TORCH_COLOUR) {
                UpdateColourSliderDisabledState();
            }

            // If we've just turned the mod off, disable all nearby entities.
            if (isEnabled != LR_ENABLED && !LR_ENABLED) {
                DisableAllNearbyEntities();
            }

            // Otherwise, if we changed any setting AND the mod is enabled, run the light rewrite.
            else if (LR_ENABLED) {
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

        SetOptionDisabledState(flashValueStorage, dataArray, 'CandleColorR', !LR_OVERRIDE_CANDLE_COLOUR);
        SetOptionDisabledState(flashValueStorage, dataArray, 'CandleColorG', !LR_OVERRIDE_CANDLE_COLOUR);
        SetOptionDisabledState(flashValueStorage, dataArray, 'CandleColorB', !LR_OVERRIDE_CANDLE_COLOUR);
        SetOptionDisabledState(flashValueStorage, dataArray, 'TorchColorR',  !LR_OVERRIDE_TORCH_COLOUR);
        SetOptionDisabledState(flashValueStorage, dataArray, 'TorchColorG',  !LR_OVERRIDE_TORCH_COLOUR);
        SetOptionDisabledState(flashValueStorage, dataArray, 'TorchColorB',  !LR_OVERRIDE_TORCH_COLOUR);

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
        var i : int;
        var entities : array<CGameplayEntity>;

        GetAllNearbyEntities(entities);

        LogLightRewrite("Enabling " + entities.Size() + " nearby entities");

        for (i = 0; i < entities.Size(); i += 1) {
            entities[i].CandleLightRewrite();
        }
    }

    private function DisableAllNearbyEntities() {
        var i : int;
        var entities : array<CGameplayEntity>;

        GetAllNearbyEntities(entities);

        LogLightRewrite("Disabling " + entities.Size() + " nearby entities");

        for (i = 0; i < entities.Size(); i += 1) {
            entities[i].DisableLightRewrite();
        }
    }

    private function GetAllNearbyEntities(out entities : array<CGameplayEntity>) {
        var interimEntities : array<CGameplayEntity>;
        var i : int;
        var entity : CGameplayEntity;

        FindGameplayEntitiesInRange(interimEntities, thePlayer, 1000.f, 1024, TAG_LR_CANDLE);
        LogLightRewrite("Get nearby candles: Found " + interimEntities.Size() + " nearby entities");

        for (i = 0; i < interimEntities.Size(); i += 1) {
            entity = interimEntities[i];
            entity.IdentifyLightRewriteType();

            if (entity.IsLightRewritable()) {
                entities.PushBack(entity);
            }
        }

        FindGameplayEntitiesInRange(interimEntities, thePlayer, 1000.f, 1024, TAG_LR_TORCH);
        LogLightRewrite("Get nearby torches: Found " + interimEntities.Size() + " nearby entities");

        for (i = 0; i < interimEntities.Size(); i += 1) {
            entity = interimEntities[i];
            entity.IdentifyLightRewriteType();

            if (entity.IsLightRewritable()) {
                entities.PushBack(entity);
            }
        }
    }
}
