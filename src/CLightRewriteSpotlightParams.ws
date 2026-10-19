class CLightRewriteSpotlightParams extends CLightRewriteComponentLightParams {
    public var innerAngle: SLightRewriteOptionalFloat;

    public var outerAngle: SLightRewriteOptionalFloat;

    public var softness: SLightRewriteOptionalFloat;

    public var rotation: SLightRewriteOptionalEulerAngles;

    // When set, a spotlight entity is spawned for the match rather than editing an existing component
    public var spawn: bool;  default spawn = false;

    public function ApplySpotlightTo(target: CLightRewriteSpotlightParams) {
        ApplyBaseTo(target);

        if (innerAngle.has) target.innerAngle = innerAngle;
        if (outerAngle.has) target.outerAngle = outerAngle;
        if (softness.has) target.softness = softness;
        if (rotation.has) target.rotation = rotation;
        target.spawn = spawn;
    }
}
