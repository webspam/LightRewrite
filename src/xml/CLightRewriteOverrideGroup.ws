/*
 * In-memory form of one <overrides> XML block: its weight, its profile, the
 * filter every contained override must also pass, and the overrides themselves.
 *
 * Holding the shared filter on the block, not on each override, means an entity
 * the block excludes is rejected by a single test instead of one test per override.
 */
class CLightRewriteOverrideGroup {
    public var weight     : int;
    public var profileName: name;

    public var filter: CLightRewriteMatchAll;

    public var overrides: array<CLightRewriteSourceParams>;

    public function Apply(entity: CGameplayEntity, out params: CLightRewriteSourceParams) {
        var override: CLightRewriteSourceParams;
        var i, count: int;

        if (!filter.Matches(entity)) return;

        count = overrides.Size();
        for (i = 0; i < count; i += 1) {
            override = overrides[i];
            if (!override.MatchesEntity(entity)) continue;

            if (!params) params = new CLightRewriteSourceParams in entity;
            override.ApplyTo(params);

            // TODO: Determine if we want tags from all merged overrides
            params.tag = override.tag;
            params.displayName = override.displayName;
        }
    }
}
