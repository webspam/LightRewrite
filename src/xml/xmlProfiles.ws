function BuildLightRewriteProfiles(
    owner: CObject,
    groups: array<CLightRewriteOverrideGroup>
): array<CLightRewriteProfile> {
    var profiles: array<CLightRewriteProfile>;
    var profileNames, bases, chain: array<name>;
    var profile: CLightRewriteProfile;
    var i, count: int;

    LR_CollectProfileBases(groups, profileNames, bases);

    count = profileNames.Size();
    for (i = 0; i < count; i += 1) {
        if (!LR_TryResolveProfileChain(profileNames[i], profileNames, bases, chain)) {
            LogLightRewriteXml("Dropping profile '" + NameToString(profileNames[i]) + "' - circular inheritance.");
            continue;
        }

        profile = new CLightRewriteProfile in owner;
        profile.profileName = profileNames[i];
        profile.groups = LR_CollectProfileChainGroups(groups, chain);
        profiles.PushBack(profile);
    }

    return profiles;
}

/** A profile split across files may declare its base on any of its groups */
function LR_CollectProfileBases(
    groups: array<CLightRewriteOverrideGroup>,
    out profileNames: array<name>,
    out bases: array<name>
) {
    var i, idx, count: int;

    count = groups.Size();
    for (i = 0; i < count; i += 1) {
        idx = profileNames.FindFirst(groups[i].profileName);
        if (idx == -1) {
            profileNames.PushBack(groups[i].profileName);
            bases.PushBack(groups[i].inheritsProfile);
            continue;
        }

        if (groups[i].inheritsProfile == '') continue;

        if (bases[idx] == '') {
            bases[idx] = groups[i].inheritsProfile;
        }
        else if (bases[idx] != groups[i].inheritsProfile) {
            LogLightRewriteXml("Profile '" + NameToString(groups[i].profileName) + "' declares conflicting bases; keeping '" + NameToString(bases[idx]) + "'.");
        }
    }
}

/** Chain is ordered self to root; false when inheritance is circular */
function LR_TryResolveProfileChain(
    profileName: name,
    profileNames: array<name>,
    bases: array<name>,
    out chain: array<name>
): bool {
    var current, baseProfile: name;
    var idx: int;

    chain.Clear();
    current = profileName;

    while (true) {
        chain.PushBack(current);

        idx = profileNames.FindFirst(current);
        baseProfile = bases[idx];
        if (baseProfile == '') return true;
        if (chain.Contains(baseProfile)) return false;

        if (profileNames.FindFirst(baseProfile) == -1) {
            LogLightRewriteXml("Profile '" + NameToString(current) + "' inherits unknown profile '" + NameToString(baseProfile) + "'.");
            return true;
        }

        current = baseProfile;
    }

    return true;
}

/** Base profile groups sort before inheritors on equal weight */
function LR_CollectProfileChainGroups(
    groups: array<CLightRewriteOverrideGroup>,
    chain: array<name>
): array<CLightRewriteOverrideGroup> {
    var result: array<CLightRewriteOverrideGroup>;
    var i, j, count: int;

    count = groups.Size();
    for (i = chain.Size() - 1; i >= 0; i -= 1) {
        for (j = 0; j < count; j += 1) {
            if (groups[j].profileName == chain[i]) result.PushBack(groups[j]);
        }
    }

    ArraySortGroupsByWeight(result);
    return result;
}
