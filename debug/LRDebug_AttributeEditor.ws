/**
 * Owns the currently-selected attribute index and all per-attribute edit logic.
 *
 * CycleAttribute and AdjustAttribute intentionally do not call
 * LRDebug_RegenerateText on the target's oneliner — that is the caller's
 * responsibility after each operation so the call site stays explicit.
 */
class LRDebug_AttributeEditor {
    private var attrIndex : int;

    public function GetCurrentAttrId() : name {
        switch (attrIndex) {
            case 0:  return 'brightness';
            case 1:  return 'radius';
            case 2:  return 'attenuation';
            case 3:  return 'shadowFadeDistance';
            case 4:  return 'shadowFadeRange';
            case 5:  return 'shadowBlendFactor';
            case 6:  return 'useSpotlightColor';
            case 7:  return 'alignPointLights';
            case 8:  return 'alignOffsetZ';
            case 9:  return 'overrideColour';
            case 10: return 'colourR';
            case 11: return 'colourG';
            case 12: return 'colourB';
        }
        return 'unknown';
    }

    public function GetCurrentAttrLabel() : string {
        switch (GetCurrentAttrId()) {
            case 'brightness':         return "brightness";
            case 'radius':             return "radius";
            case 'attenuation':        return "attenuation";
            case 'shadowFadeDistance': return "shadow distance";
            case 'shadowFadeRange':    return "shadow range";
            case 'shadowBlendFactor':  return "shadow blend";
            case 'useSpotlightColor':  return "use spotlight colour";
            case 'alignPointLights':   return "align point lights";
            case 'alignOffsetZ':       return "align offset Z";
            case 'overrideColour':     return "override colour";
            case 'colourR':            return "colour R";
            case 'colourG':            return "colour G";
            case 'colourB':            return "colour B";
        }
        return "unknown";
    }

    public function CycleAttribute(delta : int) {
        var count : int = LRDebug_GetAttributeCount();
        if (count <= 0) return;

        attrIndex += delta;
        while (attrIndex < 0) attrIndex += count;
        while (attrIndex >= count) attrIndex -= count;
    }

    /**
     * Applies a signed adjustment to the currently selected attribute on the
     * given entity. Returns true if the adjustment was applied (caller should
     * then call LRDebug_RegenerateText on the entity's oneliner).
     */
    public function AdjustAttribute(
        sign : int,
        target : CGameplayEntity,
        accel : LRDebug_AdjustAccelerator
    ) : bool {
        var attr : name;
        var step : float;
        var accelMult : float;
        var point : CPointLightComponent;
        var spot : CSpotLightComponent;
        var sourceLight : CLightComponent;
        var params : CLightRewriteSourceParams;
        var rewriter : ILightSourceRewriter;

        if (!target) return false;
        if (!target.lrdebugOneliner) return false;

        rewriter = LRDebug_EnsureEntityHasRewriter(target);
        if (!rewriter) return false;

        params = target.LRDebug_EnsureTempParams();
        if (!params) return false;

        attr = GetCurrentAttrId();
        point = LRDebug_FirstPointLight(target);
        spot = LRDebug_FirstSpotLight(target);

        accelMult = 1.0;
        if (accel && LRDebug_IsAcceleratedAttribute(attr)) {
            accelMult = accel.GetMultiplier(sign);
        }

        if (spot && spot.IsEnabled() && LRDebug_IsCandle(target)) {
            sourceLight = spot;
        }
        else {
            sourceLight = point;
        }

        switch (attr) {
            case 'brightness':
                if (!params.hasBrightness) {
                    params.hasBrightness = true;
                    if (sourceLight) params.brightness = sourceLight.brightness;
                    if (sourceLight == spot) params.brightness *= 0.5f;
                }
                step = LRDebug_GetDynamicAttributeStep(attr, params.brightness, sign) * accelMult;
                params.brightness = LRDebug_ApplyDynamicFloatDelta(attr, params.brightness, step * sign);
                break;

            case 'radius':
                if (!params.hasRadius) {
                    params.hasRadius = true;
                    if (sourceLight) params.radius = sourceLight.radius;
                }
                step = LRDebug_GetDynamicAttributeStep(attr, params.radius, sign) * accelMult;
                params.radius = LRDebug_ApplyDynamicFloatDelta(attr, params.radius, step * sign);
                break;

            case 'attenuation':
                if (!params.hasAttenuation) {
                    params.hasAttenuation = true;
                    if (sourceLight) params.attenuation = sourceLight.attenuation;
                }
                step = LRDebug_GetDynamicAttributeStep(attr, params.attenuation, sign) * accelMult;
                params.attenuation = LRDebug_ApplyDynamicFloatDelta(attr, params.attenuation, step * sign);
                break;

            case 'shadowFadeDistance':
                if (!params.hasShadowFadeDistance) {
                    params.hasShadowFadeDistance = true;
                    if (sourceLight) params.shadowFadeDistance = sourceLight.shadowFadeDistance;
                }
                step = LRDebug_GetDynamicAttributeStep(attr, params.shadowFadeDistance, sign) * accelMult;
                params.shadowFadeDistance = LRDebug_ApplyDynamicFloatDelta(attr, params.shadowFadeDistance, step * sign);
                break;

            case 'shadowFadeRange':
                if (!params.hasShadowFadeRange) {
                    params.hasShadowFadeRange = true;
                    if (sourceLight) params.shadowFadeRange = sourceLight.shadowFadeRange;
                }
                step = LRDebug_GetDynamicAttributeStep(attr, params.shadowFadeRange, sign) * accelMult;
                params.shadowFadeRange = LRDebug_ApplyDynamicFloatDelta(attr, params.shadowFadeRange, step * sign);
                break;

            case 'shadowBlendFactor':
                if (!params.hasShadowBlendFactor) {
                    params.hasShadowBlendFactor = true;
                    if (sourceLight) params.shadowBlendFactor = sourceLight.shadowBlendFactor;
                }
                step = LRDebug_GetDynamicAttributeStep(attr, params.shadowBlendFactor, sign) * accelMult;
                params.shadowBlendFactor = LRDebug_ApplyDynamicFloatDelta(attr, params.shadowBlendFactor, step * sign);
                break;

            case 'useSpotlightColor':
                params.hasUseSpotlightColor = true;
                params.useSpotlightColor = (sign > 0);
                break;

            case 'alignPointLights':
                params.hasAlignPointLights = true;
                params.alignPointLights = (sign > 0);
                break;

            case 'alignOffsetZ':
                if (!params.hasAlignPointLights) {
                    params.hasAlignPointLights = true;
                    params.alignPointLights = true;
                }
                step = LRDebug_GetDynamicAttributeStep(attr, params.pointLightOffset.Z, sign) * accelMult;
                params.pointLightOffset.Z += step * sign;
                break;

            case 'overrideColour':
                params.hasColour = (sign > 0);
                if (params.hasColour && sourceLight) {
                    params.color = sourceLight.color;
                }
                break;

            case 'colourR':
                if (!params.hasColour) {
                    params.hasColour = true;
                    if (sourceLight) params.color = sourceLight.color;
                }
                params.color.Red = (byte)Clamp(params.color.Red + sign, 0, 255);
                break;

            case 'colourG':
                if (!params.hasColour) {
                    params.hasColour = true;
                    if (sourceLight) params.color = sourceLight.color;
                }
                params.color.Green = (byte)Clamp(params.color.Green + sign, 0, 255);
                break;

            case 'colourB':
                if (!params.hasColour) {
                    params.hasColour = true;
                    if (sourceLight) params.color = sourceLight.color;
                }
                params.color.Blue = (byte)Clamp(params.color.Blue + sign, 0, 255);
                break;
        }

        rewriter.LRDebug_SetMenuOverrideParams(params);
        rewriter.RewriteLight();
        return true;
    }
}
