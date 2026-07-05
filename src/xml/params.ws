/** Populates ILightRewriteParams fields shared by both override entries and spotlight nodes. */
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

function ParseLightRewritePerLightNodes(
    override: CLightRewriteSourceParams,
    dm: CDefinitionsManagerAccessor,
    entryNode: SCustomNode
) {
    var childNode: SCustomNode;
    var spotParams: CLightRewriteSpotlightParams;
    var index, i, count: int;

    count = entryNode.subNodes.Size();
    for (i = 0; i < count; i += 1) {
        childNode = entryNode.subNodes[i];

        if (childNode.nodeName == 'light') {
            if (!dm.GetCustomNodeAttributeValueInt(childNode, 'index', index)) {
                LogLightRewriteXml("Skipping invalid light element - missing index attribute.");
                continue;
            }
            ParseLightRewriteBaseParams(override.GetOrCreatePointLightParams(index), dm, childNode);
        }
        else if (childNode.nodeName == 'spotlight') {
            spotParams = ParseLightRewriteSpotlightParams(override, dm, childNode);
            if (dm.GetCustomNodeAttributeValueInt(childNode, 'index', index)) {
                spotParams.index = index;
                override.spotLights.PushBack(spotParams);
            }
            else {
                override.spotlight = spotParams;
            }
        }
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

function ParseLightRewriteType(str: string): ELightRewriteType {
    switch (str) {
        case "LRT_Candle":     return LRT_Candle;
        case "LRT_Spotlight":  return LRT_Spotlight;
        default:               return LRT_None;
    }
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
