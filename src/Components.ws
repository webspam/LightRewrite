// Stores the original values of a light component before it is rewritten.
struct SLightRewriteOriginalValues {
    var hasBeenSaved : bool;

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

// Saves the original values of the light component.
@addMethod(CLightComponent)
public function SaveLightRewriteOriginalValues() {
    if (lightRewriteOriginalValues.hasBeenSaved) return;

    lightRewriteOriginalValues.hasBeenSaved = true;

    lightRewriteOriginalValues.brightness = brightness;
    lightRewriteOriginalValues.radius = radius;
    lightRewriteOriginalValues.attenuation = attenuation;
    lightRewriteOriginalValues.shadowFadeDistance = shadowFadeDistance;
    lightRewriteOriginalValues.shadowFadeRange = shadowFadeRange;
    lightRewriteOriginalValues.shadowBlendFactor = shadowBlendFactor;
    lightRewriteOriginalValues.color = color;
}

// Restores the light component to its original values.
@addMethod(CLightComponent)
public function RestoreLightRewriteOriginalValues() {
    var wasEnabled : bool;

    if (!lightRewriteOriginalValues.hasBeenSaved) return;

    wasEnabled = IsEnabled();
    if (wasEnabled) SetEnabled(false);

    brightness = lightRewriteOriginalValues.brightness;
    radius = lightRewriteOriginalValues.radius;
    attenuation = lightRewriteOriginalValues.attenuation;
    shadowFadeDistance = lightRewriteOriginalValues.shadowFadeDistance;
    shadowFadeRange = lightRewriteOriginalValues.shadowFadeRange;
    shadowBlendFactor = lightRewriteOriginalValues.shadowBlendFactor;
    color = lightRewriteOriginalValues.color;

    if (wasEnabled) SetEnabled(true);
}
