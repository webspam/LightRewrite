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

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'enabled', strVal)) {
            params.hasEnabled = true;
            params.enabled    = (strVal != "false");
        }

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'use_spotlight_color', strVal)) {
            params.hasUseSpotlightColor = true;
            params.useSpotlightColor    = (strVal == "true");
        }

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'brightness', strVal)) {
            params.hasBrightness = true;
            params.brightness    = StringToFloat(strVal, 0.f);
        }

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'radius', strVal)) {
            params.hasRadius = true;
            params.radius    = StringToFloat(strVal, 0.f);
        }

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'attenuation', strVal)) {
            params.hasAttenuation = true;
            params.attenuation    = StringToFloat(strVal, 0.f);
        }

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'rewriter_type', strVal)) {
            params.hasRewriterType = true;
            params.rewriterType    = ParseLightRewriteType(strVal);
        }

        shadowsNode = dm.GetCustomDefinitionSubNode(entryNode, 'shadows');
        if (dm.GetCustomNodeAttributeValueString(shadowsNode, 'fade_distance', strVal)) {
            params.hasShadowFadeDistance = true;
            params.shadowFadeDistance    = StringToFloat(strVal, 0.f);
        }
        if (dm.GetCustomNodeAttributeValueString(shadowsNode, 'fade_range', strVal)) {
            params.hasShadowFadeRange = true;
            params.shadowFadeRange    = StringToFloat(strVal, 0.f);
        }
        if (dm.GetCustomNodeAttributeValueString(shadowsNode, 'blend_factor', strVal)) {
            params.hasShadowBlendFactor = true;
            params.shadowBlendFactor    = StringToFloat(strVal, 0.f);
        }

        colourNode = dm.GetCustomDefinitionSubNode(entryNode, 'colour');
        if (dm.GetCustomNodeAttributeValueString(colourNode, 'r', strVal)) {
            params.hasColour   = true;
            params.color.Red   = StringToInt(strVal, params.color.Red);
            dm.GetCustomNodeAttributeValueString(colourNode, 'g', strVal);
            params.color.Green = StringToInt(strVal, params.color.Green);
            dm.GetCustomNodeAttributeValueString(colourNode, 'b', strVal);
            params.color.Blue  = StringToInt(strVal, params.color.Blue);
        }

        alignNode = dm.GetCustomDefinitionSubNode(entryNode, 'align_point_lights');
        if (dm.GetCustomNodeAttributeValueString(alignNode, 'x', strVal)) {
            params.hasAlignPointLights = true;
            params.alignPointLights    = true;
            params.pointLightOffset.X  = StringToFloat(strVal, 0.f);
            dm.GetCustomNodeAttributeValueString(alignNode, 'y', strVal);
            params.pointLightOffset.Y  = StringToFloat(strVal, 0.f);
            dm.GetCustomNodeAttributeValueString(alignNode, 'z', strVal);
            params.pointLightOffset.Z  = StringToFloat(strVal, 0.f);
        }

        LogLightRewrite("[XmlConfig] Loaded: " + params.displayName + " (tag=" + NameToString(params.tag) + ")");
        paramsArray.PushBack(params);
    }

    return paramsArray;
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
