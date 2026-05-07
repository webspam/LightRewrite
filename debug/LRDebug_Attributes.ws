/**
 * Attribute registry and step-math for the LRDebug light editing system.
 *
 * All functions are pure (no engine state, no side effects).
 * The 13 editable attributes are indexed 0–12.
 */





// RoundF() is not used here because RoundF(0.05 * 100.0) / 100.0 == 0.04.
function LRDebug_ClampAttributeValue(attr : name, value : float) : float {
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
