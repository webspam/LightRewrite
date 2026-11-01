class CLightRewriteOverrideGroup {
    public var weight     : int;
    public var profileName: name;
    public var inherits   : array<name>;

    public var filter: CLightRewriteMatchAll;

    public var overrides: array<CLightRewriteOverride>;

    public function Apply(
        target: CLightRewriteMatchTarget,
        params: CLightRewriteSourceParams
    ): CLightRewriteSourceParams {
        var override: CLightRewriteOverride;
        var i, count: int;

        if (!filter.Matches(target)) return params;

        count = overrides.Size();
        for (i = 0; i < count; i += 1) {
            override = overrides[i];
            if (!override.condition.Matches(target)) continue;

            if (!params) params = new CLightRewriteSourceParams in target.entity;
            override.ApplyTo(params);

            // TODO: Determine if we want tags from all merged overrides
            params.tag = override.tag;
        }

        return params;
    }
}
