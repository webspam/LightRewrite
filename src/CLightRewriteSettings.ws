/*
 * Reads LightRewrite settings from the in-game mod menu and writes them
 * directly into theGame.params so all other mod code can read them without
 * knowing about this class.
 *
 * Stored as a singleton on CR4Game via GetLightRewriteSettings() (watchSettings.ws).
 */
class CLightRewriteSettings {
    // Group name constants (must match XML Group id values)
    private const var GENERAL_GROUP  : name; default GENERAL_GROUP  = 'LightRewrite_General';
    private const var LIGHTING_GROUP : name; default LIGHTING_GROUP = 'LightRewrite_Lighting';

    // Internal group IDs resolved at init time
    private var generalGroupId  : int;
    private var lightingGroupId : int;

    private var gameConfig : CInGameConfigWrapper;

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

    // Reads current values from the game config and writes them to theGame.params.
    // Called on player spawn (startup read) and on every relevant option-change event.
    // Guards against empty strings returned before the user has opened the mod menu,
    // so the W3GameParams defaults are preserved on the first load.
    public function ReadGameConfig() {
        var val : string;

        theGame.params.LR_ENABLED = gameConfig.GetVarValue(GENERAL_GROUP, 'Enabled');
        if (!theGame.params.LR_ENABLED) { return; }

        val = gameConfig.GetVarValue(LIGHTING_GROUP, 'CandleBrightness');
        if (val != "") { theGame.params.LR_CANDLE_BRIGHTNESS = StringToFloat(val); }

        val = gameConfig.GetVarValue(LIGHTING_GROUP, 'CandleRadius');
        if (val != "") { theGame.params.LR_CANDLE_RADIUS = StringToFloat(val); }

        val = gameConfig.GetVarValue(LIGHTING_GROUP, 'TorchBrightness');
        if (val != "") { theGame.params.LR_TORCH_BRIGHTNESS = StringToFloat(val); }

        val = gameConfig.GetVarValue(LIGHTING_GROUP, 'TorchRadius');
        if (val != "") { theGame.params.LR_TORCH_RADIUS = StringToFloat(val); }

        val = gameConfig.GetVarValue(LIGHTING_GROUP, 'Attenuation');
        if (val != "") { theGame.params.LR_ATTENUATION = StringToFloat(val); }

        val = gameConfig.GetVarValue(LIGHTING_GROUP, 'ShadowFadeDistance');
        if (val != "") { theGame.params.LR_SHADOW_FADE_DISTANCE = StringToFloat(val); }

        val = gameConfig.GetVarValue(LIGHTING_GROUP, 'ShadowFadeRange');
        if (val != "") { theGame.params.LR_SHADOW_FADE_RANGE = StringToFloat(val); }

        val = gameConfig.GetVarValue(LIGHTING_GROUP, 'ShadowBlendFactor');
        if (val != "") { theGame.params.LR_SHADOW_BLEND_FACTOR = StringToFloat(val); }
    }

    // Called by the CR4IngameMenu wrapper for every option-change event.
    // Filters to this mod's groups before refreshing the params cache.
    public function OptionValueChanged(groupId : int, optionName : name, optionValue : string) {
        if (IsMyModSettingsGroup(groupId)) {
            ReadGameConfig();
        }
    }
}
