/*
 * Unified params class for per-light-source configuration.
 *
 * Every field except tag/displayName is optional; a has* guard being false
 * means "do not touch this property — leave it as the engine set it".
 *
 * When matchRules is non-empty the object acts as an override: it will only
 * be applied to entities that satisfy all of its rules.
 */
class CLightRewriteSourceParams extends ILightRewriteParams {
    // Always required
    public var tag: name;
    public var displayName: string;
    default displayName = "generic";

    // Override matching — empty means this is a base-params entry, not an override
    public var matchRules: array<CLightRewriteMatchRule>;

    // Weight of the override — higher weights override lower weights
    public var weight: int;

    // Profile this override belongs to — empty means no profile assigned
    public var profileName: name;

    // The rewriter implementation to use
    public var hasRewriterType: bool;
    public var rewriterType: ELightRewriteType;

    // Point-light alignment to fire FX slots
    public var hasAlignPointLights: bool;
    public var alignPointLights: bool;
    public var pointLightOffset: Vector;

    // Direct point-light position offset (non-candle lights)
    public var hasPointLightOffset: bool;
    public var pointLightOffsetPos: Vector;

    // Copy the spotlight colour to point lights instead of using an explicit colour
    public var hasUseSpotlightColor: bool;
    public var useSpotlightColor: bool;

    // Force shadow casting on drawable (mesh) components — for noshadow entities
    public var hasForceCastShadows : bool;
    public var forceCastShadows : bool;

    // Spotlight-specific override — NULL if no <spotlight> element was present
    public var spotlight: CLightRewriteSpotlightParams;

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
        if (hasCastShadows) {
            target.hasCastShadows = true;
            target.castShadows = castShadows;
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
        if (hasPointLightOffset) {
            target.hasPointLightOffset = true;
            target.pointLightOffsetPos = pointLightOffsetPos;
        }
        if (hasUseSpotlightColor) {
            target.hasUseSpotlightColor = true;
            target.useSpotlightColor = useSpotlightColor;
        }
        if (hasForceCastShadows) {
            target.hasForceCastShadows = true;
            target.forceCastShadows = forceCastShadows;
        }
        if (spotlight) {
            target.spotlight = spotlight;
        }
    }
}
