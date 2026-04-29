/*
 * Caches LightRewrite settings from the in-game mod menu.
 */
class CLightRewriteSettings {
    // The current XML config version
    private const var CONFIG_VERSION : string;         default CONFIG_VERSION = "5";
    
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
    private const var BRAZIER_BRIGHTNESS : name;       default BRAZIER_BRIGHTNESS     = 'BrazierBrightness';
    private const var BRAZIER_RADIUS : name;           default BRAZIER_RADIUS         = 'BrazierRadius';
    private const var BRAZIER_ATTENUATION : name;      default BRAZIER_ATTENUATION    = 'BrazierAttenuation';
    private const var OVERRIDE_BRAZIER_COLOUR : name;  default OVERRIDE_BRAZIER_COLOUR = 'OverrideBrazierColour';
    private const var BRAZIER_COLOR_R : name;          default BRAZIER_COLOR_R        = 'BrazierColorR';
    private const var BRAZIER_COLOR_G : name;          default BRAZIER_COLOR_G        = 'BrazierColorG';
    private const var BRAZIER_COLOR_B : name;          default BRAZIER_COLOR_B        = 'BrazierColorB';
    private const var CANDELABRA_BRIGHTNESS : name;    default CANDELABRA_BRIGHTNESS  = 'CandelabraBrightness';
    private const var CANDELABRA_RADIUS : name;        default CANDELABRA_RADIUS      = 'CandelabraRadius';
    private const var CANDELABRA_ATTENUATION : name;   default CANDELABRA_ATTENUATION = 'CandelabraAttenuation';
    private const var OVERRIDE_CANDELABRA_COLOUR : name; default OVERRIDE_CANDELABRA_COLOUR = 'OverrideCandelabraColour';
    private const var CANDELABRA_COLOR_R : name;       default CANDELABRA_COLOR_R     = 'CandelabraColorR';
    private const var CANDELABRA_COLOR_G : name;       default CANDELABRA_COLOR_G     = 'CandelabraColorG';
    private const var CANDELABRA_COLOR_B : name;       default CANDELABRA_COLOR_B     = 'CandelabraColorB';
    private const var CAMPFIRE_BRIGHTNESS : name;      default CAMPFIRE_BRIGHTNESS    = 'CampfireBrightness';
    private const var CAMPFIRE_RADIUS : name;          default CAMPFIRE_RADIUS        = 'CampfireRadius';
    private const var CAMPFIRE_ATTENUATION : name;     default CAMPFIRE_ATTENUATION   = 'CampfireAttenuation';
    private const var OVERRIDE_CAMPFIRE_COLOUR : name; default OVERRIDE_CAMPFIRE_COLOUR = 'OverrideCampfireColour';
    private const var CAMPFIRE_COLOR_R : name;         default CAMPFIRE_COLOR_R       = 'CampfireColorR';
    private const var CAMPFIRE_COLOR_G : name;         default CAMPFIRE_COLOR_G       = 'CampfireColorG';
    private const var CAMPFIRE_COLOR_B : name;         default CAMPFIRE_COLOR_B       = 'CampfireColorB';
    private const var INIT_VERSION : name;             default INIT_VERSION           = 'InitVersion';

    // Tags
    private const var TAG_LR_CANDLE : name;             default TAG_LR_CANDLE             = 'LR_Candle';
    private const var TAG_LR_TORCH : name;              default TAG_LR_TORCH              = 'LR_Torch';
    private const var TAG_LR_BRAZIER : name;            default TAG_LR_BRAZIER            = 'LR_Brazier';
    private const var TAG_LR_CANDELABRA : name;         default TAG_LR_CANDELABRA         = 'LR_Candelabra';
    private const var TAG_LR_CAMPFIRE : name;           default TAG_LR_CAMPFIRE           = 'LR_Campfire';

    // Internal group IDs resolved at init time
    private var generalGroupId  : int;

    private var gameConfig : CInGameConfigWrapper;

    // Light rewrite parameters
    public var isEnabled : bool;                      default isEnabled                = true;
    public var shadowFadeDistance : float;             default shadowFadeDistance        = 10.f;
    public var shadowFadeRange : float;                default shadowFadeRange           = 3.f;
    public var shadowBlendFactor : float;              default shadowBlendFactor         = 1.f;

    public var candleParams : CLightRewriteSourceParams;
    public var torchParams : CLightRewriteSourceParams;
    public var brazierParams : CLightRewriteSourceParams;
    public var candelabraParams : CLightRewriteSourceParams;
    public var campfireParams : CLightRewriteSourceParams;

    // Lazy constructor. Resolves group IDs from the config wrapper.
    public function Init() {
        gameConfig      = theGame.GetInGameConfigWrapper();
        generalGroupId  = gameConfig.GetGroupIdx(GENERAL_GROUP);

        candleParams = new CLightRewriteSourceParams in this;
        torchParams = new CLightRewriteSourceParams in this;
        brazierParams = new CLightRewriteSourceParams in this;
        candelabraParams = new CLightRewriteSourceParams in this;
        campfireParams = new CLightRewriteSourceParams in this;

        candleParams.tag = TAG_LR_CANDLE;
        torchParams.tag = TAG_LR_TORCH;
        brazierParams.tag = TAG_LR_BRAZIER;
        candelabraParams.tag = TAG_LR_CANDELABRA;
        campfireParams.tag = TAG_LR_CAMPFIRE;

        candleParams.useSpotlightColor = true;
        candleParams.brightness = 5.5f;
        candleParams.radius = 9.f;
        candleParams.attenuation = 1.0f;
        candleParams.shouldOverrideColour = false;
        candleParams.color.Red = 240;
        candleParams.color.Green = 245;
        candleParams.color.Blue = 255;

        torchParams.useSpotlightColor = false;
        torchParams.brightness = 30.f;
        torchParams.radius = 20.f;
        torchParams.attenuation = 1.0f;
        torchParams.shouldOverrideColour = false;
        torchParams.color.Red = 255;
        torchParams.color.Green = 255;
        torchParams.color.Blue = 255;

        brazierParams.useSpotlightColor = false;
        brazierParams.brightness = 40.f;
        brazierParams.radius = 25.f;
        brazierParams.attenuation = 1.0f;
        brazierParams.shouldOverrideColour = false;
        brazierParams.color.Red = 255;
        brazierParams.color.Green = 255;
        brazierParams.color.Blue = 255;

        candelabraParams.useSpotlightColor = true;
        candelabraParams.brightness = 8.0f;
        candelabraParams.radius = 12.f;
        candelabraParams.attenuation = 1.0f;
        candelabraParams.shouldOverrideColour = false;
        candelabraParams.color.Red = 255;
        candelabraParams.color.Green = 255;
        candelabraParams.color.Blue = 255;

        campfireParams.useSpotlightColor = false;
        campfireParams.brightness = 50.f;
        campfireParams.radius = 30.f;
        campfireParams.attenuation = 1.0f;
        campfireParams.shouldOverrideColour = false;
        campfireParams.color.Red = 255;
        campfireParams.color.Green = 255;
        campfireParams.color.Blue = 255;
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
                gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_ATTENUATION, candleParams.attenuation);
                gameConfig.SetVarValue(GENERAL_GROUP, TORCH_ATTENUATION, torchParams.attenuation);
            }
        }

        // v2 → v3: add per-source colour override settings.
        if (initVersion == "1" || initVersion == "2") {
            gameConfig.SetVarValue(GENERAL_GROUP, OVERRIDE_CANDLE_COLOUR, candleParams.shouldOverrideColour);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_COLOR_R, candleParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_COLOR_G, candleParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_COLOR_B, candleParams.color.Blue);
            gameConfig.SetVarValue(GENERAL_GROUP, OVERRIDE_TORCH_COLOUR, torchParams.shouldOverrideColour);
            gameConfig.SetVarValue(GENERAL_GROUP, TORCH_COLOR_R, torchParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, TORCH_COLOR_G, torchParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, TORCH_COLOR_B, torchParams.color.Blue);
        }

        // v3 → v4: add brazier light source settings.
        if (initVersion == "1" || initVersion == "2" || initVersion == "3") {
            gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_BRIGHTNESS, brazierParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_RADIUS, brazierParams.radius);
            gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_ATTENUATION, brazierParams.attenuation);
            gameConfig.SetVarValue(GENERAL_GROUP, OVERRIDE_BRAZIER_COLOUR, brazierParams.shouldOverrideColour);
            gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_COLOR_R, brazierParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_COLOR_G, brazierParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_COLOR_B, brazierParams.color.Blue);
        }

        // v4 → v5: add candelabra and campfire light source settings.
        if (initVersion == "1" || initVersion == "2" || initVersion == "3" || initVersion == "4") {
            gameConfig.SetVarValue(GENERAL_GROUP, CANDELABRA_BRIGHTNESS, candelabraParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDELABRA_RADIUS, candelabraParams.radius);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDELABRA_ATTENUATION, candelabraParams.attenuation);
            gameConfig.SetVarValue(GENERAL_GROUP, OVERRIDE_CANDELABRA_COLOUR, candelabraParams.shouldOverrideColour);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDELABRA_COLOR_R, candelabraParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDELABRA_COLOR_G, candelabraParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDELABRA_COLOR_B, candelabraParams.color.Blue);
            gameConfig.SetVarValue(GENERAL_GROUP, CAMPFIRE_BRIGHTNESS, campfireParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, CAMPFIRE_RADIUS, campfireParams.radius);
            gameConfig.SetVarValue(GENERAL_GROUP, CAMPFIRE_ATTENUATION, campfireParams.attenuation);
            gameConfig.SetVarValue(GENERAL_GROUP, OVERRIDE_CAMPFIRE_COLOUR, campfireParams.shouldOverrideColour);
            gameConfig.SetVarValue(GENERAL_GROUP, CAMPFIRE_COLOR_R, campfireParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, CAMPFIRE_COLOR_G, campfireParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, CAMPFIRE_COLOR_B, campfireParams.color.Blue);
        }

        // Never initialised - write all defaults.
        else if (!initVersion) {
            gameConfig.SetVarValue(GENERAL_GROUP, ENABLED, isEnabled);
            gameConfig.SetVarValue(GENERAL_GROUP, SHADOW_FADE_DISTANCE, shadowFadeDistance);
            gameConfig.SetVarValue(GENERAL_GROUP, SHADOW_FADE_RANGE, shadowFadeRange);
            gameConfig.SetVarValue(GENERAL_GROUP, SHADOW_BLEND_FACTOR, shadowBlendFactor);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_BRIGHTNESS, candleParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_RADIUS, candleParams.radius);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_ATTENUATION, candleParams.attenuation);
            gameConfig.SetVarValue(GENERAL_GROUP, TORCH_BRIGHTNESS, torchParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, TORCH_RADIUS, torchParams.radius);
            gameConfig.SetVarValue(GENERAL_GROUP, TORCH_ATTENUATION, torchParams.attenuation);
            gameConfig.SetVarValue(GENERAL_GROUP, OVERRIDE_CANDLE_COLOUR, candleParams.shouldOverrideColour);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_COLOR_R, candleParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_COLOR_G, candleParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_COLOR_B, candleParams.color.Blue);
            gameConfig.SetVarValue(GENERAL_GROUP, OVERRIDE_TORCH_COLOUR, torchParams.shouldOverrideColour);
            gameConfig.SetVarValue(GENERAL_GROUP, TORCH_COLOR_R, torchParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, TORCH_COLOR_G, torchParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, TORCH_COLOR_B, torchParams.color.Blue);
            gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_BRIGHTNESS, brazierParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_RADIUS, brazierParams.radius);
            gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_ATTENUATION, brazierParams.attenuation);
            gameConfig.SetVarValue(GENERAL_GROUP, OVERRIDE_BRAZIER_COLOUR, brazierParams.shouldOverrideColour);
            gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_COLOR_R, brazierParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_COLOR_G, brazierParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_COLOR_B, brazierParams.color.Blue);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDELABRA_BRIGHTNESS, candelabraParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDELABRA_RADIUS, candelabraParams.radius);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDELABRA_ATTENUATION, candelabraParams.attenuation);
            gameConfig.SetVarValue(GENERAL_GROUP, OVERRIDE_CANDELABRA_COLOUR, candelabraParams.shouldOverrideColour);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDELABRA_COLOR_R, candelabraParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDELABRA_COLOR_G, candelabraParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDELABRA_COLOR_B, candelabraParams.color.Blue);
            gameConfig.SetVarValue(GENERAL_GROUP, CAMPFIRE_BRIGHTNESS, campfireParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, CAMPFIRE_RADIUS, campfireParams.radius);
            gameConfig.SetVarValue(GENERAL_GROUP, CAMPFIRE_ATTENUATION, campfireParams.attenuation);
            gameConfig.SetVarValue(GENERAL_GROUP, OVERRIDE_CAMPFIRE_COLOUR, campfireParams.shouldOverrideColour);
            gameConfig.SetVarValue(GENERAL_GROUP, CAMPFIRE_COLOR_R, campfireParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, CAMPFIRE_COLOR_G, campfireParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, CAMPFIRE_COLOR_B, campfireParams.color.Blue);
        }

        gameConfig.SetVarValue(GENERAL_GROUP, INIT_VERSION, CONFIG_VERSION);
        theGame.SaveUserSettings();
    }

    // Delegates to W3GameParams.ReadLightRewriteConfig(), which can write to
    // its own fields directly.
    public function ReadGameConfig() {
        var val : string;

        EnsureGameConfigIsInitialised();

        isEnabled = gameConfig.GetVarValue(GENERAL_GROUP, ENABLED);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CANDLE_BRIGHTNESS);
        if (val != "") candleParams.brightness = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CANDLE_RADIUS);
        if (val != "") candleParams.radius = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CANDLE_ATTENUATION);
        if (val != "") candleParams.attenuation = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, TORCH_BRIGHTNESS);
        if (val != "") torchParams.brightness = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, TORCH_RADIUS);
        if (val != "") torchParams.radius = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, TORCH_ATTENUATION);
        if (val != "") torchParams.attenuation = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, SHADOW_FADE_DISTANCE);
        if (val != "") shadowFadeDistance = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, SHADOW_FADE_RANGE);
        if (val != "") shadowFadeRange = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, SHADOW_BLEND_FACTOR);
        if (val != "") shadowBlendFactor = StringToFloat(val);

        candleParams.shouldOverrideColour = gameConfig.GetVarValue(GENERAL_GROUP, OVERRIDE_CANDLE_COLOUR);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CANDLE_COLOR_R);
        if (val != "") candleParams.color.Red = (int)StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CANDLE_COLOR_G);
        if (val != "") candleParams.color.Green = (int)StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CANDLE_COLOR_B);
        if (val != "") candleParams.color.Blue = (int)StringToFloat(val);

        torchParams.shouldOverrideColour = gameConfig.GetVarValue(GENERAL_GROUP, OVERRIDE_TORCH_COLOUR);

        val = gameConfig.GetVarValue(GENERAL_GROUP, TORCH_COLOR_R);
        if (val != "") torchParams.color.Red = (int)StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, TORCH_COLOR_G);
        if (val != "") torchParams.color.Green = (int)StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, TORCH_COLOR_B);
        if (val != "") torchParams.color.Blue = (int)StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, BRAZIER_BRIGHTNESS);
        if (val != "") brazierParams.brightness = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, BRAZIER_RADIUS);
        if (val != "") brazierParams.radius = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, BRAZIER_ATTENUATION);
        if (val != "") brazierParams.attenuation = StringToFloat(val);

        brazierParams.shouldOverrideColour = gameConfig.GetVarValue(GENERAL_GROUP, OVERRIDE_BRAZIER_COLOUR);

        val = gameConfig.GetVarValue(GENERAL_GROUP, BRAZIER_COLOR_R);
        if (val != "") brazierParams.color.Red = (int)StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, BRAZIER_COLOR_G);
        if (val != "") brazierParams.color.Green = (int)StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, BRAZIER_COLOR_B);
        if (val != "") brazierParams.color.Blue = (int)StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CANDELABRA_BRIGHTNESS);
        if (val != "") candelabraParams.brightness = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CANDELABRA_RADIUS);
        if (val != "") candelabraParams.radius = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CANDELABRA_ATTENUATION);
        if (val != "") candelabraParams.attenuation = StringToFloat(val);

        candelabraParams.shouldOverrideColour = gameConfig.GetVarValue(GENERAL_GROUP, OVERRIDE_CANDELABRA_COLOUR);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CANDELABRA_COLOR_R);
        if (val != "") candelabraParams.color.Red = (int)StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CANDELABRA_COLOR_G);
        if (val != "") candelabraParams.color.Green = (int)StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CANDELABRA_COLOR_B);
        if (val != "") candelabraParams.color.Blue = (int)StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CAMPFIRE_BRIGHTNESS);
        if (val != "") campfireParams.brightness = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CAMPFIRE_RADIUS);
        if (val != "") campfireParams.radius = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CAMPFIRE_ATTENUATION);
        if (val != "") campfireParams.attenuation = StringToFloat(val);

        campfireParams.shouldOverrideColour = gameConfig.GetVarValue(GENERAL_GROUP, OVERRIDE_CAMPFIRE_COLOUR);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CAMPFIRE_COLOR_R);
        if (val != "") campfireParams.color.Red = (int)StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CAMPFIRE_COLOR_G);
        if (val != "") campfireParams.color.Green = (int)StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, CAMPFIRE_COLOR_B);
        if (val != "") campfireParams.color.Blue = (int)StringToFloat(val);
    }

    // To be called for every option-change event.
    // Filters to this mod's groups before updating cached settings.
    public function OptionValueChanged(groupId : int, optionName : name, optionValue : string) {
        var wasEnabled : bool = isEnabled;

        if (IsMyModSettingsGroup(groupId)) {
            ReadGameConfig();

            if (optionName == OVERRIDE_CANDLE_COLOUR || optionName == OVERRIDE_TORCH_COLOUR || optionName == OVERRIDE_BRAZIER_COLOUR
                || optionName == OVERRIDE_CANDELABRA_COLOUR || optionName == OVERRIDE_CAMPFIRE_COLOUR) {
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

        SetOptionDisabledState(flashValueStorage, dataArray, 'CandleColorR', !candleParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, 'CandleColorG', !candleParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, 'CandleColorB', !candleParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, 'TorchColorR',   !torchParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, 'TorchColorG',   !torchParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, 'TorchColorB',   !torchParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, 'BrazierColorR', !brazierParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, 'BrazierColorG', !brazierParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, 'BrazierColorB', !brazierParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, 'CandelabraColorR', !candelabraParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, 'CandelabraColorG', !candelabraParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, 'CandelabraColorB', !candelabraParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, 'CampfireColorR', !campfireParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, 'CampfireColorG', !campfireParams.shouldOverrideColour);
        SetOptionDisabledState(flashValueStorage, dataArray, 'CampfireColorB', !campfireParams.shouldOverrideColour);

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
        var interimEntities : array<CEntity>;
        var i, count : int;
        var entity : CGameplayEntity;

        theGame.GetEntitiesByTag(candleParams.tag, interimEntities);
        count = interimEntities.Size();
        LogLightRewrite("Get nearby candles: Found " + count + " nearby entities");

        for (i = 0; i < count; i += 1) {
            entity = (CGameplayEntity)interimEntities[i];
            entity.IdentifyLightRewriteType();

            if (entity.IsLightRewritable()) {
                entities.PushBack(entity);
            }
        }
        interimEntities.Clear();

        theGame.GetEntitiesByTag(torchParams.tag, interimEntities);
        count = interimEntities.Size();
        LogLightRewrite("Get nearby torches: Found " + count + " nearby entities");

        for (i = 0; i < count; i += 1) {
            entity = (CGameplayEntity)interimEntities[i];
            entity.IdentifyLightRewriteType();

            if (entity.IsLightRewritable()) {
                entities.PushBack(entity);
            }
        }
        interimEntities.Clear();

        theGame.GetEntitiesByTag(brazierParams.tag, interimEntities);
        count = interimEntities.Size();
        LogLightRewrite("Get nearby braziers: Found " + count + " nearby entities");

        for (i = 0; i < count; i += 1) {
            entity = (CGameplayEntity)interimEntities[i];
            entity.IdentifyLightRewriteType();

            if (entity.IsLightRewritable()) {
                entities.PushBack(entity);
            }
        }
        interimEntities.Clear();

        theGame.GetEntitiesByTag(candelabraParams.tag, interimEntities);
        count = interimEntities.Size();
        LogLightRewrite("Get nearby candelabras: Found " + count + " nearby entities");

        for (i = 0; i < count; i += 1) {
            entity = (CGameplayEntity)interimEntities[i];
            entity.IdentifyLightRewriteType();

            if (entity.IsLightRewritable()) {
                entities.PushBack(entity);
            }
        }
        interimEntities.Clear();

        theGame.GetEntitiesByTag(campfireParams.tag, interimEntities);
        count = interimEntities.Size();
        LogLightRewrite("Get nearby campfires: Found " + count + " nearby entities");

        for (i = 0; i < count; i += 1) {
            entity = (CGameplayEntity)interimEntities[i];
            entity.IdentifyLightRewriteType();

            if (entity.IsLightRewritable()) {
                entities.PushBack(entity);
            }
        }
    }
}
