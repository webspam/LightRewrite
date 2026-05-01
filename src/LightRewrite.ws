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

// The Light Rewrite module singleton.
@addField(CR4Game)
public var lightRewrite : CLightRewriteManager;

@wrapMethod(CR4Game)
function OnGameStarting(restored : bool) {
    wrappedMethod(restored);

    lightRewrite = new CLightRewriteManager in this;
    lightRewrite.Init(GetLightRewriteSettings());
}

// Enable to bypass the mod.  When true, all Light Rewrite logic will quickly return without acting.
// If this is false, lightSourceRewriter will likely be NULL.
@addField(CGameplayEntity) public var bypassLightRewrite : bool;
// Before accessing, confirm that bypassLightRewrite is false.
@addField(CGameplayEntity) public var lightSourceRewriter : ILightSourceRewriter;

// Identify light sources, and rewrite matched entities to work properly with RT.
@addMethod(CGameplayEntity)
protected function InitialiseLightRewrite() {
    var params : CLightRewriteSourceParams = theGame.GetLightRewriteSettings().FindParamsForEntity(this);

    // Not a valid light source.
    if (!params) {
        bypassLightRewrite = true;
        return;
    }

    lightSourceRewriter = theGame.lightRewrite.CreateRewriterFromParams(params, this);

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

    if (bypassLightRewrite) return;

    if (
        tag == theGame.params.TAG_OPEN_FIRE &&
        theGame.GetLightRewriteSettings().isEnabled &&
        IsLightRewritable()
    ) {
        lightSourceRewriter.CandleLightRewrite();
    }
}

// This entity is a valid light rewrite target.
@addMethod(CGameplayEntity)
public function IsLightRewritable() : bool {
    return !bypassLightRewrite && lightSourceRewriter.IsEnabled();
}
