class CLightRewriteSpotlightParams extends ILightRewriteParams {
    // -1 targets every spotlight (the entity-wide params); >= 0 targets one component
    public var index: int;  default index = -1;

    public var innerAngle: SLightRewriteOptionalFloat;

    public var outerAngle: SLightRewriteOptionalFloat;

    public var softness: SLightRewriteOptionalFloat;

    public var offset: SLightRewriteOptionalVector;

    // When set, a spotlight entity is spawned for the match rather than editing an existing component
    public var spawn: bool;  default spawn = false;

    public function ApplyTo(target: CLightRewriteSpotlightParams) {
        ApplyBaseTo(target);
        if (innerAngle.has) target.innerAngle = innerAngle;
        if (outerAngle.has) target.outerAngle = outerAngle;
        if (softness.has) target.softness = softness;
        if (offset.has) target.offset = offset;
        target.spawn = spawn;
    }
}
