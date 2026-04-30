class CLightRewriteParamsCandelabra extends CLightRewriteSourceParams {
    // The tag that will identify this source in the game
    default tag = 'LR_Candelabra';

    default TAG_ENABLED = 'CandelabraEnabled';
    default TAG_BRIGHTNESS = 'CandelabraBrightness';
    default TAG_RADIUS = 'CandelabraRadius';
    default TAG_ATTENUATION = 'CandelabraAttenuation';
    default TAG_SHADOW_DISTANCE = 'CandelabraShadowFadeDistance';
    default TAG_SHADOW_RANGE = 'CandelabraShadowFadeRange';
    default TAG_SHADOW_BLEND = 'CandelabraShadowBlendFactor';
    default TAG_OVERRIDE_COLOUR = 'OverrideCandelabraColour';
    default TAG_RED = 'CandelabraColorR';
    default TAG_GREEN = 'CandelabraColorG';
    default TAG_BLUE = 'CandelabraColorB';

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

