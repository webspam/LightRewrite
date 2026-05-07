/**
 * Owns the currently-selected attribute index and all per-attribute edit logic.
 *
 * CycleAttribute and AdjustAttribute intentionally do not call
 * LRDebug_RegenerateText on the target's oneliner — that is the caller's
 * responsibility after each operation so the call site stays explicit.
 */
class LRDebug_AttributeEditor {
    private var attrIndex : int;
    private var accelerator : LRDebug_AdjustAccelerator;

    public function Init() {
        accelerator = new LRDebug_AdjustAccelerator in thePlayer;
    }

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

    private function GetFloatStep(value : float) : float {
        if (value >= 50.0) return 5.0;
        if (value >= 25.0) return 2.5;
        if (value >= 15.0) return 1.0;
        if (value >= 3.5)  return 0.5;
        if (value >= 1.0)  return 0.25;
        if (value >= 0.5)  return 0.1;
        if (value >= 0.1)  return 0.05;
        return 0.01;
    }

    private function GetFloatStepDirectional(value : float, sign : float) : float {
        var floatStep : float = GetFloatStep(value);

        if (sign > 0.0) return floatStep;

        // If decrementing would take us into a lower band, use the lower band's step.
        return MinF(floatStep, GetFloatStep(value - floatStep));
    }

    // RoundF() is not used here because RoundF(0.05 * 100.0) / 100.0 == 0.04.
    private function ClampAttributeValue(attr : name, value : float) : float {
        var clamped : float;

        // alignOffsetZ is the only attribute that can go negative.
        switch (attr) {
            case 'brightness':         clamped = ClampF(value, 0.0, 100.0); break;
            case 'radius':             clamped = ClampF(value, 0.0, 50.0);  break;
            case 'attenuation':        clamped = ClampF(value, 0.0, 1.0);   break;
            case 'shadowFadeDistance': clamped = ClampF(value, 0.0, 100.0); break;
            case 'shadowFadeRange':    clamped = ClampF(value, 0.0, 100.0); break;
            case 'shadowBlendFactor':  clamped = ClampF(value, 0.0, 1.0);   break;
            case 'alignOffsetZ':       clamped = ClampF(value, -3.0, 3.0);  break;
            default: return value;
        }

        if (clamped >= 0.0) return (float)FloorF(clamped * 100.0 + 0.5) / 100.0;
        return (float)CeilF(clamped * 100.0 - 0.5) / 100.0;
    }

    private function GetDynamicStep(attr : name, currentValue : float, sign : float) : float {
        switch (attr) {
            case 'alignOffsetZ':
            case 'attenuation':
            case 'shadowBlendFactor':
                return 0.05;
            default:
                return GetFloatStepDirectional(currentValue, sign);
        }
    }

    private function ApplyFloatDelta(attr : name, currentValue : float, delta : float) : float {
        var remaining : float;
        var sign : float;
        var step : float;
        var prevValue : float;
        var i : int;

        if (delta == 0.0) return currentValue;

        remaining = delta;
        sign = 1.0;
        if (remaining < 0.0) sign = -1.0;

        // Apply in sub-steps so large deltas don't skip step-size thresholds.
        for (i = 0; i < 1000 && remaining * sign > 0.0; i += 1) {
            step = GetDynamicStep(attr, currentValue, sign);
            if (step <= 0.0) break;

            if (step > remaining * sign) step = remaining * sign;

            prevValue = currentValue;
            currentValue = currentValue + (step * sign);
            currentValue = ClampAttributeValue(attr, currentValue);

            // If rounding/clamping prevented any change, stop to avoid getting stuck.
            if (currentValue == prevValue) break;

            remaining = remaining - (step * sign);
            if (currentValue == 0.0 && sign < 0.0) break;
        }

        return currentValue;
    }

    public function CycleAttribute(delta : int) {
        var count : int = 13;
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
    public function AdjustAttribute(sign : int, target : CGameplayEntity) : bool {
        var attr : name;
        var step : float;
        var point : CPointLightComponent;
        var spot : CSpotLightComponent;
        var sourceLight : CLightComponent;
        var params : CLightRewriteSourceParams;
        var rewriter : ILightSourceRewriter;

        var accelMult : float = 1.0;

        if (!target) return false;
        if (!target.lrdebugOneliner) return false;
        if (!accelerator) {
            LogLightRewrite("LRDebug_AttributeEditor: You need to call Init() on the attribute editor first.");
            return false;
        }

        rewriter = target.LRDebug_GetOrCreateRewriter();
        params = target.LRDebug_GetParams();
        attr = GetCurrentAttrId();
        point = LRDebug_FirstPointLight(target);
        spot = LRDebug_FirstSpotLight(target);

        switch (attr) {
            case 'brightness':
            case 'radius':
            case 'attenuation':
            case 'shadowFadeDistance':
            case 'shadowFadeRange':
            case 'shadowBlendFactor':
            case 'alignOffsetZ':
                accelMult = accelerator.GetMultiplier(sign);
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
                step = GetDynamicStep(attr, params.brightness, sign) * accelMult;
                params.brightness = ApplyFloatDelta(attr, params.brightness, step * sign);
                break;

            case 'radius':
                if (!params.hasRadius) {
                    params.hasRadius = true;
                    if (sourceLight) params.radius = sourceLight.radius;
                }
                step = GetDynamicStep(attr, params.radius, sign) * accelMult;
                params.radius = ApplyFloatDelta(attr, params.radius, step * sign);
                break;

            case 'attenuation':
                if (!params.hasAttenuation) {
                    params.hasAttenuation = true;
                    if (sourceLight) params.attenuation = sourceLight.attenuation;
                }
                step = GetDynamicStep(attr, params.attenuation, sign) * accelMult;
                params.attenuation = ApplyFloatDelta(attr, params.attenuation, step * sign);
                break;

            case 'shadowFadeDistance':
                if (!params.hasShadowFadeDistance) {
                    params.hasShadowFadeDistance = true;
                    if (sourceLight) params.shadowFadeDistance = sourceLight.shadowFadeDistance;
                }
                step = GetDynamicStep(attr, params.shadowFadeDistance, sign) * accelMult;
                params.shadowFadeDistance = ApplyFloatDelta(attr, params.shadowFadeDistance, step * sign);
                break;

            case 'shadowFadeRange':
                if (!params.hasShadowFadeRange) {
                    params.hasShadowFadeRange = true;
                    if (sourceLight) params.shadowFadeRange = sourceLight.shadowFadeRange;
                }
                step = GetDynamicStep(attr, params.shadowFadeRange, sign) * accelMult;
                params.shadowFadeRange = ApplyFloatDelta(attr, params.shadowFadeRange, step * sign);
                break;

            case 'shadowBlendFactor':
                if (!params.hasShadowBlendFactor) {
                    params.hasShadowBlendFactor = true;
                    if (sourceLight) params.shadowBlendFactor = sourceLight.shadowBlendFactor;
                }
                step = GetDynamicStep(attr, params.shadowBlendFactor, sign) * accelMult;
                params.shadowBlendFactor = ApplyFloatDelta(attr, params.shadowBlendFactor, step * sign);
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
                step = GetDynamicStep(attr, params.pointLightOffset.Z, sign) * accelMult;
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
