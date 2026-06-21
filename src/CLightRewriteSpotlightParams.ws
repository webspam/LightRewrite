class CLightRewriteSpotlightParams extends ILightRewriteParams {
    public var innerAngle: SLightRewriteOptionalFloat;

    public var outerAngle: SLightRewriteOptionalFloat;

    public var softness: SLightRewriteOptionalFloat;

    public var offset: SLightRewriteOptionalVector;

    // When set, a spotlight entity is spawned for the match rather than editing an existing component
    public var spawn: bool;  default spawn = false;
}
