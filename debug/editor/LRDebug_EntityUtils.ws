/**
 * Entity and component utilities for the LRDebug light editing system.
 *
 * - Free functions for component/rewriter access
 * - @addField and @addMethod extensions on CGameplayEntity and ILightSourceRewriter
 * - @wrapMethod hooks that track inOriginalState on ILightSourceRewriter
 */

// ---- Component helpers ----

function LRDebug_FirstPointLight(entity : CGameplayEntity) : CPointLightComponent {
    var components: array<CComponent>;
    components = entity.GetComponentsByClassName('CPointLightComponent');
    if (components.Size() > 0) return (CPointLightComponent)components[0];
    return NULL;
}

function LRDebug_FirstSpotLight(entity : CGameplayEntity) : CSpotLightComponent {
    var components: array<CComponent>;
    components = entity.GetComponentsByClassName('CSpotLightComponent');
    if (components.Size() > 0) return (CSpotLightComponent)components[0];
    return NULL;
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

/** Lazy getter. Copies current effective params on first call. */
@addMethod(CGameplayEntity)
public function LRDebug_GetParams(rewriter : ILightSourceRewriter) : CLightRewriteSourceParams {
    if (!lrDebugParams) {
        lrDebugParams = new CLightRewriteSourceParams in this;

        rewriter.LRDebug_GetEffectiveParams().ApplyTo(lrDebugParams);
        lrDebugParams.hasEnabled = true;
        lrDebugParams.enabled = true;
    }
    return lrDebugParams;
}

// ---- ILightSourceRewriter extensions ----

/** Whether the rewriter is in its original state */
@addField(ILightSourceRewriter) public var inOriginalState : bool;

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

@addMethod(ILightSourceRewriter)
public function LRDebug_GetEffectiveParams() : CLightRewriteSourceParams {
    return GetEffectiveParams();
}

// Override rewriter params

@addMethod(ILightSourceRewriter)
public function LRDebug_SetMenuOverrideParams(params : CLightRewriteSourceParams) {
    this.menuOverrideParams = params;
}

@addMethod(ILightSourceRewriter)
public function LRDebug_ClearMenuOverrideParams() {
    this.menuOverrideParams = NULL;
}

// ---- Rewriter access ----

/**
 * This is a slight clobbering of the Light Rewrite logic, that ensures the debug system works
 * correctly. Any entities not covered by the active Light Rewrite profile will be given a
 * debug rewriter.
 */
@addMethod(CGameplayEntity)
public function LRDebug_GetOrCreateRewriter() : ILightSourceRewriter {
    var params: CLightRewriteSourceParams;

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
