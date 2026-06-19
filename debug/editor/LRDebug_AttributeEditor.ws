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

    public function IsEditingOffset(): bool {
        return GetCurrentAttrId(selectedLightType) == 'alignOffsetZ';
    }

    /** In spot mode slots 6/7/13 are the spotlight cone; every other slot is shared */
    public function GetCurrentAttrId(type: name): name {
        if (type == 'spot') {
            switch (attrIndex) {
                case 6:   return 'innerAngle';
                case 7:   return 'outerAngle';
                case 13:  return 'softness';
            }
        }

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
            case 13:  return 'softness';
        }
        return 'unknown';
    }

    public function GetCurrentAttrLabel(type: name): string {
        switch (GetCurrentAttrId(type)) {
            case 'brightness':          return "brightness";
            case 'radius':              return "radius";
            case 'attenuation':         return "attenuation";
            case 'shadowFadeDistance':  return "shadow distance";
            case 'shadowFadeRange':     return "shadow range";
            case 'shadowBlendFactor':   return "shadow blend";
            case 'useSpotlightColor':   return "use spotlight colour";
            case 'alignPointLights':    return "align point lights";
            case 'alignOffsetZ':        return "align offset Z";
            case 'innerAngle':          return "inner angle";
            case 'outerAngle':          return "outer angle";
            case 'softness':            return "softness";
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
        var type: name;

        if (LRDebug_FirstPointLight(target)) hasPoint = true;
        if (LRDebug_FirstSpotLight(target)) hasSpot = true;

        if (!hasPoint || !hasSpot) return;

        if (selectedLightType == 'spot') selectedLightType = 'point';
        else selectedLightType = 'spot';

        type = GetSelectedLightType(target);
        if (!IsAttrApplicable(GetCurrentAttrId(type), type)) {
            CycleAttribute(1, target);
        }
    }

    /** Cone attributes only exist on spotlights; the rewriter bools only on point lights. */
    private function IsAttrApplicable(attr: name, type: name): bool {
        switch (attr) {
            case 'innerAngle':
            case 'outerAngle':
            case 'softness':
                return type == 'spot';
            case 'useSpotlightColor':
            case 'alignPointLights':
                return type != 'spot';
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

    /** Seed offset from the live position; it's absolute, so starting at 0 would teleport the light */
    private function SeedSpotOffset(
        spotParams: CLightRewriteSpotlightParams,
        spot: CSpotLightComponent
    ) {
        if (spotParams.offset.has) return;
        spotParams.offset.has = true;
        if (spot) spotParams.offset.value = spot.GetLocalPosition();
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
            case 'innerAngle':          clamped = ClampF(value, 0.0, 360.0);  break;
            case 'outerAngle':          clamped = ClampF(value, 0.0, 360.0);  break;
            case 'softness':            clamped = ClampF(value, 0.0, 255.0);  break;
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
        var count: int = 14;
        var type: name;
        var guard: int;

        if (count <= 0 || delta == 0) return;

        type = GetSelectedLightType(target);

        // Skip attributes inactive for the selected type; guard bounds the loop if none are.
        for (guard = 0; guard < count; guard += 1) {
            attrIndex += delta;
            while (attrIndex < 0) attrIndex += count;
            while (attrIndex >= count) attrIndex -= count;

            if (IsAttrApplicable(GetCurrentAttrId(type), type)) return;
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
        var spotParams: CLightRewriteSpotlightParams;
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

        type = GetSelectedLightType(target);
        if (attr == '') attr = GetCurrentAttrId(type);
        if (!IsAttrApplicable(attr, type)) return false;

        switch (attr) {
            case 'brightness':
            case 'radius':
            case 'attenuation':
            case 'shadowFadeDistance':
            case 'shadowFadeRange':
            case 'shadowBlendFactor':
            case 'alignOffsetZ':
            case 'innerAngle':
            case 'outerAngle':
            case 'softness':
                accelMult = accelerator.GetMultiplier(value);
        }

        if (type == 'spot') sourceLight = spot;
        else sourceLight = point;

        switch (attr) {
            case 'brightness':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.brightness.has) {
                    lightParams.brightness.has = true;
                    if (sourceLight) lightParams.brightness.value = sourceLight.brightness;
                }
                step = GetDynamicStep(attr, lightParams.brightness.value, value) * accelMult;
                lightParams.brightness.value = ApplyFloatDelta(attr, lightParams.brightness.value, step * value);
                break;

            case 'radius':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.radius.has) {
                    lightParams.radius.has = true;
                    if (sourceLight) lightParams.radius.value = sourceLight.radius;
                }
                step = GetDynamicStep(attr, lightParams.radius.value, value) * accelMult;
                lightParams.radius.value = ApplyFloatDelta(attr, lightParams.radius.value, step * value);
                break;

            case 'attenuation':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.attenuation.has) {
                    lightParams.attenuation.has = true;
                    if (sourceLight) lightParams.attenuation.value = sourceLight.attenuation;
                }
                step = GetDynamicStep(attr, lightParams.attenuation.value, value) * accelMult;
                lightParams.attenuation.value = ApplyFloatDelta(attr, lightParams.attenuation.value, step * value);
                break;

            case 'shadowFadeDistance':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.shadowFadeDistance.has) {
                    lightParams.shadowFadeDistance.has = true;
                    if (sourceLight) {
                        lightParams.shadowFadeDistance.value = sourceLight.shadowFadeDistance;
                    }
                }
                step = GetDynamicStep(attr, lightParams.shadowFadeDistance.value, value) * accelMult;
                lightParams.shadowFadeDistance.value = ApplyFloatDelta(attr, lightParams.shadowFadeDistance.value, step * value);
                break;

            case 'shadowFadeRange':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.shadowFadeRange.has) {
                    lightParams.shadowFadeRange.has = true;
                    if (sourceLight) {
                        lightParams.shadowFadeRange.value = sourceLight.shadowFadeRange;
                    }
                }
                step = GetDynamicStep(attr, lightParams.shadowFadeRange.value, value) * accelMult;
                lightParams.shadowFadeRange.value = ApplyFloatDelta(attr, lightParams.shadowFadeRange.value, step * value);
                break;

            case 'shadowBlendFactor':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.shadowBlendFactor.has) {
                    lightParams.shadowBlendFactor.has = true;
                    if (sourceLight) {
                        lightParams.shadowBlendFactor.value = sourceLight.shadowBlendFactor;
                    }
                }
                step = GetDynamicStep(attr, lightParams.shadowBlendFactor.value, value) * accelMult;
                lightParams.shadowBlendFactor.value = ApplyFloatDelta(attr, lightParams.shadowBlendFactor.value, step * value);
                break;

            case 'useSpotlightColor':
                params.useSpotlightColor.has = true;
                params.useSpotlightColor.value = (value > 0);
                break;

            case 'alignPointLights':
                params.alignPointLights.has = true;
                params.alignPointLights.value = (value > 0);
                break;

            case 'alignOffsetZ':
                if (type == 'spot') {
                    spotParams = EnsureSpotParams(params, target);
                    SeedSpotOffset(spotParams, spot);
                    step = GetDynamicStep(attr, spotParams.offset.value.Z, value) * accelMult;
                    spotParams.offset.value.Z += step * value;
                }
                else if (LRDebug_IsCandle(target)) {
                    if (!params.alignPointLights.has) {
                        params.alignPointLights.has = true;
                        params.alignPointLights.value = true;
                    }
                    step = GetDynamicStep(attr, params.pointLightOffset.Z, value) * accelMult;
                    params.pointLightOffset.Z += step * value;
                }
                else {
                    if (!params.pointLightOffsetPos.has) {
                        params.pointLightOffsetPos.has = true;
                    }
                    step = GetDynamicStep(attr, params.pointLightOffsetPos.value.Z, value) * accelMult;
                    params.pointLightOffsetPos.value.Z += step * value;
                }
                break;

            case 'innerAngle':
                spotParams = EnsureSpotParams(params, target);
                if (!spotParams.innerAngle.has) {
                    spotParams.innerAngle.has = true;
                    if (spot) spotParams.innerAngle.value = spot.innerAngle;
                }
                step = GetDynamicStep(attr, spotParams.innerAngle.value, value) * accelMult;
                spotParams.innerAngle.value = ApplyFloatDelta(attr, spotParams.innerAngle.value, step * value);
                break;

            case 'outerAngle':
                spotParams = EnsureSpotParams(params, target);
                if (!spotParams.outerAngle.has) {
                    spotParams.outerAngle.has = true;
                    if (spot) spotParams.outerAngle.value = spot.outerAngle;
                }
                step = GetDynamicStep(attr, spotParams.outerAngle.value, value) * accelMult;
                spotParams.outerAngle.value = ApplyFloatDelta(attr, spotParams.outerAngle.value, step * value);
                break;

            case 'softness':
                spotParams = EnsureSpotParams(params, target);
                if (!spotParams.softness.has) {
                    spotParams.softness.has = true;
                    if (spot) spotParams.softness.value = spot.softness;
                }
                step = GetDynamicStep(attr, spotParams.softness.value, value) * accelMult;
                spotParams.softness.value = ApplyFloatDelta(attr, spotParams.softness.value, step * value);
                break;

            case 'overrideColour':
                lightParams = GetSharedParams(params, target, type);
                lightParams.color.has = (value > 0);
                if (lightParams.color.has && sourceLight) {
                    lightParams.color.value = sourceLight.color;
                }
                break;

            case 'colourR':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.color.has) {
                    lightParams.color.has = true;
                    if (sourceLight) lightParams.color.value = sourceLight.color;
                }
                colourStep = RoundF(SignF(value) * Max(1, FloorF(AbsF(value))));
                lightParams.color.value.Red = (byte)Clamp(lightParams.color.value.Red + colourStep, 0, 255);
                break;

            case 'colourG':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.color.has) {
                    lightParams.color.has = true;
                    if (sourceLight) lightParams.color.value = sourceLight.color;
                }
                colourStep = RoundF(SignF(value) * Max(1, FloorF(AbsF(value))));
                lightParams.color.value.Green = (byte)Clamp(lightParams.color.value.Green + colourStep, 0, 255);
                break;

            case 'colourB':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.color.has) {
                    lightParams.color.has = true;
                    if (sourceLight) lightParams.color.value = sourceLight.color;
                }
                colourStep = RoundF(SignF(value) * Max(1, FloorF(AbsF(value))));
                lightParams.color.value.Blue = (byte)Clamp(lightParams.color.value.Blue + colourStep, 0, 255);
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
        var spotParams: CLightRewriteSpotlightParams;
        var rewriter: ILightSourceRewriter;
        var type: name;

        if (delta == 0.0) return false;
        if (!target) return false;
        if (!target.lrdebugOneliner) return false;

        rewriter = target.LRDebug_GetOrCreateRewriter();
        params = target.LRDebug_GetParams(rewriter);
        point = LRDebug_FirstPointLight(target);
        spot = LRDebug_FirstSpotLight(target);

        type = GetSelectedLightType(target);
        if (attr == '') attr = GetCurrentAttrId(type);
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
                if (!lightParams.brightness.has) {
                    lightParams.brightness.has = true;
                    if (sourceLight) lightParams.brightness.value = sourceLight.brightness;
                }
                lightParams.brightness.value = ClampAttributeValue(attr, lightParams.brightness.value + delta);
                break;

            case 'radius':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.radius.has) {
                    lightParams.radius.has = true;
                    if (sourceLight) lightParams.radius.value = sourceLight.radius;
                }
                lightParams.radius.value = ClampAttributeValue(attr, lightParams.radius.value + delta);
                break;

            case 'attenuation':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.attenuation.has) {
                    lightParams.attenuation.has = true;
                    if (sourceLight) lightParams.attenuation.value = sourceLight.attenuation;
                }
                lightParams.attenuation.value = ClampAttributeValue(attr, lightParams.attenuation.value + delta);
                break;

            case 'shadowFadeDistance':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.shadowFadeDistance.has) {
                    lightParams.shadowFadeDistance.has = true;
                    if (sourceLight) {
                        lightParams.shadowFadeDistance.value = sourceLight.shadowFadeDistance;
                    }
                }
                lightParams.shadowFadeDistance.value = ClampAttributeValue(attr, lightParams.shadowFadeDistance.value + delta);
                break;

            case 'shadowFadeRange':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.shadowFadeRange.has) {
                    lightParams.shadowFadeRange.has = true;
                    if (sourceLight) {
                        lightParams.shadowFadeRange.value = sourceLight.shadowFadeRange;
                    }
                }
                lightParams.shadowFadeRange.value = ClampAttributeValue(attr, lightParams.shadowFadeRange.value + delta);
                break;

            case 'shadowBlendFactor':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.shadowBlendFactor.has) {
                    lightParams.shadowBlendFactor.has = true;
                    if (sourceLight) {
                        lightParams.shadowBlendFactor.value = sourceLight.shadowBlendFactor;
                    }
                }
                lightParams.shadowBlendFactor.value = ClampAttributeValue(attr, lightParams.shadowBlendFactor.value + delta);
                break;

            case 'alignOffsetZ':
                if (type == 'spot') {
                    spotParams = EnsureSpotParams(params, target);
                    SeedSpotOffset(spotParams, spot);
                    spotParams.offset.value.Z = ClampAttributeValue(attr, spotParams.offset.value.Z + delta);
                }
                else if (LRDebug_IsCandle(target)) {
                    if (!params.alignPointLights.has) {
                        params.alignPointLights.has = true;
                        params.alignPointLights.value = true;
                    }
                    params.pointLightOffset.Z = ClampAttributeValue(attr, params.pointLightOffset.Z + delta);
                }
                else {
                    if (!params.pointLightOffsetPos.has) {
                        params.pointLightOffsetPos.has = true;
                    }
                    params.pointLightOffsetPos.value.Z = ClampAttributeValue(attr, params.pointLightOffsetPos.value.Z + delta);
                }
                break;

            case 'innerAngle':
                spotParams = EnsureSpotParams(params, target);
                if (!spotParams.innerAngle.has) {
                    spotParams.innerAngle.has = true;
                    if (spot) spotParams.innerAngle.value = spot.innerAngle;
                }
                spotParams.innerAngle.value = ClampAttributeValue(attr, spotParams.innerAngle.value + delta);
                break;

            case 'outerAngle':
                spotParams = EnsureSpotParams(params, target);
                if (!spotParams.outerAngle.has) {
                    spotParams.outerAngle.has = true;
                    if (spot) spotParams.outerAngle.value = spot.outerAngle;
                }
                spotParams.outerAngle.value = ClampAttributeValue(attr, spotParams.outerAngle.value + delta);
                break;

            case 'softness':
                spotParams = EnsureSpotParams(params, target);
                if (!spotParams.softness.has) {
                    spotParams.softness.has = true;
                    if (spot) spotParams.softness.value = spot.softness;
                }
                spotParams.softness.value = ClampAttributeValue(attr, spotParams.softness.value + delta);
                break;

            case 'colourR':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.color.has) {
                    lightParams.color.has = true;
                    if (sourceLight) lightParams.color.value = sourceLight.color;
                }
                lightParams.color.value.Red = (byte)Clamp(lightParams.color.value.Red + (int)delta, 0, 255);
                break;

            case 'colourG':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.color.has) {
                    lightParams.color.has = true;
                    if (sourceLight) lightParams.color.value = sourceLight.color;
                }
                lightParams.color.value.Green = (byte)Clamp(lightParams.color.value.Green + (int)delta, 0, 255);
                break;

            case 'colourB':
                lightParams = GetSharedParams(params, target, type);
                if (!lightParams.color.has) {
                    lightParams.color.has = true;
                    if (sourceLight) lightParams.color.value = sourceLight.color;
                }
                lightParams.color.value.Blue = (byte)Clamp(lightParams.color.value.Blue + (int)delta, 0, 255);
                break;

            default:
                return false;
        }

        rewriter.LRDebug_SetMenuOverrideParams(params);
        rewriter.RestoreOriginalState();
        rewriter.RewriteLight();
        return true;
    }

    /** Candles are skipped: their offset auto-aligns to FX slots, and only its Z is exported */
    public function MoveOffsetXY(dx: float, dy: float, target: CGameplayEntity): bool {
        var point: CPointLightComponent;
        var spot: CSpotLightComponent;
        var params: CLightRewriteSourceParams;
        var spotParams: CLightRewriteSpotlightParams;
        var rewriter: ILightSourceRewriter;
        var type: name;
        var scale: float;

        if (dx == 0.0 && dy == 0.0) return false;
        if (!target) return false;
        if (!target.lrdebugOneliner) return false;

        rewriter = target.LRDebug_GetOrCreateRewriter();
        params = target.LRDebug_GetParams(rewriter);
        point = LRDebug_FirstPointLight(target);
        spot = LRDebug_FirstSpotLight(target);

        type = GetSelectedLightType(target);

        // Normalise using the same value as Z-axis adjustment
        scale = GetAxisScale('alignOffsetZ');
        dx *= scale;
        dy *= scale;

        if (type == 'spot') {
            spotParams = EnsureSpotParams(params, target);
            SeedSpotOffset(spotParams, spot);
            spotParams.offset.value.X += dx;
            spotParams.offset.value.Y += dy;
        }
        else if (LRDebug_IsCandle(target)) {
            return false;
        }
        else {
            if (!params.pointLightOffsetPos.has) {
                params.pointLightOffsetPos.has = true;
            }
            params.pointLightOffsetPos.value.X += dx;
            params.pointLightOffsetPos.value.Y += dy;
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
            case 'softness':           return 0.02;
            case 'colourR':
            case 'colourG':
            case 'colourB':            return 2.55;
        }
        return 1.0;
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

        type = GetSelectedLightType(target);
        if (attr == '') attr = GetCurrentAttrId(type);
        if (!IsAttrApplicable(attr, type)) return false;

        if (type == 'spot') sourceLight = spot;
        else sourceLight = point;

        switch (attr) {
            case 'useSpotlightColor':
                params.useSpotlightColor.has = true;
                params.useSpotlightColor.value = !params.useSpotlightColor.value;
                break;

            case 'alignPointLights':
                params.alignPointLights.has = true;
                params.alignPointLights.value = !params.alignPointLights.value;
                break;

            case 'overrideColour':
                lightParams = GetSharedParams(params, target, type);
                lightParams.color.has = !lightParams.color.has;
                if (lightParams.color.has && sourceLight) {
                    lightParams.color.value = sourceLight.color;
                }
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
