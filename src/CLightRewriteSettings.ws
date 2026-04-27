/*
 * Reads LightRewrite settings from the in-game mod menu and writes them
 * directly into theGame.params so all other mod code can read them without
 * knowing about this class.
 *
 * Stored as a singleton on CR4Game via GetLightRewriteSettings() (watchSettings.ws).
 */

// Reads all LightRewrite settings from the game config and stores them on
// this W3GameParams instance.
// W3GameParams fields can only be written from within a method on the class itself.
@addMethod(W3GameParams)
public function ReadLightRewriteConfig() {
    var val : string;
    var gameConfig : CInGameConfigWrapper = theGame.GetInGameConfigWrapper();

    LR_ENABLED = gameConfig.GetVarValue('LightRewrite_General', 'Enabled');
    if (!LR_ENABLED) return;

    val = gameConfig.GetVarValue('LightRewrite_Lighting', 'CandleBrightness');
    if (val != "") LR_CANDLE_BRIGHTNESS = StringToFloat(val);

    val = gameConfig.GetVarValue('LightRewrite_Lighting', 'CandleRadius');
    if (val != "") LR_CANDLE_RADIUS = StringToFloat(val);

    val = gameConfig.GetVarValue('LightRewrite_Lighting', 'TorchBrightness');
    if (val != "") LR_TORCH_BRIGHTNESS = StringToFloat(val);

    val = gameConfig.GetVarValue('LightRewrite_Lighting', 'TorchRadius');
    if (val != "") LR_TORCH_RADIUS = StringToFloat(val);

    val = gameConfig.GetVarValue('LightRewrite_Lighting', 'Attenuation');
    if (val != "") LR_ATTENUATION = StringToFloat(val);

    val = gameConfig.GetVarValue('LightRewrite_Lighting', 'ShadowFadeDistance');
    if (val != "") LR_SHADOW_FADE_DISTANCE = StringToFloat(val);

    val = gameConfig.GetVarValue('LightRewrite_Lighting', 'ShadowFadeRange');
    if (val != "") LR_SHADOW_FADE_RANGE = StringToFloat(val);

    val = gameConfig.GetVarValue('LightRewrite_Lighting', 'ShadowBlendFactor');
    if (val != "") LR_SHADOW_BLEND_FACTOR = StringToFloat(val);
}

class CLightRewriteSettings {
    // Group name constants (must match XML Group id values)
    private const var GENERAL_GROUP  : name; default GENERAL_GROUP  = 'LightRewrite_General';
    private const var LIGHTING_GROUP : name; default LIGHTING_GROUP = 'LightRewrite_Lighting';

    // Internal group IDs resolved at init time
    private var generalGroupId  : int;
    private var lightingGroupId : int;

    private var gameConfig : CInGameConfigWrapper;

    // Resolve group IDs from the config wrapper; called once at singleton creation.
    public function Init() {
        gameConfig      = theGame.GetInGameConfigWrapper();
        generalGroupId  = gameConfig.GetGroupIdx(GENERAL_GROUP);
        lightingGroupId = gameConfig.GetGroupIdx(LIGHTING_GROUP);
    }

    // Returns true if groupId belongs to one of this mod's settings groups.
    // Used to filter out option-change events fired by other mods.
    public function IsMyModSettingsGroup(groupId : int) : bool {
        return groupId == generalGroupId || groupId == lightingGroupId;
    }

    // Delegates to W3GameParams.ReadLightRewriteConfig(), which can write to
    // its own fields directly. Called on player spawn and on option-change events.
    public function ReadGameConfig() {
        theGame.params.ReadLightRewriteConfig();
    }

    // Called by the CR4IngameMenu wrapper for every option-change event.
    // Filters to this mod's groups before refreshing the params cache.
    public function OptionValueChanged(groupId : int, optionName : name, optionValue : string) {
        if (IsMyModSettingsGroup(groupId)) {
            ReadGameConfig();
        }
    }
}
