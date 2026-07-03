// Resolves profile inheritance from override groups and answers profile lookups
class CLightRewriteProfileSet {
    // Excludes profiles dropped for circular inheritance
    private var profiles: array<CLightRewriteProfile>;

    // Scratch shared across the recursive resolve of one profile
    private var chain   : array<name>;
    private var visiting: array<name>;

    public function Build(groups: array<CLightRewriteOverrideGroup>) {
        var resolved: array<CLightRewriteProfile>;
        var inheritance: string;
        var i, count: int;

        CollectBases(groups);

        count = profiles.Size();
        for (i = 0; i < count; i += 1) {
            if (!TryResolveChain(profiles[i])) {
                LogLightRewriteXml("Dropping profile '" + profiles[i].profileName + "' - circular inheritance.");
                continue;
            }

            inheritance = profiles[i].BasesToString();
            if (inheritance != "") {
                LogLightRewriteXml("Profile '" + profiles[i].profileName + "' inherits " + inheritance + ".");
            }

            profiles[i].groups = CollectChainGroups(groups);
            resolved.PushBack(profiles[i]);
        }

        profiles = resolved;
    }

    public function AppendNames(out names: array<name>) {
        var i, count: int;

        count = profiles.Size();
        names.Grow(count);
        for (i = 0; i < count; i += 1) {
            names[i] = profiles[i].profileName;
        }
    }

    public function FindByName(profileName: name): CLightRewriteProfile {
        var i, count: int;

        count = profiles.Size();
        for (i = 0; i < count; i += 1) {
            if (profiles[i].profileName == profileName) return profiles[i];
        }

        return NULL;
    }

    /** A profile split across files may declare bases on any of its groups */
    private function CollectBases(groups: array<CLightRewriteOverrideGroup>) {
        var profile: CLightRewriteProfile;
        var i, j, count, inheritCount: int;

        count = groups.Size();
        for (i = 0; i < count; i += 1) {
            profile = FindByName(groups[i].profileName);
            if (!profile) {
                profile = new CLightRewriteProfile in this;
                profile.profileName = groups[i].profileName;
                profiles.PushBack(profile);
            }

            inheritCount = groups[i].inherits.Size();
            for (j = 0; j < inheritCount; j += 1) {
                if (!profile.bases.Contains(groups[i].inherits[j])) {
                    profile.bases.PushBack(groups[i].inherits[j]);
                }
            }
        }
    }

    /** Chain lists bases in application order, the profile itself last; false when inheritance is circular */
    private function TryResolveChain(profile: CLightRewriteProfile): bool {
        chain.Clear();
        visiting.Clear();
        return ExpandChain(profile);
    }

    private function ExpandChain(profile: CLightRewriteProfile): bool {
        var baseProfile: CLightRewriteProfile;
        var i, count: int;

        // A base shared through separate branches is applied once, at its earliest position
        if (chain.Contains(profile.profileName)) return true;
        if (visiting.Contains(profile.profileName)) return false;

        visiting.PushBack(profile.profileName);

        count = profile.bases.Size();
        for (i = 0; i < count; i += 1) {
            baseProfile = FindByName(profile.bases[i]);
            if (!baseProfile) {
                LogLightRewriteXml("Profile '" + profile.profileName + "' inherits unknown profile '" + profile.bases[i] + "'.");
                continue;
            }

            if (!ExpandChain(baseProfile)) return false;
        }

        visiting.Remove(profile.profileName);
        chain.PushBack(profile.profileName);
        return true;
    }

    /** Chain order breaks weight ties, so later bases and finally the profile itself win */
    private function CollectChainGroups(
        groups: array<CLightRewriteOverrideGroup>
    ): array<CLightRewriteOverrideGroup> {
        var result: array<CLightRewriteOverrideGroup>;
        var i, j, count, chainCount: int;

        count = groups.Size();
        chainCount = chain.Size();
        for (i = 0; i < chainCount; i += 1) {
            for (j = 0; j < count; j += 1) {
                if (groups[j].profileName == chain[i]) result.PushBack(groups[j]);
            }
        }

        ArraySortGroupsByWeight(result);
        return result;
    }
}
