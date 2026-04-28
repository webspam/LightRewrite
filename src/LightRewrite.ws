// Below classes are already imported by modSharedImports

// import class CLightComponent extends CSpriteComponent {
//     import var radius : float;
//     import var brightness : float;
//     import var attenuation : float;
//     import var color : Color;
//     import var allowDistantFade : bool;
//     import var shadowFadeDistance : float;
//     import var shadowFadeRange : float;
//     import var shadowBlendFactor : float;
// }

// import class CSpotLightComponent extends CLightComponent {}

enum ELightRewriteType {
    LRT_None,
    LRT_Unknown,
    LRT_Candle,
    LRT_Torch,
    LRT_Brazier,
}

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

@addField(CLightComponent) public var lightRewriteOriginalValues : SLightRewriteOriginalValues;

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

@addMethod(CLightComponent)
public function RestoreLightRewriteOriginalValues() {
    if (!lightRewriteOriginalValues.hasBeenSaved) return;

    SetEnabled(false);
    
    brightness = lightRewriteOriginalValues.brightness;
    radius = lightRewriteOriginalValues.radius;
    attenuation = lightRewriteOriginalValues.attenuation;
    shadowFadeDistance = lightRewriteOriginalValues.shadowFadeDistance;
    shadowFadeRange = lightRewriteOriginalValues.shadowFadeRange;
    shadowBlendFactor = lightRewriteOriginalValues.shadowBlendFactor;
    color = lightRewriteOriginalValues.color;

    SetEnabled(true);
}

@addField(CGameplayEntity) public var lightRewriteLightType : ELightRewriteType;

// Rewrite a single candle / torch entity
@addMethod(CGameplayEntity)
function CandleLightRewrite() {
    var spotLight : CSpotLightComponent;
    var pointLight : CPointLightComponent;
    var i : int;
    var sourceParams : CLightRewriteSourceParams;

    var components : array<CComponent> = GetComponentsByClassName('CPointLightComponent');
    var count : int = components.Size();

    var settings : CLightRewriteSettings = theGame.GetLightRewriteSettings();

    if (lightRewriteLightType == LRT_Candle) {
        sourceParams = settings.candleParams;
    }
    else if (lightRewriteLightType == LRT_Torch) {
        sourceParams = settings.torchParams;
    }
    else if (lightRewriteLightType == LRT_Brazier) {
        sourceParams = settings.brazierParams;
    }
    else {
        LogLightRewrite("Invalid light rewrite type: " + lightRewriteLightType);
        return;
    }

    // Clusters of candles emit most of their light via a single spotlight.
    // The point lights are used to balance the pre-RT fake scene lighting (blue), so they end up being extremely red with RT on.
    spotLight = (CSpotLightComponent)GetComponent('CSpotLightComponent0');

    for (i = 0; i < count; i += 1) {
        pointLight = (CPointLightComponent)components[i];

        if (pointLight) {
            pointLight.SaveLightRewriteOriginalValues();

            pointLight.SetEnabled(false);

            pointLight.brightness = sourceParams.brightness;
            pointLight.radius = sourceParams.radius;
            pointLight.attenuation = sourceParams.attenuation;

            pointLight.shadowFadeDistance = settings.shadowFadeDistance;
            pointLight.shadowFadeRange = settings.shadowFadeRange;
            pointLight.shadowBlendFactor = settings.shadowBlendFactor;

            if (sourceParams.shouldOverrideColour) {
                pointLight.color = sourceParams.color;
            }
            else if (spotLight) {
                pointLight.color = spotLight.color;
            }
            else {
                // No spotlight, and we're not overriding the colour, so use the original colour.
                pointLight.color = pointLight.lightRewriteOriginalValues.color;
            }

            pointLight.SetEnabled(true);
        }
    }

    // Remove spotlights from candles that have point lights (should be all candles).
    if (count > 0) DisableAllSpotlightComponents();
}

// Disable all of this entity's spotlight components.
@addMethod(CGameplayEntity)
function DisableAllSpotlightComponents() {
    var lightComponent : CSpotLightComponent;
    var i : int;

    var components : array<CComponent> = GetComponentsByClassName('CSpotLightComponent');
    var count : int = components.Size();

    for (i = 0; i < count; i += 1) {
        lightComponent = (CSpotLightComponent)components[i];

        if (lightComponent) {
            lightComponent.SaveLightRewriteOriginalValues();
            lightComponent.SetEnabled(false);
        }
    }
}

// Identify light sources, and rewrite matched entities to work properly with RT.
@wrapMethod(CGameplayEntity)
function OnSpawned(spawnData : SEntitySpawnData) {
    var editorName : string;

    if (!spawnData.restored && theGame.GetLightRewriteSettings().isEnabled) {
        IdentifyLightRewriteType();

        if (IsLightRewritable()) CandleLightRewrite();
    }

    wrappedMethod(spawnData);
}

@wrapMethod(CGameplayEntity)
function AddTag(tag : name) {
    wrappedMethod(tag);

    if (tag == theGame.params.TAG_OPEN_FIRE) {
        IdentifyLightRewriteType();
    }
}

// This entity has already confirmed its light rewrite type.
@addMethod(CGameplayEntity)
public function HasCheckedLightRewriteType() : bool {
    return lightRewriteLightType != LRT_None;
}

// This entity is a valid light rewrite target.
@addMethod(CGameplayEntity)
public function IsLightRewritable() : bool {
    return lightRewriteLightType != LRT_Unknown && lightRewriteLightType != LRT_None;
}

// If this is an open fire, identify the light rewrite type of this entity.
@addMethod(CGameplayEntity)
public function IdentifyLightRewriteType() {
    var editorName : string;

    if (HasCheckedLightRewriteType()) return;

    editorName = StrAfterLast(ToString(), StrChar(92));

    if (StrFindFirst(editorName, "candle") != -1) {
        LogLightRewrite("Found candle: " + editorName);

        lightRewriteLightType = LRT_Candle;
        AddTag(theGame.GetLightRewriteSettings().candleParams.tag);
    }
    else if (StrFindFirst(editorName, "torch") != -1) {
        LogLightRewrite("Found torch: " + editorName);

        lightRewriteLightType = LRT_Torch;
        AddTag(theGame.GetLightRewriteSettings().torchParams.tag);
    }
    else if (StrFindFirst(editorName, "brazier") != -1) {
        LogLightRewrite("Found brazier: " + editorName);

        lightRewriteLightType = LRT_Brazier;
        AddTag(theGame.GetLightRewriteSettings().brazierParams.tag);
    }
    else {
        lightRewriteLightType = LRT_Unknown;
    }
}

@addMethod(CGameplayEntity)
function DisableLightRewrite() {
    var spotLight : CSpotLightComponent;
    var pointLight : CPointLightComponent;
    var i : int;

    var components : array<CComponent> = GetComponentsByClassName('CPointLightComponent');
    var count : int = components.Size();

    for (i = 0; i < count; i += 1) {
        pointLight = (CPointLightComponent)components[i];

        if (pointLight) {
            pointLight.RestoreLightRewriteOriginalValues();
        }
    }

    // Remove spotlights from candles that have point lights (should be all candles).
    if (count > 0) {
        components = GetComponentsByClassName('CSpotLightComponent');
        count = components.Size();

        for (i = 0; i < count; i += 1) {
            spotLight = (CSpotLightComponent)components[i];

            if (spotLight) {
                spotLight.RestoreLightRewriteOriginalValues();
                spotLight.SetEnabled(true);
            }
        }
    }
}

function LogLightRewrite(msg : string) {
    LogChannel('LightRewrite', msg);
}
