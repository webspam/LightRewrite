/*
 * Base class for light entry params. Holds the light component properties that
 * are shared between point light overrides and spotlight overrides.
 *
 * Effectively maps to CLightComponent fields.
 */
abstract class ILightRewriteParams {
    public var enabled: SLightRewriteOptionalBool;

    public var brightness: CLightRewriteClampedFloat;

    public var radius: CLightRewriteClampedFloat;

    // Attenuation - how quickly the light fades out with distance
    public var attenuation: CLightRewriteClampedFloat;

    // Distance at which the player shadow starts to fade
    public var shadowFadeDistance: SLightRewriteOptionalFloat;

    // Range over which the shadow fades from shadowFadeDistance
    public var shadowFadeRange: SLightRewriteOptionalFloat;

    public var shadowBlendFactor: SLightRewriteOptionalFloat;

    public var castShadows: SLightRewriteOptionalShadowMode;

    public var color: SLightRewriteOptionalColour;

    // Local-space position override for the light
    public var offset: SLightRewriteOptionalVector;

    public function ApplyBaseTo(target: ILightRewriteParams) {
        if (enabled.has) target.enabled = enabled;
        target.brightness = MergeClampedFloat(target, target.brightness, brightness);
        target.radius = MergeClampedFloat(target, target.radius, radius);
        target.attenuation = MergeClampedFloat(target, target.attenuation, attenuation);
        if (shadowFadeDistance.has) target.shadowFadeDistance = shadowFadeDistance;
        if (shadowFadeRange.has) target.shadowFadeRange = shadowFadeRange;
        if (shadowBlendFactor.has) target.shadowBlendFactor = shadowBlendFactor;
        if (castShadows.has) target.castShadows = castShadows;
        if (color.has) target.color = color;
        if (offset.has) target.offset = offset;
    }

    private function MergeClampedFloat(
        target: ILightRewriteParams,
        lowerWeight: CLightRewriteClampedFloat,
        higherWeight: CLightRewriteClampedFloat
    ): CLightRewriteClampedFloat {
        if (!higherWeight) return lowerWeight;

        if (!lowerWeight) lowerWeight = new CLightRewriteClampedFloat in target;
        lowerWeight.MergeFrom(higherWeight);
        return lowerWeight;
    }
}
