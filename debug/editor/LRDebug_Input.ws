class LRDebug_Input {
    public const var BRIGHTNESS_MODIFIER          : name;  default BRIGHTNESS_MODIFIER = 'LRDebug_BrightnessModifier';
    public const var RADIUS_MODIFIER              : name;  default RADIUS_MODIFIER = 'LRDebug_RadiusModifier';
    public const var ATTENUATION_MODIFIER         : name;  default ATTENUATION_MODIFIER = 'LRDebug_AttenuationModifier';
    public const var SHADOW_FADE_DISTANCE_MODIFIER: name;  default SHADOW_FADE_DISTANCE_MODIFIER = 'LRDebug_ShadowFadeDistanceModifier';
    public const var SHADOW_FADE_RANGE_MODIFIER   : name;  default SHADOW_FADE_RANGE_MODIFIER = 'LRDebug_ShadowFadeRangeModifier';
    public const var SHADOW_BLEND_FACTOR_MODIFIER : name;  default SHADOW_BLEND_FACTOR_MODIFIER = 'LRDebug_ShadowBlendFactorModifier';
    public const var USE_SPOTLIGHT_COLOR_MODIFIER : name;  default USE_SPOTLIGHT_COLOR_MODIFIER = 'LRDebug_UseSpotlightColorModifier';
    public const var ALIGN_POINT_LIGHTS_MODIFIER  : name;  default ALIGN_POINT_LIGHTS_MODIFIER = 'LRDebug_AlignPointLightsModifier';
    public const var ALIGN_OFFSET_Z_MODIFIER      : name;  default ALIGN_OFFSET_Z_MODIFIER = 'LRDebug_AlignOffsetZModifier';
    public const var OVERRIDE_COLOUR_MODIFIER     : name;  default OVERRIDE_COLOUR_MODIFIER = 'LRDebug_OverrideColourModifier';
    public const var COLOUR_R_MODIFIER            : name;  default COLOUR_R_MODIFIER = 'LRDebug_ColourRModifier';
    public const var COLOUR_G_MODIFIER            : name;  default COLOUR_G_MODIFIER = 'LRDebug_ColourGModifier';
    public const var COLOUR_B_MODIFIER            : name;  default COLOUR_B_MODIFIER = 'LRDebug_ColourBModifier';

    // Hold-to-edit: holding a modifier locks the camera and feeds mouse-Y into the value.
    public const var CAMERA_LOCK_SOURCE     : name;   default CAMERA_LOCK_SOURCE = 'LRDebug';
    public const var ADJUST_AXIS_SENSITIVITY: float;  default ADJUST_AXIS_SENSITIVITY = 0.5; // tune in-game
}
