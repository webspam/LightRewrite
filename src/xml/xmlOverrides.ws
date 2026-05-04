/** Loads all overrides from all XML files */
function LoadLightRewriteOverrides(owner : CObject) : array<CLightRewriteSourceParams> {
    var overrides : array<CLightRewriteSourceParams>;
    var dm : CDefinitionsManagerAccessor;
    var lrNode, overridesNode : SCustomNode;
    var i, count : int;

    dm = theGame.GetDefinitionsManager();
    lrNode = dm.GetCustomDefinition('light_rewrite');

    count = lrNode.subNodes.Size();
    for (i = 0; i < count; i += 1) {
        overridesNode = lrNode.subNodes[i];
        LoadLightRewriteOverridesGroup(owner, dm, overridesNode, overrides);
    }

    return overrides;
}

function LoadLightRewriteOverridesGroup(
    owner : CObject,
    dm : CDefinitionsManagerAccessor,
    overridesNode : SCustomNode,
    out overrides : array<CLightRewriteSourceParams>
) {
    var entryNode : SCustomNode;
    var colourNode : SCustomNode;
    var override : CLightRewriteSourceParams;
    var strVal : string;
    var nameVal : name;
    var i, count : int;

    count = overridesNode.subNodes.Size();
    for (i = 0; i < count; i += 1) {
        entryNode = overridesNode.subNodes[i];
        override = new CLightRewriteSourceParams in owner;

        dm.GetCustomNodeAttributeValueName(entryNode, 'tag_name', nameVal);
        override.tag = nameVal;

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'label', strVal)) {
            override.displayName = strVal;
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

        colourNode = dm.GetCustomDefinitionSubNode(entryNode, 'colour');
        if (dm.GetCustomNodeAttributeValueString(colourNode, 'r', strVal)) {
            override.hasColour = true;
            override.color.Red = StringToInt(strVal, override.color.Red);
            dm.GetCustomNodeAttributeValueString(colourNode, 'g', strVal);
            override.color.Green = StringToInt(strVal, override.color.Green);
            dm.GetCustomNodeAttributeValueString(colourNode, 'b', strVal);
            override.color.Blue = StringToInt(strVal, override.color.Blue);
        }

        LogLightRewrite("[XmlConfig] Loaded override: " + override.displayName + " (tag=" + NameToString(override.tag) + ", rules=" + override.matchRules.Size() + ")");
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
