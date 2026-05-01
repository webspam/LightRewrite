class CLightRewriteParamsCandle extends CLightRewriteSourceParams {
    default tag = 'LR_Candle';

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
}
