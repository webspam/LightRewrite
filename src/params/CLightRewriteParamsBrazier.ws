class CLightRewriteParamsBrazier extends CLightRewriteSourceParams {
    // The tag that will identify this source in the game
    default tag = 'LR_Brazier';

    default useSpotlightColor = false;
    default brightness = 40.f;
    default radius = 25.f;
    default attenuation = 1.0f;
    default shadowFadeDistance = 35.f;
    default shadowFadeRange = 10.f;
    default shadowBlendFactor = 1.f;
    default shouldOverrideColour = false;

    public function Init() {
        color = Color(255, 255, 255);
    }
}

