/**
 * Attribute registry and step-math for the LRDebug light editing system.
 *
 * All functions are pure (no engine state, no side effects).
 * The 13 editable attributes are indexed 0–12.
 */

function LRDebug_GetAttributeCount() : int { return 13; }


function LRDebug_GetAttributeLabel(attr : name) : string {
    switch (attr) {
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

function LRDebug_IsAcceleratedAttribute(attr : name) : bool {
    switch (attr) {
        case 'brightness':
        case 'radius':
        case 'attenuation':
        case 'shadowFadeDistance':
        case 'shadowFadeRange':
        case 'shadowBlendFactor':
        case 'alignOffsetZ':
            return true;
    }
    return false;
}

function LRDebug_ClampAttributeValue(attr : name, value : float) : float {
    // alignOffsetZ is the only attribute that can go negative.
    switch (attr) {
        case 'brightness':         return LRDebug_RoundTo01(ClampF(value, 0.0, 100.0));
        case 'radius':             return LRDebug_RoundTo01(ClampF(value, 0.0, 50.0));
        case 'attenuation':        return LRDebug_RoundTo01(ClampF(value, 0.0, 1.0));
        case 'shadowFadeDistance': return LRDebug_RoundTo01(ClampF(value, 0.0, 100.0));
        case 'shadowFadeRange':    return LRDebug_RoundTo01(ClampF(value, 0.0, 100.0));
        case 'shadowBlendFactor':  return LRDebug_RoundTo01(ClampF(value, 0.0, 1.0));
        case 'alignOffsetZ':       return LRDebug_RoundTo01(ClampF(value, -3.0, 3.0));
    }
    return value;
}

/**
 * The core implementation of RoundF() does not play nicely here.
 * RoundF(0.05 * 100.0) / 100.0 == 0.04
 */
function LRDebug_RoundTo01(value : float) : float {
    if (value >= 0.0) return (float)FloorF(value * 100.0 + 0.5) / 100.0;
    return (float)CeilF(value * 100.0 - 0.5) / 100.0;
}

function LRDebug_GetFloatStep(value : float) : float {
    if (value >= 50.0) return 5.0;
    if (value >= 25.0) return 2.5;
    if (value >= 15.0) return 1.0;
    if (value >= 3.5)  return 0.5;
    if (value >= 1.0)  return 0.25;
    if (value >= 0.5)  return 0.1;
    if (value >= 0.1)  return 0.05;
    return 0.01;
}

function LRDebug_GetFloatStepDirectional(value : float, sign : float) : float {
    var floatStep : float = LRDebug_GetFloatStep(value);

    if (sign > 0.0) return floatStep;

    // If decrementing would take us into a lower band, use the lower band's step.
    return MinF(floatStep, LRDebug_GetFloatStep(value - floatStep));
}

function LRDebug_GetDynamicAttributeStep(attr : name, currentValue : float, sign : float) : float {
    switch (attr) {
        case 'alignOffsetZ':
        case 'attenuation':
        case 'shadowBlendFactor':
            return 0.05;
        default:
            return LRDebug_GetFloatStepDirectional(currentValue, sign);
    }
}

function LRDebug_ApplyDynamicFloatDelta(attr : name, currentValue : float, delta : float) : float {
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
        step = LRDebug_GetDynamicAttributeStep(attr, currentValue, sign);
        if (step <= 0.0) break;

        if (step > remaining * sign) step = remaining * sign;

        prevValue = currentValue;
        currentValue = currentValue + (step * sign);
        currentValue = LRDebug_ClampAttributeValue(attr, currentValue);

        // If rounding/clamping prevented any change, stop to avoid getting stuck.
        if (currentValue == prevValue) break;

        remaining = remaining - (step * sign);
        if (currentValue == 0.0 && sign < 0.0) break;
    }

    return currentValue;
}
