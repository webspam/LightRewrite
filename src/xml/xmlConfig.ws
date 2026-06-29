function FindLightRewriteProfileNames(out profileNames: array<name>) {
    var dm: CDefinitionsManagerAccessor;
    var lrNode, overridesNode, entryNode: SCustomNode;
    var i, count: int;
    var nameVal: name;

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
function LoadLightRewriteParams(owner: CObject): array<CLightRewriteSourceParams> {
    var paramsArray: array<CLightRewriteSourceParams>;
    var dm: CDefinitionsManagerAccessor;
    var lrNode, defaultsNode, entryNode, shadowsNode, colourNode, alignNode: SCustomNode;
    var params: CLightRewriteSourceParams;
    var i, count: int;
    var strVal: string;
    var nameVal: name;

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
            params.enabled.has = true;
            params.enabled.value = (strVal != "false");
        }

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'use_spotlight_colour', strVal)) {
            params.useSpotlightColor.has = true;
            params.useSpotlightColor.value = (strVal == "true");
        }

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'brightness', strVal)) {
            params.brightness.has = true;
            params.brightness.value = StringToFloat(strVal, 0.f);
        }

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'radius', strVal)) {
            params.radius.has = true;
            params.radius.value = StringToFloat(strVal, 0.f);
        }

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'attenuation', strVal)) {
            params.attenuation.has = true;
            params.attenuation.value = StringToFloat(strVal, 0.f);
        }

        if (dm.GetCustomNodeAttributeValueString(entryNode, 'rewriter_type', strVal)) {
            params.rewriterType.has = true;
            params.rewriterType.value = ParseLightRewriteType(strVal);
        }

        shadowsNode = dm.GetCustomDefinitionSubNode(entryNode, 'shadows');
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

        colourNode = dm.GetCustomDefinitionSubNode(entryNode, 'colour');
        if (dm.GetCustomNodeAttributeValueString(colourNode, 'r', strVal)) {
            params.color.has = true;
            params.color.value.Red = StringToInt(strVal, params.color.value.Red);
            dm.GetCustomNodeAttributeValueString(colourNode, 'g', strVal);
            params.color.value.Green = StringToInt(strVal, params.color.value.Green);
            dm.GetCustomNodeAttributeValueString(colourNode, 'b', strVal);
            params.color.value.Blue = StringToInt(strVal, params.color.value.Blue);
        }

        alignNode = dm.GetCustomDefinitionSubNode(entryNode, 'fire_fx_offset');
        if (ParseLightRewriteVector(dm, alignNode, params.pointLightOffset)) {
            params.alignPointLights.has = true;
            params.alignPointLights.value = true;
        }

        alignNode = dm.GetCustomDefinitionSubNode(entryNode, 'offset');
        if (ParseLightRewriteVector(dm, alignNode, params.pointLightOffsetPos.value)) {
            params.pointLightOffsetPos.has = true;
        }

        LogLightRewrite("[XmlConfig] Loaded: " + params.displayName + " (tag=" + NameToString(params.tag) + ")");
        paramsArray.PushBack(params);
    }

    return paramsArray;
}

function ParseLightRewriteType(str: string): ELightRewriteType {
    switch (str) {
        case "LRT_Candle":      return LRT_Candle;
        case "LRT_Spotlight":   return LRT_Spotlight;
        case "LRT_Torch":       return LRT_Torch;
        case "LRT_Brazier":     return LRT_Brazier;
        case "LRT_Candelabra":  return LRT_Candelabra;
        case "LRT_Campfire":    return LRT_Campfire;
        case "LRT_Chandelier":  return LRT_Chandelier;
        default:                return LRT_None;
    }
}
