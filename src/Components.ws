// Stores the original values of a light component before it is rewritten.
struct SLightRewriteOriginalValues {
    var hasBeenSaved: bool;

    var enabled           : bool;
    var position          : Vector;
    var brightness        : float;
    var radius            : float;
    var attenuation       : float;
    var shadowFadeDistance: float;
    var shadowFadeRange   : float;
    var shadowBlendFactor : float;
    var shadowCastingMode : ELightShadowCastingMode;
    var color             : Color;
}

// The original values of the light component.
@addField(CLightComponent) public var lightRewriteOriginalValues: SLightRewriteOriginalValues;

// Saves the current state of the light component as its original values, unless it has already been saved.
@addMethod(CLightComponent)
public function SaveLightRewriteOriginalValues() {
    if (lightRewriteOriginalValues.hasBeenSaved) return;

    lightRewriteOriginalValues.hasBeenSaved = true;

    lightRewriteOriginalValues.position = GetLocalPosition();
    lightRewriteOriginalValues.brightness = brightness;
    lightRewriteOriginalValues.radius = radius;
    lightRewriteOriginalValues.attenuation = attenuation;
    lightRewriteOriginalValues.shadowFadeDistance = shadowFadeDistance;
    lightRewriteOriginalValues.shadowFadeRange = shadowFadeRange;
    lightRewriteOriginalValues.shadowBlendFactor = shadowBlendFactor;
    lightRewriteOriginalValues.shadowCastingMode = shadowCastingMode;
    lightRewriteOriginalValues.color = color;
}

function LR_ShadowCastWeight(mode: ELightShadowCastingMode): int {
    switch (mode) {
        case LSCM_Normal:       return 3;
        case LSCM_OnlyStatic:   return 2;
        case LSCM_OnlyDynamic:  return 1;
        default:                return 0;
    }
}

// Strongest shadow caster, or most central
function LR_MainPointLight(entity: CGameplayEntity): CPointLightComponent {
    var components: array<CComponent>;
    var candidates: array<CPointLightComponent>;
    var light: CPointLightComponent;
    var bestWeight, weight, i, count: int;

    components = entity.GetComponentsByClassName('CPointLightComponent');
    count = components.Size();

    if (count == 0) return NULL;
    if (count == 1) return (CPointLightComponent)components[0];

    bestWeight = -1;
    for (i = 0; i < count; i += 1) {
        light = (CPointLightComponent)components[i];
        if (!light) continue;
        weight = LR_ShadowCastWeight(light.shadowCastingMode);
        if (weight > bestWeight) bestWeight = weight;
    }

    for (i = 0; i < count; i += 1) {
        light = (CPointLightComponent)components[i];
        if (!light) continue;
        if (LR_ShadowCastWeight(light.shadowCastingMode) == bestWeight) candidates.PushBack(light);
    }

    return LR_CentralPointLight(candidates);
}

function LR_CentralPointLight(lights: array<CPointLightComponent>): CPointLightComponent {
    var centroid, pos, posB: Vector;
    var bestDist, dist: float;
    var bestIdx, i, count: int;

    count = lights.Size();

    if (count == 0) return NULL;
    if (count == 1) return lights[0];

    // A pair has no centre, so the raised light reads as the main one
    if (count == 2) {
        pos = lights[0].GetWorldPosition();
        posB = lights[1].GetWorldPosition();
        if (posB.Z > pos.Z) return lights[1];
        return lights[0];
    }

    for (i = 0; i < count; i += 1) {
        pos = lights[i].GetWorldPosition();
        centroid.X += pos.X;
        centroid.Y += pos.Y;
        centroid.Z += pos.Z;
    }
    centroid.X /= count;
    centroid.Y /= count;
    centroid.Z /= count;

    bestIdx = 0;
    bestDist = VecDistanceSquared(lights[0].GetWorldPosition(), centroid);
    for (i = 1; i < count; i += 1) {
        dist = VecDistanceSquared(lights[i].GetWorldPosition(), centroid);
        if (dist < bestDist) {
            bestDist = dist;
            bestIdx = i;
        }
    }
    return lights[bestIdx];
}

// Restores the light component to its original values.
@addMethod(CLightComponent)
public function RestoreLightRewriteOriginalValues(useEnabled: bool, optional enabled: bool) {
    var wasEnabled: bool;

    if (!lightRewriteOriginalValues.hasBeenSaved) return;

    wasEnabled = IsEnabled();
    if (wasEnabled) SetEnabled(false);

    SetPosition(lightRewriteOriginalValues.position);
    brightness = lightRewriteOriginalValues.brightness;
    radius = lightRewriteOriginalValues.radius;
    attenuation = lightRewriteOriginalValues.attenuation;
    shadowFadeDistance = lightRewriteOriginalValues.shadowFadeDistance;
    shadowFadeRange = lightRewriteOriginalValues.shadowFadeRange;
    shadowBlendFactor = lightRewriteOriginalValues.shadowBlendFactor;
    shadowCastingMode = lightRewriteOriginalValues.shadowCastingMode;
    color = lightRewriteOriginalValues.color;

    // The caller provided the parent entity's current enabled state
    if (useEnabled) {
        if (enabled) SetEnabled(enabled);
    }
    // Theoretically, this could result in light state corruption when toggling the mod OFF
    // It is unlikely once we're closer to full release and should be guarded against elsewhere
    else if (wasEnabled) {
        SetEnabled(true);
    }
}
