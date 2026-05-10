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
public var lightRewrite: CLightRewriteManager;

@wrapMethod(CR4Game)
function OnGameStarting(restored : bool) {
    wrappedMethod(restored);

    lightRewrite = new CLightRewriteManager in this;
    lightRewrite.Init(GetLightRewriteSettings());
}

@wrapMethod(CR4Game)
function OnGameStarted(restored : bool) {
    wrappedMethod(restored);
    lightRewrite.ProcessDeferredActions();
}

// Enable to bypass the mod.  When true, all Light Rewrite logic will quickly return without acting.
// If this is false, lightSourceRewriter will likely be NULL.
@addField(CGameplayEntity) public var bypassLightRewrite : bool;
// Before accessing, confirm that bypassLightRewrite is false.
@addField(CGameplayEntity) public var lightSourceRewriter : ILightSourceRewriter;

@addMethod(CGameplayEntity)
public function HasRewritableLight() : bool {
    return
        GetComponentsCountByClassName('CPointLightComponent') > 0 ||
        GetComponentsCountByClassName('CSpotLightComponent') > 0;
}

// Identify light sources, and rewrite matched entities to work properly with RT.
@addMethod(CGameplayEntity)
protected function InitialiseLightRewrite() {
    if (!HasRewritableLight()) return;

    AddTag(theGame.lightRewrite.TAG_HAS_LIGHT);

    LightRewriteProfileChanged();
}

@addMethod(CGameplayEntity)
public function LightRewriteProfileChanged() {
    var params: CLightRewriteSourceParams = theGame.GetLightRewriteSettings().FindParamsForEntity(this);

    // Always reset to baseline; profiles aren't guaranteed to alter the same fields
    if (lightSourceRewriter) lightSourceRewriter.RestoreOriginalState();

    bypassLightRewrite = !params;
    if (bypassLightRewrite) return;

    // TODO: Confirm if discarding the previous rewriter has any impact on memory (at least until loading another zone)
    lightSourceRewriter = theGame.lightRewrite.CreateRewriterFromParams(params, this);

    if (theGame.GetLightRewriteSettings().isEnabled && IsLightRewritable()) {
        lightSourceRewriter.RewriteLight();
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
@wrapMethod(W3Campfire)
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
        lightSourceRewriter.RewriteLight();
    }
}

// This entity is a valid light rewrite target.
@addMethod(CGameplayEntity)
public function IsLightRewritable() : bool {
    return !bypassLightRewrite && lightSourceRewriter.IsEnabled();
}

@addMethod(CGameplayEntity)
timer function LightRewriteDisableSpotlights(dt : float, id : int) {
    if (!bypassLightRewrite && lightSourceRewriter) {
        lightSourceRewriter.DisableAllSpotlightComponents();
    }
}
