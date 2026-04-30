class CLightRewriteParamsChandelier extends CLightRewriteSourceParams {
    // The tag that will identify this source in the game
    default tag = 'LR_Chandelier';

    default TAG_ENABLED = 'ChandelierEnabled';
    default TAG_BRIGHTNESS = 'ChandelierBrightness';
    default TAG_RADIUS = 'ChandelierRadius';
    default TAG_ATTENUATION = 'ChandelierAttenuation';
    default TAG_SHADOW_DISTANCE = 'ChandelierShadowFadeDistance';
    default TAG_SHADOW_RANGE = 'ChandelierShadowFadeRange';
    default TAG_SHADOW_BLEND = 'ChandelierShadowBlendFactor';
    default TAG_OVERRIDE_COLOUR = 'OverrideChandelierColour';
    default TAG_RED = 'ChandelierColorR';
    default TAG_GREEN = 'ChandelierColorG';
    default TAG_BLUE = 'ChandelierColorB';

    default enabled = true;
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

