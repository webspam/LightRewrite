function LogLightRewriteXml(message: string) {
    LogChannel('LightRewriteXml', message);
}

function LoadLightRewriteOverrides(owner: CObject): array<CLightRewriteOverrideGroup> {
    var groups: array<CLightRewriteOverrideGroup>;
    var group: CLightRewriteOverrideGroup;
    var dm: CDefinitionsManagerAccessor;
    var lrNode, overridesNode: SCustomNode;
    var i, count, weight: int;
    var profileName: name;

    dm = theGame.GetDefinitionsManager();
    lrNode = dm.GetCustomDefinition('light_rewrite');

    count = lrNode.subNodes.Size();
    for (i = 0; i < count; i += 1) {
        overridesNode = lrNode.subNodes[i];
        if (overridesNode.nodeName != 'overrides') continue;

        if (!dm.GetCustomNodeAttributeValueInt(overridesNode, 'weight', weight)) {
            LogLightRewriteXml("Skipping invalid overrides group - missing weight attribute.");
            continue;
        }

        dm.GetCustomNodeAttributeValueName(overridesNode, 'profile_name', profileName);
        LogLightRewriteXml("Found overrides group with weight: " + weight + ", profile: " + profileName + ", overrides: " + overridesNode.subNodes.Size());

        group = LoadLightRewriteOverrideGroup(owner, dm, overridesNode, weight, profileName);
        if (group.overrides.Size() > 0) {
            groups.PushBack(group);
        }
    }

    ArraySortGroupsByWeight(groups);

    return groups;
}

function LoadLightRewriteOverrideGroup(
    owner: CObject,
    dm: CDefinitionsManagerAccessor,
    overridesNode: SCustomNode,
    weight: int,
    profileName: name
): CLightRewriteOverrideGroup {
    var group: CLightRewriteOverrideGroup;
    var entryNode: SCustomNode;
    var alignNode: SCustomNode;
    var override: CLightRewriteSourceParams;
    var strVal: string;
    var nameVal: name;
    var i, count: int;
    var spotlightNode: SCustomNode;
    var matchesNode: SCustomNode;
    var inheritsNode: SCustomNode;

    group = new CLightRewriteOverrideGroup in owner;
    group.weight = weight;
    group.profileName = profileName;
    group.filter = new CLightRewriteMatchAll in group;

    inheritsNode = dm.GetCustomDefinitionSubNode(overridesNode, 'inherits');
    count = inheritsNode.values.Size();
    for (i = 0; i < count; i += 1) {
        group.inherits.PushBack(inheritsNode.values[i]);
    }

    matchesNode = dm.GetCustomDefinitionSubNode(overridesNode, 'matches');
    if (matchesNode.nodeName == 'matches') {
        ParseLightRewriteMatchRules(dm, matchesNode, group.filter);
    }

    count = overridesNode.subNodes.Size();
    for (i = 0; i < count; i += 1) {
        entryNode = overridesNode.subNodes[i];
        if (entryNode.nodeName != 'override') continue;

        if (!dm.GetCustomNodeAttributeValueName(entryNode, 'tag_name', nameVal)) {
            LogLightRewriteXml("Skipping invalid override - missing tag_name attribute.");
            continue;
        }
        if (!dm.GetCustomNodeAttributeValueString(entryNode, 'label', strVal)) {
            LogLightRewriteXml("Skipping invalid override - missing label attribute.");
            continue;
        }

        override = new CLightRewriteSourceParams in group;
        override.condition = new CLightRewriteMatchAll in override;
        override.tag = nameVal;
        override.displayName = strVal;

        ParseLightRewriteBaseParams(override, dm, entryNode);
        if (dm.GetCustomNodeAttributeValueString(entryNode, 'rewriter_type', strVal)) {
            override.rewriterType.has = true;
            override.rewriterType.value = ParseLightRewriteType(strVal);
        }
        if (dm.GetCustomNodeAttributeValueString(entryNode, 'use_spotlight_colour', strVal)) {
            override.useSpotlightColor.has = true;
            override.useSpotlightColor.value = (strVal == "true");
        }
        if (dm.GetCustomNodeAttributeValueString(entryNode, 'force_single_light', strVal)) {
            override.forceSingleLight.has = true;
            override.forceSingleLight.value = (strVal == "true");
        }
        if (dm.GetCustomNodeAttributeValueString(entryNode, 'force_cast_shadows', strVal)) {
            override.forceCastShadows.has = true;
            override.forceCastShadows.value = (strVal == "true");
        }

        ParseLightRewriteMatchRules(dm, entryNode, override.condition);

        alignNode = dm.GetCustomDefinitionSubNode(entryNode, 'fire_fx_offset');
        if (ParseLightRewriteVector(dm, alignNode, override.pointLightOffset)) {
            override.alignPointLights.has = true;
            override.alignPointLights.value = true;
        }

        alignNode = dm.GetCustomDefinitionSubNode(entryNode, 'offset');
        if (ParseLightRewriteVector(dm, alignNode, override.pointLightOffsetPos.value)) {
            override.pointLightOffsetPos.has = true;
        }

        spotlightNode = dm.GetCustomDefinitionSubNode(entryNode, 'spotlight');
        if (spotlightNode.nodeName == 'spotlight') {
            override.spotlight = ParseLightRewriteSpotlightParams(override, dm, spotlightNode);
        }

        LogLightRewriteXml("Loaded override: " + override.displayName + " (tag=" + override.tag + ", rules=" + override.condition.rules.Size() + ")");
        group.overrides.PushBack(override);
    }

    return group;
}

/** Sorts override groups ascending by weight using insertion sort (stable, O(n²)). */
function ArraySortGroupsByWeight(out groups: array<CLightRewriteOverrideGroup>) {
    var i, j, keyWeight, count: int;
    var keyGroup: CLightRewriteOverrideGroup;

    count = groups.Size();
    for (i = 1; i < count; i += 1) {
        keyGroup = groups[i];
        keyWeight = keyGroup.weight;
        j = i - 1;

        while (j >= 0 && groups[j].weight > keyWeight) {
            groups[j + 1] = groups[j];
            j -= 1;
        }

        groups[j + 1] = keyGroup;
    }
}
