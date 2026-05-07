/**
 * Entity and component utilities for the LRDebug light editing system.
 *
 * - Free functions for component/rewriter access
 * - @addField and @addMethod extensions on CGameplayEntity and ILightSourceRewriter
 * - @wrapMethod hooks that track inOriginalState on ILightSourceRewriter
 */

// ---- Component helpers ----

function LRDebug_FirstPointLight(entity : CGameplayEntity) : CPointLightComponent {
    return (CPointLightComponent)entity.GetComponent('CPointLightComponent0');
}

function LRDebug_FirstSpotLight(entity : CGameplayEntity) : CSpotLightComponent {
    return (CSpotLightComponent)entity.GetComponent('CSpotLightComponent0');
}

// ---- Entity classification ----

function LRDebug_IsCandle(entity : CGameplayEntity) : bool {
    return StrFindFirst(entity.ToString(), "candle") != -1
        && StrFindFirst(entity.ToString(), "candle_holder") == -1;
}

function LRDebug_GuessRewriterType(entity : CGameplayEntity) : ELightRewriteType {
    if (LRDebug_IsCandle(entity)) return LRT_Candle;
    return LRT_Unknown;
}

// ---- CGameplayEntity extensions ----

/** The params used to edit the light source */
@addField(CGameplayEntity) public var lrDebugParams : CLightRewriteSourceParams;

/** Lazy getter */
@addMethod(CGameplayEntity)
public function LRDebug_GetParams() : CLightRewriteSourceParams {
    if (!lrDebugParams) {
        lrDebugParams = new CLightRewriteSourceParams in this;
        lrDebugParams.hasEnabled = true;
        lrDebugParams.enabled = true;
    }
    return lrDebugParams;
}

// ---- ILightSourceRewriter extensions ----

@addField(ILightSourceRewriter) public var inOriginalState : bool;

@addMethod(ILightSourceRewriter)
public function LRDebug_SetMenuOverrideParams(params : CLightRewriteSourceParams) {
    this.menuOverrideParams = params;
}

@addMethod(ILightSourceRewriter)
public function LRDebug_ClearMenuOverrideParams() {
    this.menuOverrideParams = NULL;
}

// Track inOriginalState as rewriters are applied or restored.

@wrapMethod(CCandleLightRewriter)
function RewriteLight() {
    wrappedMethod();
    inOriginalState = false;
}

@wrapMethod(CGenericLightRewriter)
function RewriteLight() {
    wrappedMethod();
    inOriginalState = false;
}

@wrapMethod(ILightSourceRewriter)
function RestoreOriginalState() {
    wrappedMethod();
    inOriginalState = true;
}

// ---- Rewriter access ----

/**
 * This is a slight clobbering of the Light Rewrite logic, that ensures the debug system works
 * correctly. Any entities not covered by the active Light Rewrite profile will be given a
 * debug rewriter.
 */
@addMethod(CGameplayEntity)
public function LRDebug_GetOrCreateRewriter() : ILightSourceRewriter {
    var params : CLightRewriteSourceParams;

    if (lightSourceRewriter) return lightSourceRewriter;

    params = theGame.GetLightRewriteSettings().FindParamsForEntity(this);
    if (!params) {
        params = new CLightRewriteSourceParams in this;
        params.hasEnabled = true;
        params.enabled = true;
        params.hasRewriterType = true;
        params.rewriterType = LRDebug_GuessRewriterType(this);
        params.tag = 'LR_DebugLight';
        params.displayName = "debug";
    }

    bypassLightRewrite = false;
    lightSourceRewriter = theGame.lightRewrite.CreateRewriterFromParams(params, this);
    return lightSourceRewriter;
}
