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
}

// Store global light rewrite parameters on the game params object.
@addField(W3GameParams) public var LR_ENABLED            : bool;
@addField(W3GameParams) public var LR_CANDLE_BRIGHTNESS  : float;
@addField(W3GameParams) public var LR_CANDLE_RADIUS      : float;
@addField(W3GameParams) public var LR_TORCH_BRIGHTNESS   : float;
@addField(W3GameParams) public var LR_TORCH_RADIUS       : float;
@addField(W3GameParams) public var LR_CANDLE_ATTENUATION : float;
@addField(W3GameParams) public var LR_TORCH_ATTENUATION  : float;
@addField(W3GameParams) public var LR_SHADOW_FADE_DISTANCE : float;
@addField(W3GameParams) public var LR_SHADOW_FADE_RANGE : float;
@addField(W3GameParams) public var LR_SHADOW_BLEND_FACTOR : float;

@addField(W3GameParams) public var LR_OVERRIDE_CANDLE_COLOUR : bool;
@addField(W3GameParams) public var LR_CANDLE_COLOR_R         : int;
@addField(W3GameParams) public var LR_CANDLE_COLOR_G         : int;
@addField(W3GameParams) public var LR_CANDLE_COLOR_B         : int;

@addField(W3GameParams) public var LR_OVERRIDE_TORCH_COLOUR  : bool;
@addField(W3GameParams) public var LR_TORCH_COLOR_R          : int;
@addField(W3GameParams) public var LR_TORCH_COLOR_G          : int;
@addField(W3GameParams) public var LR_TORCH_COLOR_B          : int;

// Tag valid light rewrite entities as they spawn.
@addField(W3GameParams) public var TAG_LR_CANDLE      : name;
@addField(W3GameParams) public var TAG_LR_TORCH       : name;

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

    var brightness, radius, attenuation : float;
    var overrideColour : bool;
    var colorR, colorG, colorB : int;

    var components : array<CComponent> = GetComponentsByClassName('CPointLightComponent');
    var count : int = components.Size();

    var shadowFadeDistance : float = theGame.params.LR_SHADOW_FADE_DISTANCE;
    var shadowFadeRange : float = theGame.params.LR_SHADOW_FADE_RANGE;
    var shadowBlendFactor : float = theGame.params.LR_SHADOW_BLEND_FACTOR;

    if (lightRewriteLightType == LRT_Candle) {
        brightness     = theGame.params.LR_CANDLE_BRIGHTNESS;
        radius         = theGame.params.LR_CANDLE_RADIUS;
        attenuation    = theGame.params.LR_CANDLE_ATTENUATION;
        overrideColour = theGame.params.LR_OVERRIDE_CANDLE_COLOUR;
        colorR         = theGame.params.LR_CANDLE_COLOR_R;
        colorG         = theGame.params.LR_CANDLE_COLOR_G;
        colorB         = theGame.params.LR_CANDLE_COLOR_B;
    }
    else if (lightRewriteLightType == LRT_Torch) {
        brightness     = theGame.params.LR_TORCH_BRIGHTNESS;
        radius         = theGame.params.LR_TORCH_RADIUS;
        attenuation    = theGame.params.LR_TORCH_ATTENUATION;
        overrideColour = theGame.params.LR_OVERRIDE_TORCH_COLOUR;
        colorR         = theGame.params.LR_TORCH_COLOR_R;
        colorG         = theGame.params.LR_TORCH_COLOR_G;
        colorB         = theGame.params.LR_TORCH_COLOR_B;
    }

    // Clusters of candles emit most of their light via a single spotlight.
    // The point lights are used to balance the pre-RT fake scene lighting (blue), so they end up being extremely red with RT on.
    spotLight = (CSpotLightComponent)GetComponent('CSpotLightComponent0');

    for (i = 0; i < count; i += 1) {
        pointLight = (CPointLightComponent)components[i];

        if (pointLight) {
            pointLight.SaveLightRewriteOriginalValues();

            pointLight.SetEnabled(false);

            pointLight.brightness = brightness;
            pointLight.radius = radius;
            pointLight.attenuation = attenuation;
            // pointLight.allowDistantFade = false;
            pointLight.shadowFadeDistance = shadowFadeDistance;
            pointLight.shadowFadeRange = shadowFadeRange;
            pointLight.shadowBlendFactor = shadowBlendFactor;

            if (overrideColour) {
                pointLight.color.Red = colorR;
                pointLight.color.Green = colorG;
                pointLight.color.Blue = colorB;
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

    if (!spawnData.restored && theGame.params.LR_ENABLED) {
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
        AddTag(theGame.params.TAG_LR_CANDLE);
    }
    else if (StrFindFirst(editorName, "torch") != -1) {
        LogLightRewrite("Found torch: " + editorName);

        lightRewriteLightType = LRT_Torch;
        AddTag(theGame.params.TAG_LR_TORCH);
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
