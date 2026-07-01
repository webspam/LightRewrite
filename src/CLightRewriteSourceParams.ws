/*
 * Unified params class for per-light-source configuration.
 *
 * Every field except tag/displayName is optional; a has* guard being false
 * means "do not touch this property - leave it as the engine set it".
 *
 * When condition is set the object acts as an override: it will only be
 * applied to entities that satisfy all of its rules.
 */
class CLightRewriteSourceParams extends ILightRewriteParams {
    // Always required
    public var tag        : name;
    public var displayName: string;
    default displayName = "generic";

    // Override match condition - NULL means this is a base-params entry, not an override
    public var condition: CLightRewriteMatchAll;

    // The rewriter implementation to use
    public var rewriterType: SLightRewriteOptionalRewriterType;

    // Point-light alignment to fire FX slots
    public var alignPointLights: SLightRewriteOptionalBool;
    public var pointLightOffset: Vector;

    // Direct point-light position offset (non-candle lights)
    public var pointLightOffsetPos: SLightRewriteOptionalVector;

    // Copy the spotlight colour to point lights instead of using an explicit colour
    public var useSpotlightColor: SLightRewriteOptionalBool;

    public var forceSingleLight: SLightRewriteOptionalBool;

    // Force shadow casting on drawable (mesh) components - for noshadow entities
    public var forceCastShadows: SLightRewriteOptionalBool;

    // Spotlight-specific override - NULL if no <spotlight> element was present
    public var spotlight: CLightRewriteSpotlightParams;

    // Applies every set field from this object onto target, overwriting its values.
    public function ApplyTo(target: CLightRewriteSourceParams) {
        if (enabled.has) target.enabled = enabled;
        if (rewriterType.has) target.rewriterType = rewriterType;
        if (brightness.has) target.brightness = brightness;
        if (radius.has) target.radius = radius;
        if (attenuation.has) target.attenuation = attenuation;
        if (shadowFadeDistance.has) target.shadowFadeDistance = shadowFadeDistance;
        if (shadowFadeRange.has) target.shadowFadeRange = shadowFadeRange;
        if (shadowBlendFactor.has) target.shadowBlendFactor = shadowBlendFactor;
        if (castShadows.has) target.castShadows = castShadows;
        if (color.has) target.color = color;
        if (alignPointLights.has) {
            target.alignPointLights = alignPointLights;
            target.pointLightOffset = pointLightOffset;
        }
        if (pointLightOffsetPos.has) target.pointLightOffsetPos = pointLightOffsetPos;
        if (useSpotlightColor.has) target.useSpotlightColor = useSpotlightColor;
        if (forceSingleLight.has) target.forceSingleLight = forceSingleLight;
        if (forceCastShadows.has) target.forceCastShadows = forceCastShadows;
        if (spotlight) {
            if (!target.spotlight) target.spotlight = new CLightRewriteSpotlightParams in target;
            spotlight.ApplyTo(target.spotlight);
        }
    }
}
