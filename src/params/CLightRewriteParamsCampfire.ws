class CLightRewriteParamsCampfire extends CLightRewriteSourceParams {
    // The tag that will identify this source in the game
    default tag = 'LR_Campfire';

    default TAG_ENABLED = 'CampfireEnabled';
    default TAG_BRIGHTNESS = 'CampfireBrightness';
    default TAG_RADIUS = 'CampfireRadius';
    default TAG_ATTENUATION = 'CampfireAttenuation';
    default TAG_SHADOW_DISTANCE = 'CampfireShadowFadeDistance';
    default TAG_SHADOW_RANGE = 'CampfireShadowFadeRange';
    default TAG_SHADOW_BLEND = 'CampfireShadowBlendFactor';
    default TAG_OVERRIDE_COLOUR = 'OverrideCampfireColour';
    default TAG_RED = 'CampfireColorR';
    default TAG_GREEN = 'CampfireColorG';
    default TAG_BLUE = 'CampfireColorB';

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

    public function Init() {
        color = Color(255, 255, 255);
    }
}

