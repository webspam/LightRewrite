class CLightRewriteProfile {
    private const var CACHE_KEY_SEPARATOR: string;  default CACHE_KEY_SEPARATOR = "|";

    public var profileName: name;

    public var bases: array<name>;

    // Own and inherited groups, weight-sorted; inherited groups come first on equal weight
    public var groups: array<CLightRewriteOverrideGroup>;

    private var matchCache: map<string, CLightRewriteMatchedOverrides>;

    public function FindParams(
        target: CLightRewriteMatchTarget,
        transport: ELightRewriteLightTransport
    ): CLightRewriteSourceParams {
        return GetMatchedOverrides(target, transport).Apply(target);
    }

    private function GetMatchedOverrides(
        target: CLightRewriteMatchTarget,
        transport: ELightRewriteLightTransport
    ): CLightRewriteMatchedOverrides {
        var key: string = target.layerPath + CACHE_KEY_SEPARATOR + target.entityFile + CACHE_KEY_SEPARATOR + (int)transport;
        var matched: CLightRewriteMatchedOverrides;
        var i, count: int;

        if (matchCache.Contains(key)) return matchCache[key];

        matched = new CLightRewriteMatchedOverrides in this;

        count = groups.Size();
        for (i = 0; i < count; i += 1) {
            if (!groups[i].transports.Contains(transport)) continue;

            groups[i].CollectMatches(target, matched);
        }

        matchCache[key] = matched;
        return matched;
    }

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
