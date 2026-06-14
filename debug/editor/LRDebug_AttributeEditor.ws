/**
 * Owns the currently-selected attribute index and all per-attribute edit logic.
 *
 * CycleAttribute and AdjustAttribute intentionally do not call
 * LRDebug_RegenerateText on the target's oneliner - that is the caller's
 * responsibility after each operation so the call site stays explicit.
 */
class LRDebug_AttributeEditor {
    private var attrIndex        : int;
    private var accelerator      : LRDebug_AdjustAccelerator;
    private var adjustAccumulator: float;
    private var selectedLightType: name;  default selectedLightType = 'point';

    public function Init() {
        accelerator = new LRDebug_AdjustAccelerator in thePlayer;
    }

    public function SetAttributeIndex(index: int) {
        attrIndex = index;
    }

    public function GetCurrentAttrId(): name {
        switch (attrIndex) {
            case 0:   return 'brightness';
            case 1:   return 'radius';
            case 2:   return 'attenuation';
            case 3:   return 'shadowFadeDistance';
            case 4:   return 'shadowFadeRange';
            case 5:   return 'shadowBlendFactor';
            case 6:   return 'useSpotlightColor';
            case 7:   return 'alignPointLights';
            case 8:   return 'alignOffsetZ';
            case 9:   return 'overrideColour';
            case 10:  return 'colourR';
            case 11:  return 'colourG';
            case 12:  return 'colourB';
        }
        return 'unknown';
    }

    public function GetCurrentAttrLabel(): string {
        switch (GetCurrentAttrId()) {
            case 'brightness':          return "brightness";
            case 'radius':              return "radius";
            case 'attenuation':         return "attenuation";
            case 'shadowFadeDistance':  return "shadow distance";
            case 'shadowFadeRange':     return "shadow range";
            case 'shadowBlendFactor':   return "shadow blend";
            case 'useSpotlightColor':   return "use spotlight colour";
            case 'alignPointLights':    return "align point lights";
            case 'alignOffsetZ':        return "align offset Z";
            case 'overrideColour':      return "override colour";
            case 'colourR':             return "colour R";
            case 'colourG':             return "colour G";
            case 'colourB':             return "colour B";
        }
        return "unknown";
    }

    public function GetSelectedLightType(target: CGameplayEntity): name {
        var hasPoint, hasSpot: bool;

        if (LRDebug_FirstPointLight(target)) hasPoint = true;
        if (LRDebug_FirstSpotLight(target)) hasSpot = true;

        if (selectedLightType == 'spot' && hasSpot) return 'spot';
        if (!hasPoint && hasSpot) return 'spot';
        return 'point';
    }

    public function SwapLightSelection(target: CGameplayEntity) {
        var hasPoint, hasSpot: bool;

        if (LRDebug_FirstPointLight(target)) hasPoint = true;
        if (LRDebug_FirstSpotLight(target)) hasSpot = true;

        if (!hasPoint || !hasSpot) return;

        if (selectedLightType == 'spot') selectedLightType = 'point';
        else selectedLightType = 'spot';

        if (!IsAttrApplicable(GetCurrentAttrId(), selectedLightType)) {
            CycleAttribute(1, target);
        }
    }

    /** Point-only attributes have no meaning on a spotlight. */
    private function IsAttrApplicable(attr: name, type: name): bool {
        if (type != 'spot') return true;

        switch (attr) {
            case 'useSpotlightColor':
            case 'alignPointLights':
            case 'alignOffsetZ':
                return false;
        }
        return true;
    }

    private function GetSharedParams(
        params: CLightRewriteSourceParams,
        target: CGameplayEntity,
        type: name
    ): ILightRewriteParams {
        if (type == 'spot') return EnsureSpotParams(params, target);
        return params;
    }

    private function EnsureSpotParams(
        params: CLightRewriteSourceParams,
        target: CGameplayEntity
    ): CLightRewriteSpotlightParams {
        if (!target.lrDebugSpotOwned) {
            // Clone so edits don't mutate the profile's shared spotlight (ApplyTo copies it by reference).
            if (params.spotlight) {
                params.spotlight = (CLightRewriteSpotlightParams)params.spotlight.Clone(target);
            }
            else {
                params.spotlight = new CLightRewriteSpotlightParams in target;
            }
            target.lrDebugSpotOwned = true;
        }
        return params.spotlight;
    }

    private function GetFloatStep(value: float): float {
        if (value >= 50.0) return 5.0;
        if (value >= 25.0) return 2.5;
        if (value >= 15.0) return 1.0;
        if (value >= 3.5) return 0.5;
        if (value >= 1.0) return 0.25;
        if (value >= 0.5) return 0.1;
        if (value >= 0.1) return 0.05;
        return 0.01;
    }

    private function GetFloatStepDirectional(currentValue: float, value: float): float {
        var floatStep: float = GetFloatStep(currentValue);

        if (value > 0.0) return floatStep;

        // If decrementing would take us into a lower band, use the lower band's step.
        return MinF(floatStep, GetFloatStep(currentValue - floatStep));
    }

    // RoundF() is not used here because RoundF(0.05 * 100.0) / 100.0 == 0.04.
    private function ClampAttributeValue(attr: name, value: float): float {
        var clamped: float;

        // alignOffsetZ is the only attribute that can go negative.
        switch (attr) {
            case 'brightness':          clamped = ClampF(value, 0.0, 100.0);  break;
            case 'radius':              clamped = ClampF(value, 0.0, 50.0);   break;
            case 'attenuation':         clamped = ClampF(value, 0.0, 1.0);    break;
            case 'shadowFadeDistance':  clamped = ClampF(value, 0.0, 100.0);  break;
            case 'shadowFadeRange':     clamped = ClampF(value, 0.0, 100.0);  break;
            case 'shadowBlendFactor':   clamped = ClampF(value, 0.0, 1.0);    break;
            case 'alignOffsetZ':        clamped = ClampF(value, -3.0, 3.0);   break;
            default:                    return value;
        }

        if (clamped >= 0.0) return (float)FloorF(clamped * 100.0 + 0.5) / 100.0;
        return (float)CeilF(clamped * 100.0 - 0.5) / 100.0;
    }

    private function GetDynamicStep(attr: name, currentValue: float, value: float): float {
        switch (attr) {
            case 'alignOffsetZ':
            case 'attenuation':
            case 'shadowBlendFactor':
                return 0.05;
            default:
                return GetFloatStepDirectional(currentValue, value);
        }
    }

    private function ApplyFloatDelta(attr: name, currentValue: float, delta: float): float {
        var remaining: float;
        var sign: float;
        var step: float;
        var prevValue: float;
        var i: int;

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

    public function CycleAttribute(delta: int, target: CGameplayEntity) {
        var count: int = 13;
        var type: name;
        var guard: int;

        if (count <= 0 || delta == 0) return;

        type = GetSelectedLightType(target);

        // Skip attributes inactive for the selected type; guard bounds the loop if none are.
        for (guard = 0; guard < count; guard += 1) {
            attrIndex += delta;
            while (attrIndex < 0) attrIndex += count;
            while (attrIndex >= count) attrIndex -= count;

            if (IsAttrApplicable(GetCurrentAttrId(), type)) return;
        }
    }

    /**
     * Applies a signed adjustment to the currently selected attribute on the
     * given entity. Returns true if the adjustment was applied (caller should
     * then call LRDebug_RegenerateText on the entity's oneliner).
     */
    public function AdjustAttribute(
        value: float,
        target: CGameplayEntity,
        optional attr: name
    ): bool {
        var step: float;
        var point: CPointLightComponent;
        var spot: CSpotLightComponent;
        var sourceLight: CLightComponent;
        var params: CLightRewriteSourceParams;
        var lightParams: ILightRewriteParams;
        var rewriter: ILightSourceRewriter;
        var colourStep: int;
        var type: name;

        var accelMult: float = 1.0;

        if (!target) return false;
        if (!target.lrdebugOneliner) return false;
        if (!accelerator) {
            LogLightRewrite("LRDebug_AttributeEditor: You need to call Init() on the attribute editor first.");
            return false;
        }

        rewriter = target.LRDebug_GetOrCreateRewriter();
        params = target.LRDebug_GetParams(rewriter);
        point = LRDebug_FirstPointLight(target);
        spot = LRDebug_FirstSpotLight(target);

        if (attr == '') attr = GetCurrentAttrId();

        type = GetSelectedLightType(target);
        if (!IsAttrApplicable(attr, type)) return false;

        switch (attr) {
            case 'brightness':
            case 'radius':
            case 'attenuation':
            case 'shadowFadeDistance':
            case 'shadowFadeRange':
            case 'shadowBlendFactor':
            case 'alignOffsetZ':
                accelMult = accelerator.GetMultiplier(value);
        }

        if (type == 'spot') sourceLight = spot;
        else sourceLight = point;

        switch (attr) {
            case 'brightness':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.hasBrightness) {
                    lightParams.hasBrightness = true;
                    if (sourceLight) lightParams.brightness = sourceLight.brightness;
                }
                step = GetDynamicStep(attr, lightParams.brightness, value) * accelMult;
                lightParams.brightness = ApplyFloatDelta(attr, lightParams.brightness, step * value);
                break;

            case 'radius':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.hasRadius) {
                    lightParams.hasRadius = true;
                    if (sourceLight) lightParams.radius = sourceLight.radius;
                }
                step = GetDynamicStep(attr, lightParams.radius, value) * accelMult;
                lightParams.radius = ApplyFloatDelta(attr, lightParams.radius, step * value);
                break;

            case 'attenuation':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.hasAttenuation) {
                    lightParams.hasAttenuation = true;
                    if (sourceLight) lightParams.attenuation = sourceLight.attenuation;
                }
                step = GetDynamicStep(attr, lightParams.attenuation, value) * accelMult;
                lightParams.attenuation = ApplyFloatDelta(attr, lightParams.attenuation, step * value);
                break;

            case 'shadowFadeDistance':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.hasShadowFadeDistance) {
                    lightParams.hasShadowFadeDistance = true;
                    if (sourceLight) {
                        lightParams.shadowFadeDistance = sourceLight.shadowFadeDistance;
                    }
                }
                step = GetDynamicStep(attr, lightParams.shadowFadeDistance, value) * accelMult;
                lightParams.shadowFadeDistance = ApplyFloatDelta(attr, lightParams.shadowFadeDistance, step * value);
                break;

            case 'shadowFadeRange':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.hasShadowFadeRange) {
                    lightParams.hasShadowFadeRange = true;
                    if (sourceLight) lightParams.shadowFadeRange = sourceLight.shadowFadeRange;
                }
                step = GetDynamicStep(attr, lightParams.shadowFadeRange, value) * accelMult;
                lightParams.shadowFadeRange = ApplyFloatDelta(attr, lightParams.shadowFadeRange, step * value);
                break;

            case 'shadowBlendFactor':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.hasShadowBlendFactor) {
                    lightParams.hasShadowBlendFactor = true;
                    if (sourceLight) lightParams.shadowBlendFactor = sourceLight.shadowBlendFactor;
                }
                step = GetDynamicStep(attr, lightParams.shadowBlendFactor, value) * accelMult;
                lightParams.shadowBlendFactor = ApplyFloatDelta(attr, lightParams.shadowBlendFactor, step * value);
                break;

            case 'useSpotlightColor':
                params.hasUseSpotlightColor = true;
                params.useSpotlightColor = (value > 0);
                break;

            case 'alignPointLights':
                params.hasAlignPointLights = true;
                params.alignPointLights = (value > 0);
                break;

            case 'alignOffsetZ':
                if (!params.hasAlignPointLights) {
                    params.hasAlignPointLights = true;
                    params.alignPointLights = true;
                }
                step = GetDynamicStep(attr, params.pointLightOffset.Z, value) * accelMult;
                params.pointLightOffset.Z += step * value;
                break;

            case 'overrideColour':
                lightParams = GetSharedParams(params, target, type);
                lightParams.hasColour = (value > 0);
                if (lightParams.hasColour && sourceLight) {
                    lightParams.color = sourceLight.color;
                }
                break;

            case 'colourR':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.hasColour) {
                    lightParams.hasColour = true;
                    if (sourceLight) lightParams.color = sourceLight.color;
                }
                colourStep = RoundF(SignF(value) * Max(1, FloorF(AbsF(value))));
                lightParams.color.Red = (byte)Clamp(lightParams.color.Red + colourStep, 0, 255);
                break;

            case 'colourG':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.hasColour) {
                    lightParams.hasColour = true;
                    if (sourceLight) lightParams.color = sourceLight.color;
                }
                colourStep = RoundF(SignF(value) * Max(1, FloorF(AbsF(value))));
                lightParams.color.Green = (byte)Clamp(lightParams.color.Green + colourStep, 0, 255);
                break;

            case 'colourB':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.hasColour) {
                    lightParams.hasColour = true;
                    if (sourceLight) lightParams.color = sourceLight.color;
                }
                colourStep = RoundF(SignF(value) * Max(1, FloorF(AbsF(value))));
                lightParams.color.Blue = (byte)Clamp(lightParams.color.Blue + colourStep, 0, 255);
                break;
        }

        rewriter.LRDebug_SetMenuOverrideParams(params);
        rewriter.RestoreOriginalState();
        rewriter.RewriteLight();
        return true;
    }

    /**
     * Analog hold-to-edit path: adds a raw signed delta to the attribute and
     * applies it live. Unlike AdjustAttribute this skips the discrete step and
     * scroll-acceleration logic; the caller has already scaled the mouse delta.
     */
    public function AdjustAttributeContinuous(
        delta: float,
        target: CGameplayEntity,
        optional attr: name
    ): bool {
        var point: CPointLightComponent;
        var spot: CSpotLightComponent;
        var sourceLight: CLightComponent;
        var params: CLightRewriteSourceParams;
        var lightParams: ILightRewriteParams;
        var rewriter: ILightSourceRewriter;
        var type: name;

        if (delta == 0.0) return false;
        if (!target) return false;
        if (!target.lrdebugOneliner) return false;

        rewriter = target.LRDebug_GetOrCreateRewriter();
        params = target.LRDebug_GetParams(rewriter);
        point = LRDebug_FirstPointLight(target);
        spot = LRDebug_FirstSpotLight(target);

        if (attr == '') attr = GetCurrentAttrId();

        type = GetSelectedLightType(target);
        if (!IsAttrApplicable(attr, type)) return false;

        // Normalise per attribute so a full swipe covers each one's range (brightness feel).
        delta *= GetAxisScale(attr);

        // Release the accumulated movement in whole value-resolution steps
        delta = ConsumeQuantizedDelta(delta, GetAdjustQuantum(attr));
        if (delta == 0.0) return false;

        if (type == 'spot') sourceLight = spot;
        else sourceLight = point;

        switch (attr) {
            case 'brightness':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.hasBrightness) {
                    lightParams.hasBrightness = true;
                    if (sourceLight) lightParams.brightness = sourceLight.brightness;
                }
                lightParams.brightness = ClampAttributeValue(attr, lightParams.brightness + delta);
                break;

            case 'radius':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.hasRadius) {
                    lightParams.hasRadius = true;
                    if (sourceLight) lightParams.radius = sourceLight.radius;
                }
                lightParams.radius = ClampAttributeValue(attr, lightParams.radius + delta);
                break;

            case 'attenuation':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.hasAttenuation) {
                    lightParams.hasAttenuation = true;
                    if (sourceLight) lightParams.attenuation = sourceLight.attenuation;
                }
                lightParams.attenuation = ClampAttributeValue(attr, lightParams.attenuation + delta);
                break;

            case 'shadowFadeDistance':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.hasShadowFadeDistance) {
                    lightParams.hasShadowFadeDistance = true;
                    if (sourceLight) {
                        lightParams.shadowFadeDistance = sourceLight.shadowFadeDistance;
                    }
                }
                lightParams.shadowFadeDistance = ClampAttributeValue(attr, lightParams.shadowFadeDistance + delta);
                break;

            case 'shadowFadeRange':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.hasShadowFadeRange) {
                    lightParams.hasShadowFadeRange = true;
                    if (sourceLight) lightParams.shadowFadeRange = sourceLight.shadowFadeRange;
                }
                lightParams.shadowFadeRange = ClampAttributeValue(attr, lightParams.shadowFadeRange + delta);
                break;

            case 'shadowBlendFactor':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.hasShadowBlendFactor) {
                    lightParams.hasShadowBlendFactor = true;
                    if (sourceLight) lightParams.shadowBlendFactor = sourceLight.shadowBlendFactor;
                }
                lightParams.shadowBlendFactor = ClampAttributeValue(attr, lightParams.shadowBlendFactor + delta);
                break;

            case 'alignOffsetZ':
                if (!params.hasAlignPointLights) {
                    params.hasAlignPointLights = true;
                    params.alignPointLights = true;
                }
                params.pointLightOffset.Z = ClampAttributeValue(attr, params.pointLightOffset.Z + delta);
                break;

            case 'colourR':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.hasColour) {
                    lightParams.hasColour = true;
                    if (sourceLight) lightParams.color = sourceLight.color;
                }
                lightParams.color.Red = (byte)Clamp(lightParams.color.Red + (int)delta, 0, 255);
                break;

            case 'colourG':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.hasColour) {
                    lightParams.hasColour = true;
                    if (sourceLight) lightParams.color = sourceLight.color;
                }
                lightParams.color.Green = (byte)Clamp(lightParams.color.Green + (int)delta, 0, 255);
                break;

            case 'colourB':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.hasColour) {
                    lightParams.hasColour = true;
                    if (sourceLight) lightParams.color = sourceLight.color;
                }
                lightParams.color.Blue = (byte)Clamp(lightParams.color.Blue + (int)delta, 0, 255);
                break;

            default:
                return false;
        }

        rewriter.LRDebug_SetMenuOverrideParams(params);
        rewriter.RestoreOriginalState();
        rewriter.RewriteLight();
        return true;
    }

    public function ResetAdjustAccumulator() {
        adjustAccumulator = 0.0;
    }

    /**
     * Accumulates the analog mouse delta and releases it in whole `quantum` increments,
     * carrying the sub-quantum remainder so high-DPI / high-FPS movement isn't lost to the
     * value's per-frame rounding.
     */
    private function ConsumeQuantizedDelta(delta: float, quantum: float): float {
        var sign: float;
        var steps: float;

        adjustAccumulator += delta;
        steps = FloorF(AbsF(adjustAccumulator) / quantum);
        if (steps < 1.0) return 0.0;

        sign = SignF(adjustAccumulator);
        adjustAccumulator -= sign * steps * quantum;
        return sign * steps * quantum;
    }

    /** Minimum input step size: colours are bytes, so must be 1 */
    private function GetAdjustQuantum(attr: name): float {
        switch (attr) {
            case 'colourR':
            case 'colourG':
            case 'colourB': return 1.0;
        }
        return 0.01;
    }

    /**
     * Per-attribute analog scale so a full mouse swipe covers each attribute's whole range
     * at the same "large swipe" feel as brightness (its 0-100 range is the reference).
     * alignOffsetZ stays 1.0: unbounded, left as-is for now.
     */
    private function GetAxisScale(attr: name): float {
        switch (attr) {
            case 'radius':             return 0.5;
            case 'attenuation':        return 0.01;
            case 'shadowBlendFactor':  return 0.01;
            case 'alignOffsetZ':       return 0.1;
            case 'colourR':
            case 'colourG':
            case 'colourB':            return 2.55;
        }
        return 1.0; // brightness, shadow fade distance/range,
    }

    /**
     * Flips a boolean attribute on the target and applies it live. Bools toggle on a
     * key-press rather than via analog hold-to-edit.
     */
    public function ToggleAttribute(target: CGameplayEntity, optional attr: name): bool {
        var point: CPointLightComponent;
        var spot: CSpotLightComponent;
        var sourceLight: CLightComponent;
        var params: CLightRewriteSourceParams;
        var lightParams: ILightRewriteParams;
        var rewriter: ILightSourceRewriter;
        var type: name;

        if (!target) return false;
        if (!target.lrdebugOneliner) return false;

        rewriter = target.LRDebug_GetOrCreateRewriter();
        params = target.LRDebug_GetParams(rewriter);
        point = LRDebug_FirstPointLight(target);
        spot = LRDebug_FirstSpotLight(target);

        if (attr == '') attr = GetCurrentAttrId();

        type = GetSelectedLightType(target);
        if (!IsAttrApplicable(attr, type)) return false;

        if (type == 'spot') sourceLight = spot;
        else sourceLight = point;

        switch (attr) {
            case 'useSpotlightColor':
                params.hasUseSpotlightColor = true;
                params.useSpotlightColor = !params.useSpotlightColor;
                break;

            case 'alignPointLights':
                params.hasAlignPointLights = true;
                params.alignPointLights = !params.alignPointLights;
                break;

            case 'overrideColour':
                lightParams = GetSharedParams(params, target, type);
                lightParams.hasColour = !lightParams.hasColour;
                if (lightParams.hasColour && sourceLight) lightParams.color = sourceLight.color;
                break;

            default:
                return false;
        }

        rewriter.LRDebug_SetMenuOverrideParams(params);
        rewriter.RestoreOriginalState();
        rewriter.RewriteLight();
        return true;
    }
}
