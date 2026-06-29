class CLightRewriteSpotlightParams extends ILightRewriteParams {
    public var innerAngle: SLightRewriteOptionalFloat;

    public var outerAngle: SLightRewriteOptionalFloat;

    public var softness: SLightRewriteOptionalFloat;

    public var offset: SLightRewriteOptionalVector;

    // When set, a spotlight entity is spawned for the match rather than editing an existing component
    public var spawn: bool;  default spawn = false;

    public function ApplyTo(target: CLightRewriteSpotlightParams) {
        if (enabled.has) target.enabled = enabled;
        if (brightness.has) target.brightness = brightness;
        if (radius.has) target.radius = radius;
        if (attenuation.has) target.attenuation = attenuation;
        if (shadowFadeDistance.has) target.shadowFadeDistance = shadowFadeDistance;
        if (shadowFadeRange.has) target.shadowFadeRange = shadowFadeRange;
        if (shadowBlendFactor.has) target.shadowBlendFactor = shadowBlendFactor;
        if (castShadows.has) target.castShadows = castShadows;
        if (color.has) target.color = color;
        if (innerAngle.has) target.innerAngle = innerAngle;
        if (outerAngle.has) target.outerAngle = outerAngle;
        if (softness.has) target.softness = softness;
        if (offset.has) target.offset = offset;
        target.spawn = spawn;
    }
}
