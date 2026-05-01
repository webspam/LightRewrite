class CLightRewriteParamsTorch extends CLightRewriteSourceParams {
    // The tag that will identify this source in the game
    default tag = 'LR_Torch';

    default TAG_ENABLED = 'TorchEnabled';
    default TAG_BRIGHTNESS = 'TorchBrightness';
    default TAG_RADIUS = 'TorchRadius';
    default TAG_ATTENUATION = 'TorchAttenuation';
    default TAG_SHADOW_DISTANCE = 'TorchShadowFadeDistance';
    default TAG_SHADOW_RANGE = 'TorchShadowFadeRange';
    default TAG_SHADOW_BLEND = 'TorchShadowBlendFactor';
    default TAG_OVERRIDE_COLOUR = 'OverrideTorchColour';
    default TAG_RED = 'TorchColorR';
    default TAG_GREEN = 'TorchColorG';
    default TAG_BLUE = 'TorchColorB';

    default enabled = true;
    default useSpotlightColor = false;
    default brightness = 30.f;
    default radius = 20.f;
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

