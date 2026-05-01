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
    LRT_Candelabra,
    LRT_Campfire,
    LRT_Chandelier,
}

// The light rewriter singleton.
@addField(CR4Game)
public var lightRewriter : CLightRewriter;

@wrapMethod(CR4Game)
function OnGameStarting(restored : bool) {
    wrappedMethod(restored);

    lightRewriter = new CLightRewriter in this;
    lightRewriter.Init(GetLightRewriteSettings());
}

@addField(CGameplayEntity) public var lightRewriteLightType : ELightRewriteType;
@addField(CGameplayEntity) public var lightSourceRewriter : ILightSourceRewriter;

// Identify light sources, and rewrite matched entities to work properly with RT.
@addMethod(CGameplayEntity)
protected function InitialiseLightRewrite() {
    IdentifyLightRewriteType();
    if (lightSourceRewriter) lightSourceRewriter.Init(this);

    if (theGame.GetLightRewriteSettings().isEnabled) {
        if (IsLightRewritable()) lightSourceRewriter.CandleLightRewrite();
    }
}

// We must wrap the OnSpawned methods of multiple classes with broken inheritance chains
@wrapMethod(CGameplayEntity)
function OnSpawned(spawnData : SEntitySpawnData) {
    if (!spawnData.restored) InitialiseLightRewrite();
    wrappedMethod(spawnData);
}
@wrapMethod(CInteractiveEntity)
function OnSpawned(spawnData : SEntitySpawnData) {
    if (!spawnData.restored) InitialiseLightRewrite();
    wrappedMethod(spawnData);
}
@wrapMethod(W3FireSource)
function OnSpawned(spawnData : SEntitySpawnData) {
    if (!spawnData.restored) InitialiseLightRewrite();
    wrappedMethod(spawnData);
}

// Ensure lights that are ignited (e.g. by the player) are rewritten.
@wrapMethod(CGameplayEntity)
function AddTag(tag : name) {
    wrappedMethod(tag);

    if (tag == theGame.params.TAG_OPEN_FIRE) {
        IdentifyLightRewriteType();

        if (theGame.GetLightRewriteSettings().isEnabled && IsLightRewritable()) {
            lightSourceRewriter.CandleLightRewrite();
        }
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
    var sourceParams : CLightRewriteSourceParams = theGame.GetLightRewriteSettings().GetParamsForType(lightRewriteLightType);

    return lightSourceRewriter && sourceParams && sourceParams.enabled;
}

// If this is an open fire, identify the light rewrite type of this entity.
@addMethod(CGameplayEntity)
public function IdentifyLightRewriteType() {
    var editorName : string;
    var genericRewriter : CGenericLightRewriter;

    if (HasCheckedLightRewriteType()) return;

    editorName = StrAfterLast(ToString(), StrChar(92));

    if (StrFindFirst(editorName, "candelabra") != -1) {
        LogLightRewrite("Found candelabra: " + ToString());

        lightRewriteLightType = LRT_Candelabra;

        genericRewriter = new CGenericLightRewriter in this;
        genericRewriter.SetParams(theGame.GetLightRewriteSettings().candelabraParams);
        lightSourceRewriter = genericRewriter;
    }
    else if (StrFindFirst(editorName, "chandelier") != -1) {
        LogLightRewrite("Found chandelier: " + ToString());

        lightRewriteLightType = LRT_Chandelier;

        genericRewriter = new CGenericLightRewriter in this;
        genericRewriter.SetParams(theGame.GetLightRewriteSettings().chandelierParams);
        lightSourceRewriter = genericRewriter;
    }
    else if (StrFindFirst(editorName, "candle") != -1) {
        LogLightRewrite("Found candle: " + ToString());

        lightRewriteLightType = LRT_Candle;

        lightSourceRewriter = new CCandleLightRewriter in this;
    }
    else if (StrFindFirst(editorName, "torch") != -1) {
        LogLightRewrite("Found torch: " + ToString());

        lightRewriteLightType = LRT_Torch;

        genericRewriter = new CGenericLightRewriter in this;
        genericRewriter.SetParams(theGame.GetLightRewriteSettings().torchParams);
        lightSourceRewriter = genericRewriter;
    }
    else if (StrFindFirst(editorName, "brazier") != -1) {
        LogLightRewrite("Found brazier: " + ToString());

        lightRewriteLightType = LRT_Brazier;

        genericRewriter = new CGenericLightRewriter in this;
        genericRewriter.SetParams(theGame.GetLightRewriteSettings().brazierParams);
        lightSourceRewriter = genericRewriter;
    }
    else if (StrFindFirst(editorName, "campfire") != -1) {
        LogLightRewrite("Found campfire: " + ToString());

        lightRewriteLightType = LRT_Campfire;

        genericRewriter = new CGenericLightRewriter in this;
        genericRewriter.SetParams(theGame.GetLightRewriteSettings().campfireParams);
        lightSourceRewriter = genericRewriter;
    }
    else {
        lightRewriteLightType = LRT_Unknown;
    }
}
