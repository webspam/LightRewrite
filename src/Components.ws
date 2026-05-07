// Stores the original values of a light component before it is rewritten.
struct SLightRewriteOriginalValues {
    var hasBeenSaved : bool;

    var enabled : bool;
    var position : Vector;
    var brightness : float;
    var radius : float;
    var attenuation : float;
    var shadowFadeDistance : float;
    var shadowFadeRange : float;
    var shadowBlendFactor : float;
    var color : Color;
}

// The original values of the light component.
@addField(CLightComponent) public var lightRewriteOriginalValues : SLightRewriteOriginalValues;

// Saves the current state of the light component as its original values, unless it has already been saved.
@addMethod(CLightComponent)
public function SaveLightRewriteOriginalValues() {
    if (lightRewriteOriginalValues.hasBeenSaved) return;

    lightRewriteOriginalValues.hasBeenSaved = true;

    lightRewriteOriginalValues.enabled = IsEnabled();
    lightRewriteOriginalValues.position = GetLocalPosition();
    lightRewriteOriginalValues.brightness = brightness;
    lightRewriteOriginalValues.radius = radius;
    lightRewriteOriginalValues.attenuation = attenuation;
    lightRewriteOriginalValues.shadowFadeDistance = shadowFadeDistance;
    lightRewriteOriginalValues.shadowFadeRange = shadowFadeRange;
    lightRewriteOriginalValues.shadowBlendFactor = shadowBlendFactor;
    lightRewriteOriginalValues.color = color;
}

// Restores the light component to its original values.
// Note: this will restore the original enabled state, which may have been changed.
// As it stands, I cannot find a way to intercept calls to SetEnabled to track state changes.
@addMethod(CLightComponent)
public function RestoreLightRewriteOriginalValues() {
    if (!lightRewriteOriginalValues.hasBeenSaved) return;

    if (IsEnabled()) SetEnabled(false);

    SetPosition(lightRewriteOriginalValues.position);
    brightness = lightRewriteOriginalValues.brightness;
    radius = lightRewriteOriginalValues.radius;
    attenuation = lightRewriteOriginalValues.attenuation;
    shadowFadeDistance = lightRewriteOriginalValues.shadowFadeDistance;
    shadowFadeRange = lightRewriteOriginalValues.shadowFadeRange;
    shadowBlendFactor = lightRewriteOriginalValues.shadowBlendFactor;
    color = lightRewriteOriginalValues.color;

    if (lightRewriteOriginalValues.enabled) SetEnabled(true);
}
