/*
 * Base class for light entry params. Holds the light component properties that
 * are shared between point light overrides and spotlight overrides.
 *
 * Effectively maps to CLightComponent fields.
 */
abstract class ILightRewriteParams {
    public var enabled: SLightRewriteOptionalBool;

    public var brightness: SLightRewriteOptionalFloat;

    public var radius: SLightRewriteOptionalFloat;

    // Attenuation - how quickly the light fades out with distance
    public var attenuation: SLightRewriteOptionalFloat;

    // Distance at which the player shadow starts to fade
    public var shadowFadeDistance: SLightRewriteOptionalFloat;

    // Range over which the shadow fades from shadowFadeDistance
    public var shadowFadeRange: SLightRewriteOptionalFloat;

    public var shadowBlendFactor: SLightRewriteOptionalFloat;

    public var castShadows: SLightRewriteOptionalShadowMode;

    public var color: SLightRewriteOptionalColour;

    public function ApplyBaseTo(target: ILightRewriteParams) {
        if (enabled.has) target.enabled = enabled;
        if (brightness.has) target.brightness = brightness;
        if (radius.has) target.radius = radius;
        if (attenuation.has) target.attenuation = attenuation;
        if (shadowFadeDistance.has) target.shadowFadeDistance = shadowFadeDistance;
        if (shadowFadeRange.has) target.shadowFadeRange = shadowFadeRange;
        if (shadowBlendFactor.has) target.shadowBlendFactor = shadowBlendFactor;
        if (castShadows.has) target.castShadows = castShadows;
        if (color.has) target.color = color;
    }
}
