class CLightRewriteSpotlightParams extends CLightRewriteComponentLightParams {
    public var innerAngle: SLightRewriteOptionalFloat;

    public var outerAngle: SLightRewriteOptionalFloat;

    public var softness: SLightRewriteOptionalFloat;

    // When set, a spotlight entity is spawned for the match rather than editing an existing component
    public var spawn: bool;  default spawn = false;

    public function ApplyTo(target: CLightRewriteComponentLightParams) {
        var spot: CLightRewriteSpotlightParams = (CLightRewriteSpotlightParams)target;

        super.ApplyTo(target);

        if (!spot) return;
        if (innerAngle.has) spot.innerAngle = innerAngle;
        if (outerAngle.has) spot.outerAngle = outerAngle;
        if (softness.has) spot.softness = softness;
        spot.spawn = spawn;
    }
}
