/** Populates ILightRewriteParams fields shared by both override entries and spotlight nodes. */
function ParseLightRewriteBaseParams(
    params: ILightRewriteParams,
    dm: CDefinitionsManagerAccessor,
    node: SCustomNode
) {
    var strVal: string;
    var shadowsNode, colourNode, offsetNode: SCustomNode;

    if (dm.GetCustomNodeAttributeValueString(node, 'enabled', strVal)) {
        params.enabled.has = true;
        params.enabled.value = (strVal != "false");
    }

    params.brightness = ParseLightRewriteClampedFloat(
        params,
        dm,
        node,
        'brightness',
        'min_brightness',
        'max_brightness'
    );
    params.radius = ParseLightRewriteClampedFloat(
        params,
        dm,
        node,
        'radius',
        'min_radius',
        'max_radius'
    );
    params.attenuation = ParseLightRewriteClampedFloat(
        params,
        dm,
        node,
        'attenuation',
        'min_attenuation',
        'max_attenuation'
    );
    params.autoHideDistance = ParseLightRewriteClampedFloat(
        params,
        dm,
        node,
        'auto_hide_distance',
        'min_auto_hide_distance',
        'max_auto_hide_distance'
    );
    params.autoHideRange = ParseLightRewriteClampedFloat(
        params,
        dm,
        node,
        'auto_hide_range',
        'min_auto_hide_range',
        'max_auto_hide_range'
    );

    shadowsNode = dm.GetCustomDefinitionSubNode(node, 'shadows');
    params.shadowFadeDistance = ParseLightRewriteClampedFloat(
        params,
        dm,
        shadowsNode,
        'fade_distance',
        'min_fade_distance',
        'max_fade_distance'
    );
    params.shadowFadeRange = ParseLightRewriteClampedFloat(
        params,
        dm,
        shadowsNode,
        'fade_range',
        'min_fade_range',
        'max_fade_range'
    );
    if (dm.GetCustomNodeAttributeValueString(shadowsNode, 'blend_factor', strVal)) {
        params.shadowBlendFactor.has = true;
        params.shadowBlendFactor.value = StringToFloat(strVal, 0.f);
    }
    if (dm.GetCustomNodeAttributeValueString(shadowsNode, 'casting_mode', strVal)) {
        params.castShadows.has = true;
        params.castShadows.value = LR_StringToLightShadowCastingMode(strVal);
    }

    params.usageMask = LR_MergeUsageMaskEdit(
        params.usageMask,
        ParseLightRewriteUsageMask(dm, dm.GetCustomDefinitionSubNode(node, 'lum'))
    );

    colourNode = dm.GetCustomDefinitionSubNode(node, 'colour');
    if (dm.GetCustomNodeAttributeValueString(colourNode, 'r', strVal)) {
        params.color.has = true;
        params.color.value.Red = StringToInt(strVal, params.color.value.Red);
        dm.GetCustomNodeAttributeValueString(colourNode, 'g', strVal);
        params.color.value.Green = StringToInt(strVal, params.color.value.Green);
        dm.GetCustomNodeAttributeValueString(colourNode, 'b', strVal);
        params.color.value.Blue = StringToInt(strVal, params.color.value.Blue);
    }

    offsetNode = dm.GetCustomDefinitionSubNode(node, 'offset');
    if (ParseLightRewriteVector(dm, offsetNode, params.offset.value)) {
        params.offset.has = true;
    }
}

function ParseLightRewriteUsageMask(
    dm: CDefinitionsManagerAccessor,
    lumNode: SCustomNode
): SLightRewriteUsageMaskEdit {
    var edit: SLightRewriteUsageMaskEdit;

    ParseLightRewriteUsageFlag(dm, lumNode, 'exclude_scene', LRLUM_ExcludeFromSceneRender, edit);
    ParseLightRewriteUsageFlag(dm, lumNode, 'env_probe', LRLUM_RenderToEnvProbe, edit);
    ParseLightRewriteUsageFlag(dm, lumNode, 'interior', LRLUM_InteriorOnly, edit);
    ParseLightRewriteUsageFlag(dm, lumNode, 'exterior', LRLUM_ExteriorOnly, edit);
    return edit;
}

function ParseLightRewriteUsageFlag(
    dm: CDefinitionsManagerAccessor,
    lumNode: SCustomNode,
    attribute: name,
    flag: ELightRewriteUsageMask,
    out edit: SLightRewriteUsageMaskEdit
) {
    var strVal: string;

    if (!dm.GetCustomNodeAttributeValueString(lumNode, attribute, strVal)) return;

    if (strVal == "true" || strVal == "1") {
        edit.setBits = edit.setBits | (int)flag;
    }
    else {
        edit.clearBits = edit.clearBits | (int)flag;
    }
}

function ParseLightRewriteClampedFloat(
    owner: CObject,
    dm: CDefinitionsManagerAccessor,
    node: SCustomNode,
    valueAttribute: name,
    minAttribute: name,
    maxAttribute: name
): CLightRewriteClampedFloat {
    var parsed: CLightRewriteClampedFloat;
    var valueStr, minStr, maxStr: string;
    var hasValue: bool = dm.GetCustomNodeAttributeValueString(node, valueAttribute, valueStr);
    var hasMin: bool = dm.GetCustomNodeAttributeValueString(node, minAttribute, minStr);
    var hasMax: bool = dm.GetCustomNodeAttributeValueString(node, maxAttribute, maxStr);

    if (!hasValue && !hasMin && !hasMax) return NULL;

    parsed = new CLightRewriteClampedFloat in owner;
    parsed.min.has = hasMin;
    parsed.min.value = StringToFloat(minStr, 0.f);
    parsed.max.has = hasMax;
    parsed.max.value = StringToFloat(maxStr, 0.f);

    if (hasMin && hasMax && parsed.min.value > parsed.max.value) {
        LogLightRewriteXml(
            NameToString(minAttribute) + " exceeds " + NameToString(maxAttribute) + "; max wins."
        );
    }
    if (hasValue) {
        parsed.SetClampedValue(StringToFloat(valueStr, 0.f));
    }
    return parsed;
}

function ParseLightRewritePerLightNodes(
    override: CLightRewriteOverride,
    dm: CDefinitionsManagerAccessor,
    entryNode: SCustomNode
) {
    var childNode: SCustomNode;
    var spotParams: CLightRewriteSpotlightParams;
    var pointParams: CLightRewriteComponentLightParams;
    var index, i, count: int;

    count = entryNode.subNodes.Size();
    for (i = 0; i < count; i += 1) {
        childNode = entryNode.subNodes[i];

        if (childNode.nodeName == 'light') {
            if (!dm.GetCustomNodeAttributeValueInt(childNode, 'index', index)) {
                LogLightRewriteXml("Skipping invalid light element - missing index attribute.");
                continue;
            }
            pointParams = override.GetOrCreatePointLightParams(index);
            ParseLightRewriteBaseParams(pointParams, dm, childNode);
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
    if (ParseLightRewriteEulerAngles(
        dm,
        dm.GetCustomDefinitionSubNode(spotlightNode, 'rotation'),
        spotlight.rotation.value
    )) {
        spotlight.rotation.has = true;
    }

    return spotlight;
}

function ParseLightRewriteEulerAngles(
    dm: CDefinitionsManagerAccessor,
    node: SCustomNode,
    out angles: EulerAngles
): bool {
    var pitch, yaw, roll: string;

    if (!dm.GetCustomNodeAttributeValueString(node, 'pitch', pitch)) return false;

    dm.GetCustomNodeAttributeValueString(node, 'yaw', yaw);
    dm.GetCustomNodeAttributeValueString(node, 'roll', roll);
    angles = EulerAngles(
        StringToFloat(pitch, 0.f),
        StringToFloat(yaw, 0.f),
        StringToFloat(roll, 0.f)
    );
    return true;
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
        case "LRT_Candle":   return LRT_Candle;
        case "LRT_FxAlign":  return LRT_FxAlign;
        default:             return LRT_None;
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

function LR_LightShadowCastingModeToString(mode: ELightShadowCastingMode): string {
    switch (mode) {
        case LSCM_None:         return "None";
        case LSCM_Normal:       return "Normal";
        case LSCM_OnlyDynamic:  return "OnlyDynamic";
        case LSCM_OnlyStatic:   return "OnlyStatic";
        default:                return "None";
    }
}
