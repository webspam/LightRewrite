function LogLightRewriteXml(message : string) {
    LogChannel('LightRewriteXml', message);
}

/** Loads all overrides from all XML files */
function LoadLightRewriteOverrides(owner : CObject) : array<CLightRewriteSourceParams> {
    var overrides : array<CLightRewriteSourceParams>;
    var dm : CDefinitionsManagerAccessor;
    var lrNode, overridesNode : SCustomNode;
    var i, count, weight : int;

    dm = theGame.GetDefinitionsManager();
    lrNode = dm.GetCustomDefinition('light_rewrite');

    count = lrNode.subNodes.Size();
    for (i = 0; i < count; i += 1) {
        overridesNode = lrNode.subNodes[i];
        if (overridesNode.nodeName != 'overrides') continue;

        if (!dm.GetCustomNodeAttributeValueInt(overridesNode, 'weight', weight)) {
            LogLightRewriteXml("Skipping invalid overrides group - missing weight attribute.");
            continue;
        } else {
            LogLightRewriteXml("Found overrides group with weight: " + weight + ", overrides: " + overridesNode.subNodes.Size());
        }
   
        LoadLightRewriteOverridesGroup(owner, dm, overridesNode, overrides, weight);
    }

    ArraySortOverridesByWeight(overrides);

    return overrides;
}

function LoadLightRewriteOverridesGroup(
    owner : CObject,
    dm : CDefinitionsManagerAccessor,
    overridesNode : SCustomNode,
    out overrides : array<CLightRewriteSourceParams>,
    weight : int
) {
    var entryNode : SCustomNode;
    var shadowsNode : SCustomNode;
    var colourNode : SCustomNode;
    var alignNode : SCustomNode;
    var override : CLightRewriteSourceParams;
    var strVal : string;
    var nameVal : name;
    var i, count : int;

    count = overridesNode.subNodes.Size();
    for (i = 0; i < count; i += 1) {
        entryNode = overridesNode.subNodes[i];
        override = new CLightRewriteSourceParams in owner;
        override.weight = weight;

        if (!dm.GetCustomNodeAttributeValueName(entryNode, 'tag_name', nameVal)) {
            LogLightRewriteXml("Skipping invalid override - missing tag_name attribute.");
            continue;
        }
        override.tag = nameVal;

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'label', strVal)) {
            override.displayName = strVal;
        }

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

        if (matchNode.nodeName != 'match') {
            continue;
        }

        if (matchNode.values.Size() == 0) {
            continue;
        }

        rule = new CLightRewriteMatchRule in override;
        rule.matchValue = matchNode.values[0];

        if (dm.GetCustomNodeAttributeValueString(matchNode, 'type', strVal)) {
            switch (strVal) {
                case "layer": rule.matchType = LR_Match_Layer; break;
            }
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
