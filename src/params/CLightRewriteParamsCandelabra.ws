class CLightRewriteParamsCandelabra extends CLightRewriteSourceParams {
    // The tag that will identify this source in the game
    default tag = 'LR_Candelabra';

    default useSpotlightColor = true;
    default brightness = 8.0f;
    default radius = 12.f;
    default attenuation = 1.0f;
    default shadowFadeDistance = 10.f;
    default shadowFadeRange = 3.f;
    default shadowBlendFactor = 1.f;
    default shouldOverrideColour = false;

    public function Init() {
        color = Color(255, 255, 255);
    }
}

