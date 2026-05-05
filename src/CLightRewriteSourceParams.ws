/*
 * Unified params class for per-light-source configuration.
 *
 * Every field except tag/displayName is optional; a has* guard being false
 * means "do not touch this property — leave it as the engine set it".
 *
 * When matchRules is non-empty the object acts as an override: it will only
 * be applied to entities that satisfy all of its rules.
 */
class CLightRewriteSourceParams {
    // Always required
    public var tag : name;
    public var displayName : string;
    default displayName = "generic";

    // Override matching — empty means this is a base-params entry, not an override
    public var matchRules : array<CLightRewriteMatchRule>;

    // Weight of the override — higher weights override lower weights
    public var weight : int;

    // Whether this light source type is active
    public var hasEnabled : bool;
    public var enabled : bool;

    // The rewriter implementation to use
    public var hasRewriterType : bool;
    public var rewriterType : ELightRewriteType;

    // Light source brightness
    public var hasBrightness : bool;
    public var brightness : float;

    // Cutoff radius (sphere)
    public var hasRadius : bool;
    public var radius : float;

    // Attenuation — how quickly the light fades out with distance
    public var hasAttenuation : bool;
    public var attenuation : float;

    // Distance at which the player shadow starts to fade
    public var hasShadowFadeDistance : bool;
    public var shadowFadeDistance : float;

    // Range over which the shadow fades from shadowFadeDistance
    public var hasShadowFadeRange : bool;
    public var shadowFadeRange : float;

    public var hasShadowBlendFactor : bool;
    public var shadowBlendFactor : float;

    // Colour override — hasColour replaces the old shouldOverrideColour sentinel
    public var hasColour : bool;
    public var color : Color;

    // Point-light alignment to fire FX slots
    public var hasAlignPointLights : bool;
    public var alignPointLights : bool;
    public var pointLightOffset : Vector;

    // Copy the spotlight colour to point lights instead of using an explicit colour
    public var hasUseSpotlightColor : bool;
    public var useSpotlightColor : bool;

    // Virtual constructor
    public function Init() {}

    // Returns true if this params object matches the given entity (all rules must pass).
    public function MatchesEntity(entity : CGameplayEntity) : bool {
        var i, count : int;

        count = matchRules.Size();
        for (i = 0; i < count; i += 1) {
            if (!matchRules[i].Matches(entity)) {
                return false;
            }
        }

        return true;
    }

    // Applies every set field from this object onto target, overwriting its values.
    public function ApplyTo(target : CLightRewriteSourceParams) {
        if (hasEnabled) {
            target.hasEnabled = true;
            target.enabled = enabled;
        }
        if (hasRewriterType) {
            target.hasRewriterType = true;
            target.rewriterType = rewriterType;
        }
        if (hasBrightness) {
            target.hasBrightness = true;
            target.brightness = brightness;
        }
        if (hasRadius) {
            target.hasRadius = true;
            target.radius = radius;
        }
        if (hasAttenuation) {
            target.hasAttenuation = true;
            target.attenuation = attenuation;
        }
        if (hasShadowFadeDistance) {
            target.hasShadowFadeDistance = true;
            target.shadowFadeDistance = shadowFadeDistance;
        }
        if (hasShadowFadeRange) {
            target.hasShadowFadeRange = true;
            target.shadowFadeRange = shadowFadeRange;
        }
        if (hasShadowBlendFactor) {
            target.hasShadowBlendFactor = true;
            target.shadowBlendFactor = shadowBlendFactor;
        }
        if (hasColour) {
            target.hasColour = true;
            target.color = color;
        }
        if (hasAlignPointLights) {
            target.hasAlignPointLights = true;
            target.alignPointLights = alignPointLights;
            target.pointLightOffset = pointLightOffset;
        }
        if (hasUseSpotlightColor) {
            target.hasUseSpotlightColor = true;
            target.useSpotlightColor = useSpotlightColor;
        }
    }
}
