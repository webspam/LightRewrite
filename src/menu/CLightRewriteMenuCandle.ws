class CLightRewriteMenuCandle extends CLightRewriteSourceMenu {
    default TAG_ENABLED = 'CandleEnabled';
    default TAG_BRIGHTNESS = 'CandleBrightness';
    default TAG_RADIUS = 'CandleRadius';
    default TAG_ATTENUATION = 'CandleAttenuation';
    default TAG_SHADOW_DISTANCE = 'CandleShadowFadeDistance';
    default TAG_SHADOW_RANGE = 'CandleShadowFadeRange';
    default TAG_SHADOW_BLEND = 'CandleShadowBlendFactor';
    default TAG_OVERRIDE_COLOUR = 'OverrideCandleColour';
    default TAG_RED = 'CandleColorR';
    default TAG_GREEN = 'CandleColorG';
    default TAG_BLUE = 'CandleColorB';
    default TAG_ALIGN_POINT_LIGHTS = 'CandleAlignPointLights';

    public function ReadGameConfig(gameConfig : CInGameConfigWrapper, groupTag : name, params : CLightRewriteSourceParams) {
        super.ReadGameConfig(gameConfig, groupTag, params);

        params.alignPointLights = gameConfig.GetVarValue(groupTag, TAG_ALIGN_POINT_LIGHTS);
    }

    protected function UpdateSpecialMenuDisabledState(flashValueStorage : CScriptedFlashValueStorage, dataArray : CScriptedFlashArray, params : CLightRewriteSourceParams) {
        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_ALIGN_POINT_LIGHTS, !params.enabled);
    }
}
