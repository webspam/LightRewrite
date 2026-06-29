/*
 * One <overrides> XML group: a shared match gate plus the overrides it guards.
 *
 * The gate is tested once per entity; the group's overrides are only considered
 * when it passes. Every override in a group shares the group's weight.
 */
class CLightRewriteOverrideGroup {
    public var weight     : int;
    public var profileName: name;

    // Shared filters guarding the whole group; an empty gate admits every entity
    public var gate: CLightRewriteMatchAll;

    public var overrides: array<CLightRewriteSourceParams>;

    public function ApplyMatching(entity: CGameplayEntity, out params: CLightRewriteSourceParams) {
        var override: CLightRewriteSourceParams;
        var i, count: int;

        if (!gate.Matches(entity)) return;

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
