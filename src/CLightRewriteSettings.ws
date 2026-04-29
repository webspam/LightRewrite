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

    private const var SHADOW_FADE_DISTANCE : name;     default SHADOW_FADE_DISTANCE   = 'ShadowFadeDistance';
    private const var SHADOW_FADE_RANGE : name;        default SHADOW_FADE_RANGE      = 'ShadowFadeRange';
    private const var SHADOW_BLEND_FACTOR : name;      default SHADOW_BLEND_FACTOR    = 'ShadowBlendFactor';

    private const var CANDLE_BRIGHTNESS : name;        default CANDLE_BRIGHTNESS      = 'CandleBrightness';
    private const var CANDLE_RADIUS : name;            default CANDLE_RADIUS          = 'CandleRadius';
    private const var CANDLE_ATTENUATION : name;       default CANDLE_ATTENUATION     = 'CandleAttenuation';
    private const var CANDLE_SHADOW_DISTANCE : name;   default CANDLE_SHADOW_DISTANCE = 'CandleShadowFadeDistance';
    private const var CANDLE_SHADOW_RANGE : name;      default CANDLE_SHADOW_RANGE = 'CandleShadowFadeRange';
    private const var CANDLE_SHADOW_BLEND : name;      default CANDLE_SHADOW_BLEND = 'CandleShadowBlendFactor';
    private const var OVERRIDE_CANDLE_COLOUR : name;   default OVERRIDE_CANDLE_COLOUR = 'OverrideCandleColour';
    private const var CANDLE_COLOR_R : name;           default CANDLE_COLOR_R         = 'CandleColorR';
    private const var CANDLE_COLOR_G : name;           default CANDLE_COLOR_G         = 'CandleColorG';
    private const var CANDLE_COLOR_B : name;           default CANDLE_COLOR_B         = 'CandleColorB';

    private const var TORCH_BRIGHTNESS : name;         default TORCH_BRIGHTNESS       = 'TorchBrightness';
    private const var TORCH_RADIUS : name;             default TORCH_RADIUS           = 'TorchRadius';
    private const var TORCH_ATTENUATION : name;        default TORCH_ATTENUATION      = 'TorchAttenuation';
    private const var TORCH_SHADOW_DISTANCE : name;    default TORCH_SHADOW_DISTANCE = 'TorchShadowFadeDistance';
    private const var TORCH_SHADOW_RANGE : name;       default TORCH_SHADOW_RANGE = 'TorchShadowFadeRange';
    private const var TORCH_SHADOW_BLEND : name;       default TORCH_SHADOW_BLEND = 'TorchShadowBlendFactor';
    private const var OVERRIDE_TORCH_COLOUR : name;    default OVERRIDE_TORCH_COLOUR  = 'OverrideTorchColour';
    private const var TORCH_COLOR_R : name;            default TORCH_COLOR_R          = 'TorchColorR';
    private const var TORCH_COLOR_G : name;            default TORCH_COLOR_G          = 'TorchColorG';
    private const var TORCH_COLOR_B : name;            default TORCH_COLOR_B          = 'TorchColorB';

    private const var BRAZIER_BRIGHTNESS : name;       default BRAZIER_BRIGHTNESS     = 'BrazierBrightness';
    private const var BRAZIER_RADIUS : name;           default BRAZIER_RADIUS         = 'BrazierRadius';
    private const var BRAZIER_ATTENUATION : name;      default BRAZIER_ATTENUATION    = 'BrazierAttenuation';
    private const var BRAZIER_SHADOW_DISTANCE : name;  default BRAZIER_SHADOW_DISTANCE = 'BrazierShadowFadeDistance';
    private const var BRAZIER_SHADOW_RANGE : name;     default BRAZIER_SHADOW_RANGE = 'BrazierShadowFadeRange';
    private const var BRAZIER_SHADOW_BLEND : name;     default BRAZIER_SHADOW_BLEND = 'BrazierShadowBlendFactor';
    private const var OVERRIDE_BRAZIER_COLOUR : name;  default OVERRIDE_BRAZIER_COLOUR = 'OverrideBrazierColour';
    private const var BRAZIER_COLOR_R : name;          default BRAZIER_COLOR_R        = 'BrazierColorR';
    private const var BRAZIER_COLOR_G : name;          default BRAZIER_COLOR_G        = 'BrazierColorG';
    private const var BRAZIER_COLOR_B : name;          default BRAZIER_COLOR_B        = 'BrazierColorB';

    private const var CANDELABRA_BRIGHTNESS : name;    default CANDELABRA_BRIGHTNESS  = 'CandelabraBrightness';
    private const var CANDELABRA_RADIUS : name;        default CANDELABRA_RADIUS      = 'CandelabraRadius';
    private const var CANDELABRA_ATTENUATION : name;   default CANDELABRA_ATTENUATION = 'CandelabraAttenuation';
    private const var CANDELABRA_SHADOW_DISTANCE : name; default CANDELABRA_SHADOW_DISTANCE = 'CandelabraShadowFadeDistance';
    private const var CANDELABRA_SHADOW_RANGE : name;  default CANDELABRA_SHADOW_RANGE = 'CandelabraShadowFadeRange';
    private const var CANDELABRA_SHADOW_BLEND : name;  default CANDELABRA_SHADOW_BLEND = 'CandelabraShadowBlendFactor';
    private const var OVERRIDE_CANDELABRA_COLOUR : name; default OVERRIDE_CANDELABRA_COLOUR = 'OverrideCandelabraColour';
    private const var CANDELABRA_COLOR_R : name;       default CANDELABRA_COLOR_R     = 'CandelabraColorR';
    private const var CANDELABRA_COLOR_G : name;       default CANDELABRA_COLOR_G     = 'CandelabraColorG';
    private const var CANDELABRA_COLOR_B : name;       default CANDELABRA_COLOR_B     = 'CandelabraColorB';

    private const var CAMPFIRE_BRIGHTNESS : name;      default CAMPFIRE_BRIGHTNESS    = 'CampfireBrightness';
    private const var CAMPFIRE_RADIUS : name;          default CAMPFIRE_RADIUS        = 'CampfireRadius';
    private const var CAMPFIRE_ATTENUATION : name;     default CAMPFIRE_ATTENUATION   = 'CampfireAttenuation';
    private const var CAMPFIRE_SHADOW_DISTANCE : name; default CAMPFIRE_SHADOW_DISTANCE = 'CampfireShadowFadeDistance';
    private const var CAMPFIRE_SHADOW_RANGE : name;    default CAMPFIRE_SHADOW_RANGE = 'CampfireShadowFadeRange';
    private const var CAMPFIRE_SHADOW_BLEND : name;    default CAMPFIRE_SHADOW_BLEND = 'CampfireShadowBlendFactor';
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
        candleParams.shadowFadeDistance = 10.f;
        candleParams.shadowFadeRange = 3.f;
        candleParams.shadowBlendFactor = 1.f;
        candleParams.shouldOverrideColour = false;
        candleParams.color.Red = 240;
        candleParams.color.Green = 245;
        candleParams.color.Blue = 255;

        torchParams.useSpotlightColor = false;
        torchParams.brightness = 30.f;
        torchParams.radius = 20.f;
        torchParams.attenuation = 1.0f;
        torchParams.shadowFadeDistance = 10.f;
        torchParams.shadowFadeRange = 3.f;
        torchParams.shadowBlendFactor = 1.f;
        torchParams.shouldOverrideColour = false;
        torchParams.color.Red = 255;
        torchParams.color.Green = 255;
        torchParams.color.Blue = 255;

        brazierParams.useSpotlightColor = false;
        brazierParams.brightness = 40.f;
        brazierParams.radius = 25.f;
        brazierParams.attenuation = 1.0f;
        brazierParams.shadowFadeDistance = 35.f;
        brazierParams.shadowFadeRange = 10.f;
        brazierParams.shadowBlendFactor = 1.f;
        brazierParams.shouldOverrideColour = false;
        brazierParams.color.Red = 255;
        brazierParams.color.Green = 255;
        brazierParams.color.Blue = 255;

        candelabraParams.useSpotlightColor = true;
        candelabraParams.brightness = 8.0f;
        candelabraParams.radius = 12.f;
        candelabraParams.attenuation = 1.0f;
        candelabraParams.shadowFadeDistance = 10.f;
        candelabraParams.shadowFadeRange = 3.f;
        candelabraParams.shadowBlendFactor = 1.f;
        candelabraParams.shouldOverrideColour = false;
        candelabraParams.color.Red = 255;
        candelabraParams.color.Green = 255;
        candelabraParams.color.Blue = 255;

        campfireParams.useSpotlightColor = false;
        campfireParams.brightness = 50.f;
        campfireParams.radius = 30.f;
        campfireParams.attenuation = 1.0f;
        campfireParams.shadowFadeDistance = 10.f;
        campfireParams.shadowFadeRange = 3.f;
        campfireParams.shadowBlendFactor = 1.f;
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
        var oldAttenuation : string;
        var oldShadowFadeDistance : string;
        var oldShadowFadeRange : string;
        var oldShadowBlendFactor : string;
        var initVersion : int = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, INIT_VERSION), 0);

        if (initVersion == CONFIG_VERSION) return;

        // Never initialised - write the v1 defaults, then apply the same migrations below.
        if (initVersion == 0) {
            gameConfig.SetVarValue(GENERAL_GROUP, ENABLED, isEnabled);
            gameConfig.SetVarValue(GENERAL_GROUP, SHADOW_FADE_DISTANCE, 10.f);
            gameConfig.SetVarValue(GENERAL_GROUP, SHADOW_FADE_RANGE, 3.f);
            gameConfig.SetVarValue(GENERAL_GROUP, SHADOW_BLEND_FACTOR, 1.f);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_BRIGHTNESS, candleParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_RADIUS, candleParams.radius);
            gameConfig.SetVarValue(GENERAL_GROUP, TORCH_BRIGHTNESS, torchParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, TORCH_RADIUS, torchParams.radius);
        }

        // v1 → v2: promote the old global attenuation value to both per-source keys.
        if (initVersion <= 1) {
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
        if (initVersion <= 2) {
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
        if (initVersion <= 3) {
            gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_BRIGHTNESS, brazierParams.brightness);
            gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_RADIUS, brazierParams.radius);
            gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_ATTENUATION, brazierParams.attenuation);
            gameConfig.SetVarValue(GENERAL_GROUP, OVERRIDE_BRAZIER_COLOUR, brazierParams.shouldOverrideColour);
            gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_COLOR_R, brazierParams.color.Red);
            gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_COLOR_G, brazierParams.color.Green);
            gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_COLOR_B, brazierParams.color.Blue);
        }

        // v4 → v5: add candelabra and campfire light source settings.
        if (initVersion <= 4) {
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

        // v5 → v6: promote global shadow settings to per-source keys.
        if (initVersion <= 5) {
            oldShadowFadeDistance = gameConfig.GetVarValue(GENERAL_GROUP, SHADOW_FADE_DISTANCE);
            oldShadowFadeRange = gameConfig.GetVarValue(GENERAL_GROUP, SHADOW_FADE_RANGE);
            oldShadowBlendFactor = gameConfig.GetVarValue(GENERAL_GROUP, SHADOW_BLEND_FACTOR);

            if (StringToFloat(oldShadowFadeDistance, -1.f) != -1.f) {
                gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_SHADOW_DISTANCE, oldShadowFadeDistance);
                gameConfig.SetVarValue(GENERAL_GROUP, TORCH_SHADOW_DISTANCE, oldShadowFadeDistance);
                gameConfig.SetVarValue(GENERAL_GROUP, CANDELABRA_SHADOW_DISTANCE, oldShadowFadeDistance);
                gameConfig.SetVarValue(GENERAL_GROUP, CAMPFIRE_SHADOW_DISTANCE, oldShadowFadeDistance);
            } else {
                gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_SHADOW_DISTANCE, candleParams.shadowFadeDistance);
                gameConfig.SetVarValue(GENERAL_GROUP, TORCH_SHADOW_DISTANCE, torchParams.shadowFadeDistance);
                gameConfig.SetVarValue(GENERAL_GROUP, CANDELABRA_SHADOW_DISTANCE, candelabraParams.shadowFadeDistance);
                gameConfig.SetVarValue(GENERAL_GROUP, CAMPFIRE_SHADOW_DISTANCE, campfireParams.shadowFadeDistance);
            }
            gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_SHADOW_DISTANCE, brazierParams.shadowFadeDistance);

            if (StringToFloat(oldShadowFadeRange, -1.f) != -1.f) {
                gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_SHADOW_RANGE, oldShadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, TORCH_SHADOW_RANGE, oldShadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_SHADOW_RANGE, oldShadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, CANDELABRA_SHADOW_RANGE, oldShadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, CAMPFIRE_SHADOW_RANGE, oldShadowFadeRange);
            } else {
                gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_SHADOW_RANGE, candleParams.shadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, TORCH_SHADOW_RANGE, torchParams.shadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_SHADOW_RANGE, brazierParams.shadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, CANDELABRA_SHADOW_RANGE, candelabraParams.shadowFadeRange);
                gameConfig.SetVarValue(GENERAL_GROUP, CAMPFIRE_SHADOW_RANGE, campfireParams.shadowFadeRange);
            }

            if (StringToFloat(oldShadowBlendFactor, -1.f) != -1.f) {
                gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_SHADOW_BLEND, oldShadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, TORCH_SHADOW_BLEND, oldShadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_SHADOW_BLEND, oldShadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, CANDELABRA_SHADOW_BLEND, oldShadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, CAMPFIRE_SHADOW_BLEND, oldShadowBlendFactor);
            } else {
                gameConfig.SetVarValue(GENERAL_GROUP, CANDLE_SHADOW_BLEND, candleParams.shadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, TORCH_SHADOW_BLEND, torchParams.shadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, BRAZIER_SHADOW_BLEND, brazierParams.shadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, CANDELABRA_SHADOW_BLEND, candelabraParams.shadowBlendFactor);
                gameConfig.SetVarValue(GENERAL_GROUP, CAMPFIRE_SHADOW_BLEND, campfireParams.shadowBlendFactor);
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

        candleParams.brightness = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, CANDLE_BRIGHTNESS), candleParams.brightness);
        candleParams.radius = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, CANDLE_RADIUS), candleParams.radius);
        candleParams.attenuation = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, CANDLE_ATTENUATION), candleParams.attenuation);
        candleParams.shadowFadeDistance = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, CANDLE_SHADOW_DISTANCE), candleParams.shadowFadeDistance);
        candleParams.shadowFadeRange = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, CANDLE_SHADOW_RANGE), candleParams.shadowFadeRange);
        candleParams.shadowBlendFactor = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, CANDLE_SHADOW_BLEND), candleParams.shadowBlendFactor);
        candleParams.shouldOverrideColour = gameConfig.GetVarValue(GENERAL_GROUP, OVERRIDE_CANDLE_COLOUR);
        candleParams.color.Red = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, CANDLE_COLOR_R), candleParams.color.Red);
        candleParams.color.Green = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, CANDLE_COLOR_G), candleParams.color.Green);
        candleParams.color.Blue = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, CANDLE_COLOR_B), candleParams.color.Blue);

        torchParams.brightness = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, TORCH_BRIGHTNESS), torchParams.brightness);
        torchParams.radius = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, TORCH_RADIUS), torchParams.radius);
        torchParams.attenuation = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, TORCH_ATTENUATION), torchParams.attenuation);
        torchParams.shadowFadeDistance = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, TORCH_SHADOW_DISTANCE), torchParams.shadowFadeDistance);
        torchParams.shadowFadeRange = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, TORCH_SHADOW_RANGE), torchParams.shadowFadeRange);
        torchParams.shadowBlendFactor = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, TORCH_SHADOW_BLEND), torchParams.shadowBlendFactor);
        torchParams.shouldOverrideColour = gameConfig.GetVarValue(GENERAL_GROUP, OVERRIDE_TORCH_COLOUR);
        torchParams.color.Red = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, TORCH_COLOR_R), torchParams.color.Red);
        torchParams.color.Green = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, TORCH_COLOR_G), torchParams.color.Green);
        torchParams.color.Blue = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, TORCH_COLOR_B), torchParams.color.Blue);

        brazierParams.brightness = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, BRAZIER_BRIGHTNESS), brazierParams.brightness);
        brazierParams.radius = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, BRAZIER_RADIUS), brazierParams.radius);
        brazierParams.attenuation = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, BRAZIER_ATTENUATION), brazierParams.attenuation);
        brazierParams.shadowFadeDistance = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, BRAZIER_SHADOW_DISTANCE), brazierParams.shadowFadeDistance);
        brazierParams.shadowFadeRange = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, BRAZIER_SHADOW_RANGE), brazierParams.shadowFadeRange);
        brazierParams.shadowBlendFactor = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, BRAZIER_SHADOW_BLEND), brazierParams.shadowBlendFactor);
        brazierParams.shouldOverrideColour = gameConfig.GetVarValue(GENERAL_GROUP, OVERRIDE_BRAZIER_COLOUR);
        brazierParams.color.Red = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, BRAZIER_COLOR_R), brazierParams.color.Red);
        brazierParams.color.Green = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, BRAZIER_COLOR_G), brazierParams.color.Green);
        brazierParams.color.Blue = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, BRAZIER_COLOR_B), brazierParams.color.Blue);

        candelabraParams.brightness = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, CANDELABRA_BRIGHTNESS), candelabraParams.brightness);
        candelabraParams.radius = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, CANDELABRA_RADIUS), candelabraParams.radius);
        candelabraParams.attenuation = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, CANDELABRA_ATTENUATION), candelabraParams.attenuation);
        candelabraParams.shadowFadeDistance = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, CANDELABRA_SHADOW_DISTANCE), candelabraParams.shadowFadeDistance);
        candelabraParams.shadowFadeRange = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, CANDELABRA_SHADOW_RANGE), candelabraParams.shadowFadeRange);
        candelabraParams.shadowBlendFactor = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, CANDELABRA_SHADOW_BLEND), candelabraParams.shadowBlendFactor);
        candelabraParams.shouldOverrideColour = gameConfig.GetVarValue(GENERAL_GROUP, OVERRIDE_CANDELABRA_COLOUR);
        candelabraParams.color.Red = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, CANDELABRA_COLOR_R), candelabraParams.color.Red);
        candelabraParams.color.Green = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, CANDELABRA_COLOR_G), candelabraParams.color.Green);
        candelabraParams.color.Blue = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, CANDELABRA_COLOR_B), candelabraParams.color.Blue);

        campfireParams.brightness = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, CAMPFIRE_BRIGHTNESS), campfireParams.brightness);
        campfireParams.radius = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, CAMPFIRE_RADIUS), campfireParams.radius);
        campfireParams.attenuation = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, CAMPFIRE_ATTENUATION), campfireParams.attenuation);
        campfireParams.shadowFadeDistance = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, CAMPFIRE_SHADOW_DISTANCE), campfireParams.shadowFadeDistance);
        campfireParams.shadowFadeRange = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, CAMPFIRE_SHADOW_RANGE), campfireParams.shadowFadeRange);
        campfireParams.shadowBlendFactor = StringToFloat(gameConfig.GetVarValue(GENERAL_GROUP, CAMPFIRE_SHADOW_BLEND), campfireParams.shadowBlendFactor);
        campfireParams.shouldOverrideColour = gameConfig.GetVarValue(GENERAL_GROUP, OVERRIDE_CAMPFIRE_COLOUR);
        campfireParams.color.Red = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, CAMPFIRE_COLOR_R), campfireParams.color.Red);
        campfireParams.color.Green = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, CAMPFIRE_COLOR_G), campfireParams.color.Green);
        campfireParams.color.Blue = StringToInt(gameConfig.GetVarValue(GENERAL_GROUP, CAMPFIRE_COLOR_B), campfireParams.color.Blue);
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
