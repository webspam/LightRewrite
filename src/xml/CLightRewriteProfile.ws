class CLightRewriteProfile {
    public var profileName: name;

    public var bases: array<name>;

    // Own and inherited groups, weight-sorted; inherited groups come first on equal weight
    public var groups: array<CLightRewriteOverrideGroup>;
}
