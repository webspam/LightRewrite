function LogLightRewriteXml(message: string) {
    LogChannel('LightRewriteXml', message);
}

/** Loads all overrides from all XML files */
function LoadLightRewriteOverrides(owner: CObject): array<CLightRewriteSourceParams> {
    var overrides: array<CLightRewriteSourceParams>;
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

        LoadLightRewriteOverridesGroup(owner, dm, overridesNode, overrides, weight, profileName);
    }

    ArraySortOverridesByWeight(overrides);

    return overrides;
}

function LoadLightRewriteOverridesGroup(
    owner: CObject,
    dm: CDefinitionsManagerAccessor,
    overridesNode: SCustomNode,
    out overrides: array<CLightRewriteSourceParams>,
    weight: int,
    profileName: name
) {
    var entryNode: SCustomNode;
    var alignNode: SCustomNode;
    var override: CLightRewriteSourceParams;
    var strVal: string;
    var nameVal: name;
    var i, count: int;
    var spotlightNode: SCustomNode;

    count = overridesNode.subNodes.Size();
    for (i = 0; i < count; i += 1) {
        entryNode = overridesNode.subNodes[i];
        override = new CLightRewriteSourceParams in owner;
        override.weight = weight;
        override.profileName = profileName;

        if (!dm.GetCustomNodeAttributeValueName(entryNode, 'tag_name', nameVal)) {
            LogLightRewriteXml("Skipping invalid override - missing tag_name attribute.");
            continue;
        }
        override.tag = nameVal;

        if (!dm.GetCustomNodeAttributeValueString(entryNode, 'label', strVal)) {
            LogLightRewriteXml("Skipping invalid override - missing label attribute.");
            continue;
        }
        override.displayName = strVal;

        ParseLightRewriteBaseParams(override, dm, entryNode);
        if (dm.GetCustomNodeAttributeValueString(entryNode, 'rewriter_type', strVal)) {
            override.hasRewriterType = true;
            override.rewriterType = ParseLightRewriteType(strVal);
        }
        if (dm.GetCustomNodeAttributeValueString(entryNode, 'use_spotlight_color', strVal)) {
            override.useSpotlightColor.has = true;
            override.useSpotlightColor.value = (strVal == "true");
        }

        ParseLightRewriteMatchRules(override, dm, entryNode);

        alignNode = dm.GetCustomDefinitionSubNode(entryNode, 'fire_fx_offset');
        if (dm.GetCustomNodeAttributeValueString(alignNode, 'x', strVal)) {
            override.hasAlignPointLights = true;
            override.alignPointLights = true;
            override.pointLightOffset.X = StringToFloat(strVal, 0.f);
            dm.GetCustomNodeAttributeValueString(alignNode, 'y', strVal);
            override.pointLightOffset.Y = StringToFloat(strVal, 0.f);
            dm.GetCustomNodeAttributeValueString(alignNode, 'z', strVal);
            override.pointLightOffset.Z = StringToFloat(strVal, 0.f);
        }

        alignNode = dm.GetCustomDefinitionSubNode(entryNode, 'offset');
        if (dm.GetCustomNodeAttributeValueString(alignNode, 'x', strVal)) {
            override.hasPointLightOffset = true;
            override.pointLightOffsetPos.X = StringToFloat(strVal, 0.f);
            dm.GetCustomNodeAttributeValueString(alignNode, 'y', strVal);
            override.pointLightOffsetPos.Y = StringToFloat(strVal, 0.f);
            dm.GetCustomNodeAttributeValueString(alignNode, 'z', strVal);
            override.pointLightOffsetPos.Z = StringToFloat(strVal, 0.f);
        }

        spotlightNode = dm.GetCustomDefinitionSubNode(entryNode, 'spotlight');
        if (spotlightNode.nodeName == 'spotlight') {
            override.spotlight = ParseLightRewriteSpotlightParams(owner, dm, spotlightNode);
        }

        LogLightRewriteXml("Loaded override: " + override.displayName + " (tag=" + NameToString(override.tag) + ", rules=" + override.matchRules.Size() + ")");
        overrides.PushBack(override);
    }
}

/** Parses the match rules for a single override. */
function ParseLightRewriteMatchRules(
    override: CLightRewriteSourceParams,
    dm: CDefinitionsManagerAccessor,
    entryNode: SCustomNode
) {
    var matchNode: SCustomNode;
    var rule: CLightRewriteMatchRule;
    var i, count: int;
    var strVal: string;

    count = entryNode.subNodes.Size();
    for (i = 0; i < count; i += 1) {
        matchNode = entryNode.subNodes[i];

        if (matchNode.nodeName != 'match') continue;
        if (matchNode.values.Size() == 0) continue;

        rule = new CLightRewriteMatchRule in override;
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

        override.matchRules.PushBack(rule);
    }
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
        params.hasCastShadows = true;
        params.castShadows = LR_StringToLightShadowCastingMode(strVal);
    }

    colourNode = dm.GetCustomDefinitionSubNode(node, 'colour');
    if (dm.GetCustomNodeAttributeValueString(colourNode, 'r', strVal)) {
        params.hasColour = true;
        params.color.Red = StringToInt(strVal, params.color.Red);
        dm.GetCustomNodeAttributeValueString(colourNode, 'g', strVal);
        params.color.Green = StringToInt(strVal, params.color.Green);
        dm.GetCustomNodeAttributeValueString(colourNode, 'b', strVal);
        params.color.Blue = StringToInt(strVal, params.color.Blue);
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

    offsetNode = dm.GetCustomDefinitionSubNode(spotlightNode, 'offset');
    if (dm.GetCustomNodeAttributeValueString(offsetNode, 'x', strVal)) {
        spotlight.hasOffset = true;
        spotlight.offset.X = StringToFloat(strVal, 0.f);
        dm.GetCustomNodeAttributeValueString(offsetNode, 'y', strVal);
        spotlight.offset.Y = StringToFloat(strVal, 0.f);
        dm.GetCustomNodeAttributeValueString(offsetNode, 'z', strVal);
        spotlight.offset.Z = StringToFloat(strVal, 0.f);
    }

    return spotlight;
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

/** Sorts overrides ascending by weight using insertion sort (stable, O(n²)). */
function ArraySortOverridesByWeight(out overrides: array<CLightRewriteSourceParams>) {
    var i, j, keyWeight, count: int;
    var keyOverride: CLightRewriteSourceParams;

    count = overrides.Size();
    for (i = 1; i < count; i += 1) {
        keyOverride = overrides[i];
        keyWeight = keyOverride.weight;
        j = i - 1;

        while (j >= 0 && overrides[j].weight > keyWeight) {
            overrides[j + 1] = overrides[j];
            j -= 1;
        }

        overrides[j + 1] = keyOverride;
    }
}
