class CLightRewriteParamsBrazier extends CLightRewriteSourceParams {
    // The tag that will identify this source in the game
    default tag = 'LR_Brazier';

    default TAG_ENABLED = 'BrazierEnabled';
    default TAG_BRIGHTNESS = 'BrazierBrightness';
    default TAG_RADIUS = 'BrazierRadius';
    default TAG_ATTENUATION = 'BrazierAttenuation';
    default TAG_SHADOW_DISTANCE = 'BrazierShadowFadeDistance';
    default TAG_SHADOW_RANGE = 'BrazierShadowFadeRange';
    default TAG_SHADOW_BLEND = 'BrazierShadowBlendFactor';
    default TAG_OVERRIDE_COLOUR = 'OverrideBrazierColour';
    default TAG_RED = 'BrazierColorR';
    default TAG_GREEN = 'BrazierColorG';
    default TAG_BLUE = 'BrazierColorB';
    default TAG_ALIGN_POINT_LIGHTS = 'BrazierAlignPointLights';

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

    public function Init() {
        color = Color(255, 255, 255);
    }
}

