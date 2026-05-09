function LogLightRewriteXml(message : string) {
    LogChannel('LightRewriteXml', message);
}

/** Loads all overrides from all XML files */
function LoadLightRewriteOverrides(owner : CObject) : array<CLightRewriteSourceParams> {
    var overrides : array<CLightRewriteSourceParams>;
    var dm : CDefinitionsManagerAccessor;
    var lrNode, overridesNode : SCustomNode;
    var i, count, weight : int;
    var profileName : name;

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
    owner : CObject,
    dm : CDefinitionsManagerAccessor,
    overridesNode : SCustomNode,
    out overrides : array<CLightRewriteSourceParams>,
    weight : int,
    profileName : name
) {
    var entryNode : SCustomNode;
    var shadowsNode : SCustomNode;
    var colourNode : SCustomNode;
    var alignNode : SCustomNode;
    var override : CLightRewriteSourceParams;
    var strVal : string;
    var nameVal : name;
    var i, count : int;
    var spotlightNode : SCustomNode;

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

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'enabled', strVal)) {
            override.hasEnabled = true;
            override.enabled = (strVal != "false");
        }
        if (dm.GetCustomNodeAttributeValueString(entryNode, 'rewriter_type', strVal)) {
            override.hasRewriterType = true;
            override.rewriterType = ParseLightRewriteType(strVal);
        }
        if (dm.GetCustomNodeAttributeValueString(entryNode, 'use_spotlight_color', strVal)) {
            override.hasUseSpotlightColor = true;
            override.useSpotlightColor = (strVal == "true");
        }
        if (dm.GetCustomNodeAttributeValueString(entryNode, 'brightness', strVal)) {
            override.hasBrightness = true;
            override.brightness = StringToFloat(strVal, 0.f);
        }
        if (dm.GetCustomNodeAttributeValueString(entryNode, 'radius', strVal)) {
            override.hasRadius = true;
            override.radius = StringToFloat(strVal, 0.f);
        }
        if (dm.GetCustomNodeAttributeValueString(entryNode, 'attenuation', strVal)) {
            override.hasAttenuation = true;
            override.attenuation = StringToFloat(strVal, 0.f);
        }

        ParseLightRewriteMatchRules(override, dm, entryNode);

        shadowsNode = dm.GetCustomDefinitionSubNode(entryNode, 'shadows');
        if (dm.GetCustomNodeAttributeValueString(shadowsNode, 'fade_distance', strVal)) {
            override.hasShadowFadeDistance = true;
            override.shadowFadeDistance = StringToFloat(strVal, 0.f);
        }
        if (dm.GetCustomNodeAttributeValueString(shadowsNode, 'fade_range', strVal)) {
            override.hasShadowFadeRange = true;
            override.shadowFadeRange = StringToFloat(strVal, 0.f);
        }
        if (dm.GetCustomNodeAttributeValueString(shadowsNode, 'blend_factor', strVal)) {
            override.hasShadowBlendFactor = true;
            override.shadowBlendFactor = StringToFloat(strVal, 0.f);
        }

        colourNode = dm.GetCustomDefinitionSubNode(entryNode, 'colour');
        if (dm.GetCustomNodeAttributeValueString(colourNode, 'r', strVal)) {
            override.hasColour = true;
            override.color.Red = StringToInt(strVal, override.color.Red);
            dm.GetCustomNodeAttributeValueString(colourNode, 'g', strVal);
            override.color.Green = StringToInt(strVal, override.color.Green);
            dm.GetCustomNodeAttributeValueString(colourNode, 'b', strVal);
            override.color.Blue = StringToInt(strVal, override.color.Blue);
        }

        alignNode = dm.GetCustomDefinitionSubNode(entryNode, 'align_point_lights');
        if (dm.GetCustomNodeAttributeValueString(alignNode, 'x', strVal)) {
            override.hasAlignPointLights = true;
            override.alignPointLights = true;
            override.pointLightOffset.X = StringToFloat(strVal, 0.f);
            dm.GetCustomNodeAttributeValueString(alignNode, 'y', strVal);
            override.pointLightOffset.Y = StringToFloat(strVal, 0.f);
            dm.GetCustomNodeAttributeValueString(alignNode, 'z', strVal);
            override.pointLightOffset.Z = StringToFloat(strVal, 0.f);
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
    override : CLightRewriteSourceParams,
    dm : CDefinitionsManagerAccessor,
    entryNode : SCustomNode
) {
    var matchNode : SCustomNode;
    var rule : CLightRewriteMatchRule;
    var i, count : int;
    var strVal : string;

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
                case "endsWith": rule.matchMode = LR_Match_EndsWith; break;
                case "contains": rule.matchMode = LR_Match_Contains; break;
                case "exact": rule.matchMode = LR_Match_Exact; break;
            }
        }

        override.matchRules.PushBack(rule);
    }
}

/** Parses a <spotlight> node into a new CLightRewriteSpotlightParams. */
function ParseLightRewriteSpotlightParams(
    owner : CObject,
    dm : CDefinitionsManagerAccessor,
    spotlightNode : SCustomNode
) : CLightRewriteSpotlightParams {
    var spotlight : CLightRewriteSpotlightParams;
    var shadowsNode, colourNode, offsetNode : SCustomNode;
    var strVal : string;

    spotlight = new CLightRewriteSpotlightParams in owner;

    if (dm.GetCustomNodeAttributeValueString(spotlightNode, 'enabled', strVal)) {
        spotlight.hasEnabled = true;
        spotlight.enabled = (strVal != "false");
    }
    if (dm.GetCustomNodeAttributeValueString(spotlightNode, 'brightness', strVal)) {
        spotlight.hasBrightness = true;
        spotlight.brightness = StringToFloat(strVal, 0.f);
    }
    if (dm.GetCustomNodeAttributeValueString(spotlightNode, 'radius', strVal)) {
        spotlight.hasRadius = true;
        spotlight.radius = StringToFloat(strVal, 0.f);
    }
    if (dm.GetCustomNodeAttributeValueString(spotlightNode, 'attenuation', strVal)) {
        spotlight.hasAttenuation = true;
        spotlight.attenuation = StringToFloat(strVal, 0.f);
    }
    if (dm.GetCustomNodeAttributeValueString(spotlightNode, 'innerAngle', strVal)) {
        spotlight.hasInnerAngle = true;
        spotlight.innerAngle = StringToFloat(strVal, 0.f);
    }
    if (dm.GetCustomNodeAttributeValueString(spotlightNode, 'outerAngle', strVal)) {
        spotlight.hasOuterAngle = true;
        spotlight.outerAngle = StringToFloat(strVal, 0.f);
    }
    if (dm.GetCustomNodeAttributeValueString(spotlightNode, 'softness', strVal)) {
        spotlight.hasSoftness = true;
        spotlight.softness = StringToFloat(strVal, 0.f);
    }

    shadowsNode = dm.GetCustomDefinitionSubNode(spotlightNode, 'shadows');
    if (dm.GetCustomNodeAttributeValueString(shadowsNode, 'fade_distance', strVal)) {
        spotlight.hasShadowFadeDistance = true;
        spotlight.shadowFadeDistance = StringToFloat(strVal, 0.f);
    }
    if (dm.GetCustomNodeAttributeValueString(shadowsNode, 'fade_range', strVal)) {
        spotlight.hasShadowFadeRange = true;
        spotlight.shadowFadeRange = StringToFloat(strVal, 0.f);
    }
    if (dm.GetCustomNodeAttributeValueString(shadowsNode, 'blend_factor', strVal)) {
        spotlight.hasShadowBlendFactor = true;
        spotlight.shadowBlendFactor = StringToFloat(strVal, 0.f);
    }

    colourNode = dm.GetCustomDefinitionSubNode(spotlightNode, 'colour');
    if (dm.GetCustomNodeAttributeValueString(colourNode, 'r', strVal)) {
        spotlight.hasColour = true;
        spotlight.color.Red = StringToInt(strVal, spotlight.color.Red);
        dm.GetCustomNodeAttributeValueString(colourNode, 'g', strVal);
        spotlight.color.Green = StringToInt(strVal, spotlight.color.Green);
        dm.GetCustomNodeAttributeValueString(colourNode, 'b', strVal);
        spotlight.color.Blue = StringToInt(strVal, spotlight.color.Blue);
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

/** Sorts overrides ascending by weight using insertion sort (stable, O(n²)). */
function ArraySortOverridesByWeight(out overrides : array<CLightRewriteSourceParams>) {
    var i, j, keyWeight, count : int;
    var keyOverride : CLightRewriteSourceParams;

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
