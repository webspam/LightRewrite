class CLightRewriteParamsBrazier extends CLightRewriteSourceParams {
    default tag = 'LR_Brazier';

    default enabled = true;
    default useSpotlightColor = false;
    default brightness = 40.f;
    default radius = 25.f;
    default attenuation = 1.0f;
    default shadowFadeDistance = 35.f;
    default shadowFadeRange = 10.f;
    default shadowBlendFactor = 1.f;
    default shouldOverrideColour = false;
    default alignPointLights = true;

    default displayName = "brazier";

    public function Init() {
        color = Color(255, 255, 255);
    }
}
