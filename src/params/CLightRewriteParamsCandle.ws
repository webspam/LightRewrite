class CLightRewriteParamsCandle extends CLightRewriteSourceParams {
    // The tag that will identify this source in the game
    default tag = 'LR_Candle';

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

    default enabled = true;
    default useSpotlightColor = true;
    default brightness = 5.5f;
    default radius = 9.f;
    default attenuation = 1.0f;
    default shadowFadeDistance = 10.f;
    default shadowFadeRange = 3.f;
    default shadowBlendFactor = 1.f;
    default shouldOverrideColour = false;

    default alignPointLights = true;

    default displayName = "candle";
    default rewriterType = LRT_Candle;

    public function Init() {
        color = Color(240, 245, 255);
        // Offset should put the point light roughly in the centre of the candle flame FX
        pointLightOffset = Vector(0.0f, 0.0f, 0.075f);
    }

    public function ReadGameConfig(gameConfig : CInGameConfigWrapper, groupTag : name) {
        super.ReadGameConfig(gameConfig, groupTag);

        alignPointLights = gameConfig.GetVarValue(groupTag, TAG_ALIGN_POINT_LIGHTS);
    }

    protected function UpdateSpecialMenuDisabledState(flashValueStorage : CScriptedFlashValueStorage, dataArray : CScriptedFlashArray) {
        LR_SetMenuOptionDisabled(flashValueStorage, dataArray, TAG_ALIGN_POINT_LIGHTS, !enabled);
    }
}
