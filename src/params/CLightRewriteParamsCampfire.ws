class CLightRewriteParamsCampfire extends CLightRewriteSourceParams {
    default tag = 'LR_Campfire';

    default enabled = true;
    default useSpotlightColor = false;
    default brightness = 50.f;
    default radius = 30.f;
    default attenuation = 1.0f;
    default shadowFadeDistance = 10.f;
    default shadowFadeRange = 3.f;
    default shadowBlendFactor = 1.f;
    default shouldOverrideColour = false;
    default alignPointLights = false;

    default displayName = "campfire";

    public function Init() {
        color = Color(255, 255, 255);
    }
}
