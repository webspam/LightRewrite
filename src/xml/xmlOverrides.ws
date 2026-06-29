function LogLightRewriteXml(message: string) {
    LogChannel('LightRewriteXml', message);
}

/** Loads all override groups from all XML files */
function LoadLightRewriteOverrides(owner: CObject): array<CLightRewriteOverrideGroup> {
    var groups: array<CLightRewriteOverrideGroup>;
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
        LogLightRewriteXml("Found overrides group with weight: " + weight + ", profile: " + NameToString(profileName) + ", overrides: " + overridesNode.subNodes.Size());

        groups.PushBack(LoadLightRewriteOverrideGroup(owner, dm, overridesNode, weight, profileName));
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

    group = new CLightRewriteOverrideGroup in owner;
    group.weight = weight;
    group.profileName = profileName;
    group.filter = new CLightRewriteMatchAll in group;

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

        LogLightRewriteXml("Loaded override: " + override.displayName + " (tag=" + NameToString(override.tag) + ", rules=" + override.condition.rules.Size() + ")");
        group.overrides.PushBack(override);
    }

    return group;
}

function ParseLightRewriteMatchRules(
    dm: CDefinitionsManagerAccessor,
    node: SCustomNode,
    target: CLightRewriteMatchAll
) {
    var childNode: SCustomNode;
    var rule: CLightRewriteMatchRule;
    var group: CLightRewriteMatchAny;
    var i, count: int;

    count = node.subNodes.Size();
    for (i = 0; i < count; i += 1) {
        childNode = node.subNodes[i];

        if (childNode.nodeName == 'match') {
            rule = ParseLightRewriteMatchRule(target, dm, childNode);
            if (rule) target.rules.PushBack(rule);
        }
        else if (childNode.nodeName == 'any') {
            group = ParseLightRewriteMatchGroup(target, dm, childNode);
            if (group.rules.Size() > 0) target.rules.PushBack(group);
        }
    }
}

function ParseLightRewriteMatchGroup(
    owner: CObject,
    dm: CDefinitionsManagerAccessor,
    groupNode: SCustomNode
): CLightRewriteMatchAny {
    var group: CLightRewriteMatchAny;
    var rule: CLightRewriteMatchRule;
    var i, count: int;

    group = new CLightRewriteMatchAny in owner;

    count = groupNode.subNodes.Size();
    for (i = 0; i < count; i += 1) {
        if (groupNode.subNodes[i].nodeName != 'match') continue;
        rule = ParseLightRewriteMatchRule(group, dm, groupNode.subNodes[i]);
        if (rule) group.rules.PushBack(rule);
    }

    return group;
}

function ParseLightRewriteMatchRule(
    owner: CObject,
    dm: CDefinitionsManagerAccessor,
    matchNode: SCustomNode
): CLightRewriteMatchRule {
    var rule: CLightRewriteMatchRule;
    var strVal: string;

    if (matchNode.values.Size() == 0) return NULL;

    rule = new CLightRewriteMatchRule in owner;
    rule.matchValue = matchNode.values[0];

    if (dm.GetCustomNodeAttributeValueString(matchNode, 'type', strVal)) {
        if (strVal == "layer") rule.matchType = LR_Match_Layer;
    }

    if (dm.GetCustomNodeAttributeValueString(matchNode, 'mode', strVal)) {
        switch (strVal) {
            case "endsWith":  rule.matchMode = LR_Match_EndsWith;  break;
            case "contains":  rule.matchMode = LR_Match_Contains;  break;
            case "exact":     rule.matchMode = LR_Match_Exact;     break;
        }
    }

    return rule;
}

// Populates ILightRewriteParams fields shared by both override entries and spotlight nodes.
function ParseLightRewriteBaseParams(
    params: ILightRewriteParams,
    dm: CDefinitionsManagerAccessor,
    node: SCustomNode
) {
    var strVal: string;
    var shadowsNode, colourNode: SCustomNode;

    if (dm.GetCustomNodeAttributeValueString(node, 'enabled', strVal)) {
        params.enabled.has = true;
        params.enabled.value = (strVal != "false");
    }
    if (dm.GetCustomNodeAttributeValueString(node, 'brightness', strVal)) {
        params.brightness.has = true;
        params.brightness.value = StringToFloat(strVal, 0.f);
    }
    if (dm.GetCustomNodeAttributeValueString(node, 'radius', strVal)) {
        params.radius.has = true;
        params.radius.value = StringToFloat(strVal, 0.f);
    }
    if (dm.GetCustomNodeAttributeValueString(node, 'attenuation', strVal)) {
        params.attenuation.has = true;
        params.attenuation.value = StringToFloat(strVal, 0.f);
    }

    shadowsNode = dm.GetCustomDefinitionSubNode(node, 'shadows');
    if (dm.GetCustomNodeAttributeValueString(shadowsNode, 'fade_distance', strVal)) {
        params.shadowFadeDistance.has = true;
        params.shadowFadeDistance.value = StringToFloat(strVal, 0.f);
    }
    if (dm.GetCustomNodeAttributeValueString(shadowsNode, 'fade_range', strVal)) {
        params.shadowFadeRange.has = true;
        params.shadowFadeRange.value = StringToFloat(strVal, 0.f);
    }
    if (dm.GetCustomNodeAttributeValueString(shadowsNode, 'blend_factor', strVal)) {
        params.shadowBlendFactor.has = true;
        params.shadowBlendFactor.value = StringToFloat(strVal, 0.f);
    }
    if (dm.GetCustomNodeAttributeValueString(shadowsNode, 'casting_mode', strVal)) {
        params.castShadows.has = true;
        params.castShadows.value = LR_StringToLightShadowCastingMode(strVal);
    }

    colourNode = dm.GetCustomDefinitionSubNode(node, 'colour');
    if (dm.GetCustomNodeAttributeValueString(colourNode, 'r', strVal)) {
        params.color.has = true;
        params.color.value.Red = StringToInt(strVal, params.color.value.Red);
        dm.GetCustomNodeAttributeValueString(colourNode, 'g', strVal);
        params.color.value.Green = StringToInt(strVal, params.color.value.Green);
        dm.GetCustomNodeAttributeValueString(colourNode, 'b', strVal);
        params.color.value.Blue = StringToInt(strVal, params.color.value.Blue);
    }
}

/** Parses a <spotlight> node into a new CLightRewriteSpotlightParams. */
function ParseLightRewriteSpotlightParams(
    owner: CObject,
    dm: CDefinitionsManagerAccessor,
    spotlightNode: SCustomNode
): CLightRewriteSpotlightParams {
    var spotlight: CLightRewriteSpotlightParams;
    var offsetNode: SCustomNode;
    var strVal: string;

    spotlight = new CLightRewriteSpotlightParams in owner;

    ParseLightRewriteBaseParams(spotlight, dm, spotlightNode);
    if (dm.GetCustomNodeAttributeValueString(spotlightNode, 'innerAngle', strVal)) {
        spotlight.innerAngle.has = true;
        spotlight.innerAngle.value = StringToFloat(strVal, 0.f);
    }
    if (dm.GetCustomNodeAttributeValueString(spotlightNode, 'outerAngle', strVal)) {
        spotlight.outerAngle.has = true;
        spotlight.outerAngle.value = StringToFloat(strVal, 0.f);
    }
    if (dm.GetCustomNodeAttributeValueString(spotlightNode, 'softness', strVal)) {
        spotlight.softness.has = true;
        spotlight.softness.value = StringToFloat(strVal, 0.f);
    }
    if (dm.GetCustomNodeAttributeValueString(spotlightNode, 'spawn', strVal)) {
        spotlight.spawn = (strVal == "true");
    }

    offsetNode = dm.GetCustomDefinitionSubNode(spotlightNode, 'offset');
    if (ParseLightRewriteVector(dm, offsetNode, spotlight.offset.value)) {
        spotlight.offset.has = true;
    }

    return spotlight;
}

function ParseLightRewriteVector(
    dm: CDefinitionsManagerAccessor,
    node: SCustomNode,
    out vec: Vector
): bool {
    var x, y, z: string;

    if (!dm.GetCustomNodeAttributeValueString(node, 'x', x)) return false;

    dm.GetCustomNodeAttributeValueString(node, 'y', y);
    dm.GetCustomNodeAttributeValueString(node, 'z', z);
    vec = Vector(StringToFloat(x, 0.f), StringToFloat(y, 0.f), StringToFloat(z, 0.f));
    return true;
}

function LR_StringToLightShadowCastingMode(str: string): ELightShadowCastingMode {
    switch (str) {
        case "None":         return LSCM_None;
        case "Normal":       return LSCM_Normal;
        case "OnlyDynamic":  return LSCM_OnlyDynamic;
        case "OnlyStatic":   return LSCM_OnlyStatic;
        default:             return LSCM_None;
    }
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
