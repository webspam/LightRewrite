class CLightRewriteOverrideGroup {
    public var weight     : int;
    public var profileName: name;
    public var inherits   : array<name>;
    public var transports : array<ELightRewriteLightTransport>;

    public var filter: CLightRewriteMatchAll;

    public var overrides: array<CLightRewriteOverride>;

    public function CollectMatches(
        target: CLightRewriteMatchTarget,
        matched: CLightRewriteMatchedOverrides
    ) {
        var i, count: int;

        if (!filter.Matches(target)) return;

        count = overrides.Size();
        for (i = 0; i < count; i += 1) {
            if (overrides[i].condition.hasScaleRule || overrides[i].condition.Matches(target)) {
                matched.overrides.PushBack(overrides[i]);
            }
        }
    }
}
