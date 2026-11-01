class CLightRewriteMatchedOverrides {
    public var overrides: array<CLightRewriteOverride>;

    public function Apply(target: CLightRewriteMatchTarget): CLightRewriteSourceParams {
        var params: CLightRewriteSourceParams = NULL;
        var i, count: int;

        count = overrides.Size();
        for (i = 0; i < count; i += 1) {
            if (overrides[i].condition.hasScaleRule && !overrides[i].condition.Matches(target)) {
                continue;
            }

            if (!params) params = new CLightRewriteSourceParams in target.entity;
            overrides[i].ApplyTo(params);

            // TODO: Determine if we want tags from all merged overrides
            params.tag = overrides[i].tag;
        }

        return params;
    }
}
