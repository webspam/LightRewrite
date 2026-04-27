/*
 * Reads LightRewrite settings from the in-game mod menu and writes them
 * directly into theGame.params so all other mod code can read them without
 * knowing about this class.
 *
 * Stored as a singleton on CR4Game via GetLightRewriteSettings() (watchSettings.ws).
 */

class CLightRewriteSettings {
    // The current XML config version
    private const var CONFIG_VERSION : string;         default CONFIG_VERSION = "2";
    
    // Group name constants (must match XML Group id values)
    private const var GENERAL_GROUP : name;            default GENERAL_GROUP = 'LightRewrite_General';
    private const var CANDLE_GROUP : name;             default CANDLE_GROUP  = 'LightRewrite_Candle';
    private const var TORCH_GROUP : name;              default TORCH_GROUP   = 'LightRewrite_Torch';

    // Setting name constants (must match XML Var id values)
    private const var ENABLED : name;                  default ENABLED              = 'Enabled';
    private const var ATTENUATION : name;              default ATTENUATION          = 'Attenuation';
    private const var SHADOW_FADE_DISTANCE : name;     default SHADOW_FADE_DISTANCE = 'ShadowFadeDistance';
    private const var SHADOW_FADE_RANGE : name;        default SHADOW_FADE_RANGE    = 'ShadowFadeRange';
    private const var SHADOW_BLEND_FACTOR : name;      default SHADOW_BLEND_FACTOR  = 'ShadowBlendFactor';
    private const var BRIGHTNESS : name;               default BRIGHTNESS           = 'Brightness';
    private const var RADIUS : name;                   default RADIUS               = 'Radius';
    private const var INIT_VERSION : name;             default INIT_VERSION         = 'InitVersion';

    // Internal group IDs resolved at init time
    private var generalGroupId  : int;
    private var candleGroupId : int;
    private var torchGroupId : int;

    private var gameConfig : CInGameConfigWrapper;

    // Resolve group IDs from the config wrapper; called once at singleton creation.
    public function Init() {
        var params : W3GameParams = theGame.params;
        
        gameConfig      = theGame.GetInGameConfigWrapper();
        generalGroupId  = gameConfig.GetGroupIdx(GENERAL_GROUP);
        candleGroupId = gameConfig.GetGroupIdx(CANDLE_GROUP);
        torchGroupId = gameConfig.GetGroupIdx(TORCH_GROUP);

        params.LR_ENABLED               = true;
        params.LR_CANDLE_BRIGHTNESS     = 5.5f;
        params.LR_CANDLE_RADIUS         = 9.f;
        params.LR_TORCH_BRIGHTNESS      = 30.f;
        params.LR_TORCH_RADIUS          = 20.f;
        params.LR_CANDLE_ATTENUATION    = 1.0f;
        params.LR_TORCH_ATTENUATION     = 1.0f;
        params.LR_SHADOW_FADE_DISTANCE  = 10.f;
        params.LR_SHADOW_FADE_RANGE     = 3.f;
        params.LR_SHADOW_BLEND_FACTOR   = 1.f;

        params.LR_CANDLE_TAG            = 'LR_Candle';
        params.LR_TORCH_TAG             = 'LR_Torch';
    }

    // Returns true if groupId belongs to one of this mod's settings groups.
    // Used to filter out option-change events fired by other mods.
    public function IsMyModSettingsGroup(groupId : int) : bool {
        return groupId == generalGroupId || groupId == candleGroupId || groupId == torchGroupId;
    }

    // If mod config has never been initialised, set the default values and save them.
    // Handles migration from older versions by writing any keys added since the stored version.
    public function EnsureGameConfigIsInitialised() {
        var initVersion : string = gameConfig.GetVarValue(GENERAL_GROUP, INIT_VERSION);
        var oldAttenuation : string;

        if (initVersion == CONFIG_VERSION) return;

        // v1 → v2: promote the old global attenuation value to both per-source keys.
        if (initVersion == "1") {
            oldAttenuation = gameConfig.GetVarValue(GENERAL_GROUP, ATTENUATION);

            if (StringToFloat(oldAttenuation, -1.f) != -1.f) {
                gameConfig.SetVarValue(CANDLE_GROUP, ATTENUATION, oldAttenuation);
                gameConfig.SetVarValue(TORCH_GROUP, ATTENUATION, oldAttenuation);
            } else {
                gameConfig.SetVarValue(CANDLE_GROUP, ATTENUATION, theGame.params.LR_CANDLE_ATTENUATION);
                gameConfig.SetVarValue(TORCH_GROUP, ATTENUATION, theGame.params.LR_TORCH_ATTENUATION);
            }
        }
        // Never initialised - write all defaults.
        else if (!initVersion) {
            gameConfig.SetVarValue(GENERAL_GROUP, ENABLED, theGame.params.LR_ENABLED);
            gameConfig.SetVarValue(GENERAL_GROUP, SHADOW_FADE_DISTANCE, theGame.params.LR_SHADOW_FADE_DISTANCE);
            gameConfig.SetVarValue(GENERAL_GROUP, SHADOW_FADE_RANGE, theGame.params.LR_SHADOW_FADE_RANGE);
            gameConfig.SetVarValue(GENERAL_GROUP, SHADOW_BLEND_FACTOR, theGame.params.LR_SHADOW_BLEND_FACTOR);
            gameConfig.SetVarValue(CANDLE_GROUP, BRIGHTNESS, theGame.params.LR_CANDLE_BRIGHTNESS);
            gameConfig.SetVarValue(CANDLE_GROUP, RADIUS, theGame.params.LR_CANDLE_RADIUS);
            gameConfig.SetVarValue(CANDLE_GROUP, ATTENUATION, theGame.params.LR_CANDLE_ATTENUATION);
            gameConfig.SetVarValue(TORCH_GROUP, BRIGHTNESS, theGame.params.LR_TORCH_BRIGHTNESS);
            gameConfig.SetVarValue(TORCH_GROUP, RADIUS, theGame.params.LR_TORCH_RADIUS);
            gameConfig.SetVarValue(TORCH_GROUP, ATTENUATION, theGame.params.LR_TORCH_ATTENUATION);
        }

        gameConfig.SetVarValue(GENERAL_GROUP, INIT_VERSION, CONFIG_VERSION);
        theGame.SaveUserSettings();
    }

    // Delegates to W3GameParams.ReadLightRewriteConfig(), which can write to
    // its own fields directly. Called on player spawn and on option-change events.
    public function ReadGameConfig() {
        var val : string;
        var params : W3GameParams = theGame.params;

        EnsureGameConfigIsInitialised();

        params.LR_ENABLED = gameConfig.GetVarValue(GENERAL_GROUP, ENABLED);
        if (!params.LR_ENABLED) return;

        val = gameConfig.GetVarValue(CANDLE_GROUP, BRIGHTNESS);
        if (val != "") params.LR_CANDLE_BRIGHTNESS = StringToFloat(val);

        val = gameConfig.GetVarValue(CANDLE_GROUP, RADIUS);
        if (val != "") params.LR_CANDLE_RADIUS = StringToFloat(val);

        val = gameConfig.GetVarValue(CANDLE_GROUP, ATTENUATION);
        if (val != "") params.LR_CANDLE_ATTENUATION = StringToFloat(val);

        val = gameConfig.GetVarValue(TORCH_GROUP, BRIGHTNESS);
        if (val != "") params.LR_TORCH_BRIGHTNESS = StringToFloat(val);

        val = gameConfig.GetVarValue(TORCH_GROUP, RADIUS);
        if (val != "") params.LR_TORCH_RADIUS = StringToFloat(val);

        val = gameConfig.GetVarValue(TORCH_GROUP, ATTENUATION);
        if (val != "") params.LR_TORCH_ATTENUATION = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, SHADOW_FADE_DISTANCE);
        if (val != "") params.LR_SHADOW_FADE_DISTANCE = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, SHADOW_FADE_RANGE);
        if (val != "") params.LR_SHADOW_FADE_RANGE = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, SHADOW_BLEND_FACTOR);
        if (val != "") params.LR_SHADOW_BLEND_FACTOR = StringToFloat(val);
    }

    // Called by the CR4IngameMenu wrapper for every option-change event.
    // Filters to this mod's groups before refreshing the params cache.
    public function OptionValueChanged(groupId : int, optionName : name, optionValue : string) {
        var isEnabled : bool = theGame.params.LR_ENABLED;

        if (IsMyModSettingsGroup(groupId)) {
            ReadGameConfig();

            // If we've just turned the mod off, disable all nearby entities.
            if (isEnabled != theGame.params.LR_ENABLED && !theGame.params.LR_ENABLED) {
                DisableAllNearbyEntities();
            }

            // Otherwise, if we changed any setting AND the mod is enabled, run the light rewrite.
            else if (theGame.params.LR_ENABLED) {
                EnableAllNearbyEntities();
            }
        }
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

        FindGameplayEntitiesInRange(interimEntities, thePlayer, 1000.f, 1024, theGame.params.LR_CANDLE_TAG);
        LogLightRewrite("Get nearby candles: Found " + interimEntities.Size() + " nearby entities");

        for (i = 0; i < interimEntities.Size(); i += 1) {
            entity = interimEntities[i];
            entity.IdentifyLightRewriteType();

            if (entity.IsLightRewritable()) {
                entities.PushBack(entity);
            }
        }

        FindGameplayEntitiesInRange(interimEntities, thePlayer, 1000.f, 1024, theGame.params.LR_TORCH_TAG);
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
