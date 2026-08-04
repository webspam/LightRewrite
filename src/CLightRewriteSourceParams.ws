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

    // Copy the spotlight colour to point lights instead of using an explicit colour
    public var useSpotlightColor: SLightRewriteOptionalBool;

    public var forceSingleLight: SLightRewriteOptionalBool;

    // Force shadow casting on drawable (mesh) components - for noshadow entities
    public var forceCastShadows: SLightRewriteOptionalBool;

    // Spotlight-specific override - NULL if no <spotlight> element was present
    public var spotlight: CLightRewriteSpotlightParams;

    // Per-component overrides, applied on top of the entity-wide fields above
    public var pointLights: array<CLightRewriteComponentLightParams>;
    public var spotLights : array<CLightRewriteSpotlightParams>;

    public function GetPointLightParams(index: int): CLightRewriteComponentLightParams {
        var i: int;
        var count: int = pointLights.Size();

        for (i = 0; i < count; i += 1) {
            if (pointLights[i].index == index) return pointLights[i];
        }
        return NULL;
    }

    public function GetOrCreatePointLightParams(index: int): CLightRewriteComponentLightParams {
        var params: CLightRewriteComponentLightParams;

        params = GetPointLightParams(index);
        if (!params) {
            params = new CLightRewriteComponentLightParams in this;
            params.index = index;
            pointLights.PushBack(params);
        }
        return params;
    }

    public function GetSpotLightParams(index: int): CLightRewriteSpotlightParams {
        var i: int;
        var count: int = spotLights.Size();

        for (i = 0; i < count; i += 1) {
            if (spotLights[i].index == index) return spotLights[i];
        }
        return NULL;
    }

    public function GetOrCreateSpotLightParams(index: int): CLightRewriteSpotlightParams {
        var params: CLightRewriteSpotlightParams = GetSpotLightParams(index);

        if (!params) {
            params = new CLightRewriteSpotlightParams in this;
            params.index = index;
            spotLights.PushBack(params);
        }
        return params;
    }

    // Applies every set field from this object onto target, overwriting its values.
    public function ApplyTo(target: CLightRewriteSourceParams) {
        var i: int;
        var pointCount: int = pointLights.Size();
        var spotCount: int = spotLights.Size();

        ApplyBaseTo(target);
        if (rewriterType.has) target.rewriterType = rewriterType;
        if (alignPointLights.has) {
            target.alignPointLights = alignPointLights;
            target.pointLightOffset = pointLightOffset;
        }
        if (useSpotlightColor.has) target.useSpotlightColor = useSpotlightColor;
        if (forceSingleLight.has) target.forceSingleLight = forceSingleLight;
        if (forceCastShadows.has) target.forceCastShadows = forceCastShadows;
        if (spotlight) {
            if (!target.spotlight) target.spotlight = new CLightRewriteSpotlightParams in target;
            spotlight.ApplySpotlightTo(target.spotlight);
        }
        for (i = 0; i < pointCount; i += 1) {
            pointLights[i].ApplyTo(target.GetOrCreatePointLightParams(pointLights[i].index));
        }
        for (i = 0; i < spotCount; i += 1) {
            spotLights[i].ApplySpotlightTo(target.GetOrCreateSpotLightParams(spotLights[i].index));
        }
    }
}
