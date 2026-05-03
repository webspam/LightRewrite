// Loads CLightRewriteSourceParams from defaults.xml via the definitions manager.
function LoadLightRewriteParams(owner : CObject) : array<CLightRewriteSourceParams> {
    var paramsArray  : array<CLightRewriteSourceParams>;
    var dm           : CDefinitionsManagerAccessor;
    var lrNode       : SCustomNode;
    var defaultsNode : SCustomNode;
    var entryNode    : SCustomNode;
    var shadowsNode  : SCustomNode;
    var colourNode   : SCustomNode;
    var alignNode    : SCustomNode;
    var params       : CLightRewriteSourceParams;
    var i, count     : int;
    var strVal       : string;
    var nameVal      : name;

    dm           = theGame.GetDefinitionsManager();
    lrNode       = dm.GetCustomDefinition('light_rewrite');
    defaultsNode = dm.GetCustomDefinitionSubNode(lrNode, 'defaults');

    count = defaultsNode.subNodes.Size();

    for (i = 0; i < count; i += 1) {
        entryNode = defaultsNode.subNodes[i];
        params    = new CLightRewriteSourceParams in owner;

        dm.GetCustomNodeAttributeValueName(entryNode, 'tag_name', nameVal);
        params.tag = nameVal;

        dm.GetCustomNodeAttributeValueString(entryNode, 'label', strVal);
        params.displayName = strVal;

        dm.GetCustomNodeAttributeValueString(entryNode, 'enabled', strVal);
        params.enabled = (strVal == "true");

        dm.GetCustomNodeAttributeValueString(entryNode, 'use_spotlight_color', strVal);
        params.useSpotlightColor = (strVal == "true");

        dm.GetCustomNodeAttributeValueString(entryNode, 'brightness', strVal);
        params.brightness = StringToFloat(strVal, params.brightness);

        dm.GetCustomNodeAttributeValueString(entryNode, 'radius', strVal);
        params.radius = StringToFloat(strVal, params.radius);

        dm.GetCustomNodeAttributeValueString(entryNode, 'attenuation', strVal);
        params.attenuation = StringToFloat(strVal, params.attenuation);

        dm.GetCustomNodeAttributeValueString(entryNode, 'rewriter_type', strVal);
        params.rewriterType = ParseLightRewriteType(strVal);

        shadowsNode = dm.GetCustomDefinitionSubNode(entryNode, 'shadows');
        dm.GetCustomNodeAttributeValueString(shadowsNode, 'fade_distance', strVal);
        params.shadowFadeDistance = StringToFloat(strVal, params.shadowFadeDistance);
        dm.GetCustomNodeAttributeValueString(shadowsNode, 'fade_range', strVal);
        params.shadowFadeRange = StringToFloat(strVal, params.shadowFadeRange);
        dm.GetCustomNodeAttributeValueString(shadowsNode, 'blend_factor', strVal);
        params.shadowBlendFactor = StringToFloat(strVal, params.shadowBlendFactor);

        colourNode = dm.GetCustomDefinitionSubNode(entryNode, 'override_colour');
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
