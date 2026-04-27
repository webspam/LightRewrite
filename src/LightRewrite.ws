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

// Store global light rewrite parameters on the game params object.
// These defaults are overwritten at runtime by CLightRewriteSettings.ReadGameConfig().
@addField(W3GameParams) public var LR_ENABLED            : bool;
@addField(W3GameParams) public var LR_CANDLE_BRIGHTNESS  : float;
@addField(W3GameParams) public var LR_CANDLE_RADIUS      : float;
@addField(W3GameParams) public var LR_TORCH_BRIGHTNESS   : float;
@addField(W3GameParams) public var LR_TORCH_RADIUS       : float;
@addField(W3GameParams) public var LR_ATTENUATION        : float;
@addField(W3GameParams) public var LR_SHADOW_FADE_DISTANCE : float;
@addField(W3GameParams) public var LR_SHADOW_FADE_RANGE : float;
@addField(W3GameParams) public var LR_SHADOW_BLEND_FACTOR : float;

@wrapMethod(W3GameParams)
function Init() {
    LR_ENABLED            = true;
    LR_CANDLE_BRIGHTNESS  = 5.5f;
    LR_CANDLE_RADIUS      = 9.f;
    LR_TORCH_BRIGHTNESS   = 30.f;
    LR_TORCH_RADIUS       = 20.f;
    LR_ATTENUATION        = 1.0f;
    LR_SHADOW_FADE_DISTANCE = 10.f;
    LR_SHADOW_FADE_RANGE = 3.f;
    LR_SHADOW_BLEND_FACTOR = 1.f;

    return wrappedMethod();
}

// Rewrite a single candle / torch entity
@addMethod(CGameplayEntity)
function CandleLightRewrite(brightness, radius : float) {
    var spotLight : CSpotLightComponent;
    var pointLight : CPointLightComponent;
    var i : int;

    var components : array<CComponent> = GetComponentsByClassName('CPointLightComponent');
    var count : int = components.Size();

    var attenuation : float = theGame.params.LR_ATTENUATION;
    var shadowFadeDistance : float = theGame.params.LR_SHADOW_FADE_DISTANCE;
    var shadowFadeRange : float = theGame.params.LR_SHADOW_FADE_RANGE;
    var shadowBlendFactor : float = theGame.params.LR_SHADOW_BLEND_FACTOR;

    // Clusters of candles emit most of their light via a single spotlight.
    // The point lights are used to balance the pre-RT fake scene lighting (blue), so they end up being extremely red with RT on.
    spotLight = (CSpotLightComponent)GetComponent('CSpotLightComponent0');

    for (i = 0; i < count; i += 1) {
        pointLight = (CPointLightComponent)components[i];

        if (pointLight) {
            pointLight.SetEnabled(false);

            pointLight.brightness = brightness;
            pointLight.radius = radius;
            pointLight.attenuation = attenuation;
            // pointLight.allowDistantFade = false;
            pointLight.shadowFadeDistance = shadowFadeDistance;
            pointLight.shadowFadeRange = shadowFadeRange;
            pointLight.shadowBlendFactor = shadowBlendFactor;

            // Take the color from the spotlight component.
            if (spotLight) {
                pointLight.color.Red = spotLight.color.Red;
                pointLight.color.Green = spotLight.color.Green;
                pointLight.color.Blue = spotLight.color.Blue;
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

        if (lightComponent) lightComponent.SetEnabled(false);
    }
}

// Identify light sources, and rewrite matched entities to work properly with RT.
@wrapMethod(CGameplayEntity)
function OnSpawned(spawnData : SEntitySpawnData) {
    var isCandle : bool;
    var isTorch : bool;
    var editorName, discard : string;

    if (!spawnData.restored && theGame.params.LR_ENABLED && HasTag(theGame.params.TAG_OPEN_FIRE)) {
        editorName = StrAfterLast(ToString(), StrChar(92));

        isCandle = StrFindFirst(editorName, "candle") != -1;
        isTorch = StrFindFirst(editorName, "torch") != -1;

        LogLightRewrite("Spawned: " + editorName + " -- isCandle: " + isCandle + " / isTorch: " + isTorch);

        if (isCandle) CandleLightRewrite(theGame.params.LR_CANDLE_BRIGHTNESS, theGame.params.LR_CANDLE_RADIUS);
        else if (isTorch) CandleLightRewrite(theGame.params.LR_TORCH_BRIGHTNESS, theGame.params.LR_TORCH_RADIUS);
    }

    wrappedMethod(spawnData);
}
