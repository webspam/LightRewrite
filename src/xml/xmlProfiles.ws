function BuildLightRewriteProfiles(
    owner: CObject,
    groups: array<CLightRewriteOverrideGroup>
): array<CLightRewriteProfile> {
    var profiles, resolved: array<CLightRewriteProfile>;
    var chain: array<name>;
    var i, count: int;

    profiles = LR_CollectProfileBases(owner, groups);

    count = profiles.Size();
    for (i = 0; i < count; i += 1) {
        if (!LR_TryResolveProfileChain(profiles[i], profiles, chain)) {
            LogLightRewriteXml("Dropping profile '" + profiles[i].profileName + "' - circular inheritance.");
            continue;
        }

        profiles[i].groups = LR_CollectProfileChainGroups(groups, chain);
        resolved.PushBack(profiles[i]);
    }

    return resolved;
}

/** A profile split across files may declare bases on any of its groups */
function LR_CollectProfileBases(
    owner: CObject,
    groups: array<CLightRewriteOverrideGroup>
): array<CLightRewriteProfile> {
    var profiles: array<CLightRewriteProfile>;
    var profile: CLightRewriteProfile;
    var i, j, count, inheritCount: int;

    count = groups.Size();
    for (i = 0; i < count; i += 1) {
        profile = LR_FindProfile(profiles, groups[i].profileName);
        if (!profile) {
            profile = new CLightRewriteProfile in owner;
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

    return profiles;
}

function LR_FindProfile(
    profiles: array<CLightRewriteProfile>,
    profileName: name
): CLightRewriteProfile {
    var i, count: int;

    count = profiles.Size();
    for (i = 0; i < count; i += 1) {
        if (profiles[i].profileName == profileName) return profiles[i];
    }

    return NULL;
}

/** Chain lists bases in application order, the profile itself last; false when inheritance is circular */
function LR_TryResolveProfileChain(
    profile: CLightRewriteProfile,
    profiles: array<CLightRewriteProfile>,
    out chain: array<name>
): bool {
    var visiting: array<name>;

    chain.Clear();
    return LR_ExpandProfileChain(profile, profiles, visiting, chain);
}

function LR_ExpandProfileChain(
    profile: CLightRewriteProfile,
    profiles: array<CLightRewriteProfile>,
    out visiting: array<name>,
    out chain: array<name>
): bool {
    var baseProfile: CLightRewriteProfile;
    var i, count: int;

    // A base shared through separate branches is applied once, at its earliest position
    if (chain.Contains(profile.profileName)) return true;
    if (visiting.Contains(profile.profileName)) return false;

    visiting.PushBack(profile.profileName);

    count = profile.bases.Size();
    for (i = 0; i < count; i += 1) {
        baseProfile = LR_FindProfile(profiles, profile.bases[i]);
        if (!baseProfile) {
            LogLightRewriteXml("Profile '" + profile.profileName + "' inherits unknown profile '" + profile.bases[i] + "'.");
            continue;
        }

        if (!LR_ExpandProfileChain(baseProfile, profiles, visiting, chain)) return false;
    }

    visiting.Remove(profile.profileName);
    chain.PushBack(profile.profileName);
    return true;
}

/** Chain order breaks weight ties, so later bases and finally the profile itself win */
function LR_CollectProfileChainGroups(
    groups: array<CLightRewriteOverrideGroup>,
    chain: array<name>
): array<CLightRewriteOverrideGroup> {
    var result: array<CLightRewriteOverrideGroup>;
    var i, j, count: int;

    count = groups.Size();
    for (i = 0; i < chain.Size(); i += 1) {
        for (j = 0; j < count; j += 1) {
            if (groups[j].profileName == chain[i]) result.PushBack(groups[j]);
        }
    }

    ArraySortGroupsByWeight(result);
    return result;
}
