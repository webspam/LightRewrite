class CLightRewriteProfile {
    public var profileName: name;

    public var bases: array<name>;

    // Own and inherited groups, weight-sorted; inherited groups come first on equal weight
    public var groups: array<CLightRewriteOverrideGroup>;

    public function BasesToString(): string {
        var text: string;
        var i, count: int;

        count = bases.Size();
        for (i = 0; i < count; i += 1) {
            if (i > 0) text += ", ";
            text += bases[i];
        }

        return text;
    }
}
