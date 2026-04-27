/*
 * Reads LightRewrite settings from the in-game mod menu and writes them
 * directly into theGame.params so all other mod code can read them without
 * knowing about this class.
 *
 * Stored as a singleton on CR4Game via GetLightRewriteSettings() (watchSettings.ws).
 */

class CLightRewriteSettings {
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
        gameConfig      = theGame.GetInGameConfigWrapper();
        generalGroupId  = gameConfig.GetGroupIdx(GENERAL_GROUP);
        candleGroupId = gameConfig.GetGroupIdx(CANDLE_GROUP);
        torchGroupId = gameConfig.GetGroupIdx(TORCH_GROUP);
    }

    // Returns true if groupId belongs to one of this mod's settings groups.
    // Used to filter out option-change events fired by other mods.
    public function IsMyModSettingsGroup(groupId : int) : bool {
        return groupId == generalGroupId || groupId == candleGroupId || groupId == torchGroupId;
    }

    // Delegates to W3GameParams.ReadLightRewriteConfig(), which can write to
    // its own fields directly. Called on player spawn and on option-change events.
    public function ReadGameConfig() {
        var val : string;
        var params : W3GameParams = theGame.params;

        params.LR_ENABLED = gameConfig.GetVarValue(GENERAL_GROUP, ENABLED);
        if (!params.LR_ENABLED) return;

        val = gameConfig.GetVarValue(CANDLE_GROUP, BRIGHTNESS);
        if (val != "") params.LR_CANDLE_BRIGHTNESS = StringToFloat(val);

        val = gameConfig.GetVarValue(CANDLE_GROUP, RADIUS);
        if (val != "") params.LR_CANDLE_RADIUS = StringToFloat(val);

        val = gameConfig.GetVarValue(TORCH_GROUP, BRIGHTNESS);
        if (val != "") params.LR_TORCH_BRIGHTNESS = StringToFloat(val);

        val = gameConfig.GetVarValue(TORCH_GROUP, RADIUS);
        if (val != "") params.LR_TORCH_RADIUS = StringToFloat(val);

        val = gameConfig.GetVarValue(GENERAL_GROUP, ATTENUATION);
        if (val != "") params.LR_ATTENUATION = StringToFloat(val);

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
        if (IsMyModSettingsGroup(groupId)) {
            ReadGameConfig();
        }
    }
}
