class CLightRewriteParamsCandelabra extends CLightRewriteSourceParams {
    default tag = 'LR_Candelabra';

    default enabled = true;
    default useSpotlightColor = true;
    default brightness = 8.0f;
    default radius = 12.f;
    default attenuation = 1.0f;
    default shadowFadeDistance = 10.f;
    default shadowFadeRange = 3.f;
    default shadowBlendFactor = 1.f;
    default shouldOverrideColour = false;
    default alignPointLights = false;

    default displayName = "candelabra";

    public function Init() {
        color = Color(255, 255, 255);
    }
}
