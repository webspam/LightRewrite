/*
 * Base class for light entry params. Holds the light component properties that
 * are shared between point light overrides and spotlight overrides.
 *
 * Effectively maps to CLightComponent fields.
 */
abstract class ILightRewriteParams {
    public var enabled   : SLightRewriteOptionalBool;
    public var brightness: CLightRewriteClampedFloat;
    public var radius    : CLightRewriteClampedFloat;

    // Attenuation - how quickly the light fades out with distance
    public var attenuation: CLightRewriteClampedFloat;

    // Distance at which the player shadow starts to fade
    public var shadowFadeDistance: CLightRewriteClampedFloat;

    // Range over which the shadow fades from shadowFadeDistance
    public var shadowFadeRange  : CLightRewriteClampedFloat;
    public var shadowBlendFactor: SLightRewriteOptionalFloat;

    // Automatically starts fading out from the scene once the camera is above this distance
    public var autoHideDistance: CLightRewriteClampedFloat;
    // Range over which the light starts to fade out from autoHideDistance
    public var autoHideRange   : CLightRewriteClampedFloat;

    public var castShadows: SLightRewriteOptionalShadowMode;
    public var usageMask  : SLightRewriteUsageMaskEdit;

    public var color: SLightRewriteOptionalColour;

    // Local-space position override for the light
    public var offset: SLightRewriteOptionalVector;

    public function ApplyBaseTo(target: ILightRewriteParams) {
        if (enabled.has) target.enabled = enabled;
        target.brightness = MergeClampedFloat(target, target.brightness, brightness);
        target.radius = MergeClampedFloat(target, target.radius, radius);
        target.attenuation = MergeClampedFloat(target, target.attenuation, attenuation);
        target.shadowFadeDistance = MergeClampedFloat(
            target,
            target.shadowFadeDistance,
            shadowFadeDistance
        );
        target.shadowFadeRange = MergeClampedFloat(target, target.shadowFadeRange, shadowFadeRange);
        if (shadowBlendFactor.has) target.shadowBlendFactor = shadowBlendFactor;
        target.autoHideDistance = MergeClampedFloat(
            target,
            target.autoHideDistance,
            autoHideDistance
        );
        target.autoHideRange = MergeClampedFloat(target, target.autoHideRange, autoHideRange);
        if (castShadows.has) target.castShadows = castShadows;
        target.usageMask = LR_MergeUsageMaskEdit(target.usageMask, usageMask);
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
