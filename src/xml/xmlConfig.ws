function FindLightRewriteProfileNames(out profileNames : array<name>) {
    var dm : CDefinitionsManagerAccessor;
    var lrNode, overridesNode, entryNode : SCustomNode;
    var i, count : int;
    var nameVal : name;

    dm = theGame.GetDefinitionsManager();
    lrNode = dm.GetCustomDefinition('light_rewrite');

    count = lrNode.subNodes.Size();
    for (i = 0; i < count; i += 1) {
        if (
            dm.GetCustomNodeAttributeValueName(lrNode.subNodes[i], 'profile_name', nameVal) &&
            !profileNames.Contains(nameVal)
        ) {
            profileNames.PushBack(nameVal);
        }

        LogLightRewrite("[XmlConfig] Found profile: " + NameToString(nameVal));
    }
}

/** Loads CLightRewriteSourceParams from menu_defaults.xml via the definitions manager. */
function LoadLightRewriteParams(owner : CObject) : array<CLightRewriteSourceParams> {
    var paramsArray : array<CLightRewriteSourceParams>;
    var dm : CDefinitionsManagerAccessor;
    var lrNode, defaultsNode, entryNode, shadowsNode, colourNode, alignNode : SCustomNode;
    var params : CLightRewriteSourceParams;
    var i, count : int;
    var strVal : string;
    var nameVal : name;

    dm = theGame.GetDefinitionsManager();
    lrNode = dm.GetCustomDefinition('light_rewrite');
    defaultsNode = dm.GetCustomDefinitionSubNode(lrNode, 'menu_defaults');

    count = defaultsNode.subNodes.Size();

    for (i = 0; i < count; i += 1) {
        entryNode = defaultsNode.subNodes[i];
        params = new CLightRewriteSourceParams in owner;

        dm.GetCustomNodeAttributeValueName(entryNode, 'tag_name', nameVal);
        params.tag = nameVal;

        dm.GetCustomNodeAttributeValueString(entryNode, 'label', strVal);
        params.displayName = strVal;

        dm.GetCustomNodeAttributeValueString(entryNode, 'enabled', strVal);
        params.enabled = (strVal != "false");

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'use_spotlight_color', strVal)) {
            params.useSpotlightColor = (strVal == "true");
        }

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'brightness', strVal)) {
            params.brightness = StringToFloat(strVal, 0.f);
        }

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'radius', strVal)) {
            params.radius = StringToFloat(strVal, 0.f);
        }

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'attenuation', strVal)) {
            params.attenuation = StringToFloat(strVal, 0.f);
        }

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'rewriter_type', strVal)) {
            params.rewriterType = ParseLightRewriteType(strVal);
        }

        shadowsNode = dm.GetCustomDefinitionSubNode(entryNode, 'shadows');
        if (dm.GetCustomNodeAttributeValueString(shadowsNode, 'fade_distance', strVal)) {
            params.shadowFadeDistance = StringToFloat(strVal, 0.f);
        }
        if (dm.GetCustomNodeAttributeValueString(shadowsNode, 'fade_range', strVal)) {
            params.shadowFadeRange = StringToFloat(strVal, 0.f);
        }
        if (dm.GetCustomNodeAttributeValueString(shadowsNode, 'blend_factor', strVal)) {
            params.shadowBlendFactor = StringToFloat(strVal, 0.f);
        }

        colourNode = dm.GetCustomDefinitionSubNode(entryNode, 'colour');
        if (dm.GetCustomNodeAttributeValueString(colourNode, 'r', strVal)) {
            params.shouldOverrideColour = true;
            params.color.Red = StringToInt(strVal, params.color.Red);
            dm.GetCustomNodeAttributeValueString(colourNode, 'g', strVal);
            params.color.Green = StringToInt(strVal, params.color.Green);
            dm.GetCustomNodeAttributeValueString(colourNode, 'b', strVal);
            params.color.Blue = StringToInt(strVal, params.color.Blue);
        }

        alignNode = dm.GetCustomDefinitionSubNode(entryNode, 'align_point_lights');
        if (dm.GetCustomNodeAttributeValueString(alignNode, 'x', strVal)) {
            params.alignPointLights = true;
            params.pointLightOffset.X = StringToFloat(strVal, 0.f);
            dm.GetCustomNodeAttributeValueString(alignNode, 'y', strVal);
            params.pointLightOffset.Y = StringToFloat(strVal, 0.f);
            dm.GetCustomNodeAttributeValueString(alignNode, 'z', strVal);
            params.pointLightOffset.Z = StringToFloat(strVal, 0.f);
        }

        LogLightRewrite("[XmlConfig] Loaded: " + params.displayName + " (tag=" + NameToString(params.tag) + ")");
        paramsArray.PushBack(params);
    }

    return paramsArray;
}

/** Parses the match rules for a single override. */
function ParseLightRewriteMatchRules(
    override : CLightRewriteOverrideParams,
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

/** Loads all overrides from all XML files */
function LoadLightRewriteOverrides(owner : CObject) : array<CLightRewriteOverrideParams> {
    var overrides : array<CLightRewriteOverrideParams>;
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
    owner         : CObject,
    dm            : CDefinitionsManagerAccessor,
    overridesNode : SCustomNode,
    out overrides : array<CLightRewriteOverrideParams>
) {
    var entryNode  : SCustomNode;
    var colourNode : SCustomNode;
    var override   : CLightRewriteOverrideParams;
    var strVal     : string;
    var nameVal    : name;
    var i, count   : int;

    count = overridesNode.subNodes.Size();
    for (i = 0; i < count; i += 1) {
        entryNode = overridesNode.subNodes[i];
        override  = new CLightRewriteOverrideParams in owner;

        dm.GetCustomNodeAttributeValueName(entryNode, 'tag_name', nameVal);
        override.tag = nameVal;

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'label', strVal)) {
            override.displayName = strVal;
        }

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'brightness', strVal)) {
            override.hasBrightness = true;
            override.brightness    = StringToFloat(strVal, 0.f);
        }

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'radius', strVal)) {
            override.hasRadius = true;
            override.radius    = StringToFloat(strVal, 0.f);
        }

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'attenuation', strVal)) {
            override.hasAttenuation = true;
            override.attenuation    = StringToFloat(strVal, 0.f);
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

function ParseLightRewriteType(str : string) : ELightRewriteType {
    switch (str) {
        case "LRT_Candle":     return LRT_Candle;
        case "LRT_Torch":      return LRT_Torch;
        case "LRT_Brazier":    return LRT_Brazier;
        case "LRT_Candelabra": return LRT_Candelabra;
        case "LRT_Campfire":   return LRT_Campfire;
        case "LRT_Chandelier": return LRT_Chandelier;
        default:               return LRT_None;
    }
}
