class CLightRewriteSourceParams extends ILightRewriteSourceParams {
    public function GetEffectivePointLightParams(index: int): ILightRewriteParams {
        return MergePointLightParams(GetPointLightParams(index));
    }

    public function MergePointLightParams(
        lightParams: CLightRewriteComponentLightParams
    ): ILightRewriteParams {
        var merged: CLightRewriteComponentLightParams;

        if (!lightParams) return this;

        merged = new CLightRewriteComponentLightParams in this;
        ApplyBaseTo(merged);
        lightParams.ApplyBaseTo(merged);
        return merged;
    }

    // The entity-wide spotlight is the base merged into every component
    public function GetEffectiveSpotLightParams(index: int): CLightRewriteSpotlightParams {
        var entityWide, spotParams, merged: CLightRewriteSpotlightParams;

        if (spotlight && !spotlight.spawn) entityWide = spotlight;
        spotParams = GetSpotLightParams(index);

        if (!entityWide) return spotParams;
        if (!spotParams) return entityWide;

        merged = new CLightRewriteSpotlightParams in this;
        entityWide.ApplySpotlightTo(merged);
        spotParams.ApplySpotlightTo(merged);
        return merged;
    }
}
