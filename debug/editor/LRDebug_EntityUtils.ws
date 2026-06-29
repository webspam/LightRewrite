/**
 * Entity and component utilities for the LRDebug light editing system.
 *
 * - Free functions for component/rewriter access
 * - @addField and @addMethod extensions on CGameplayEntity and ILightSourceRewriter
 * - @wrapMethod hooks that track inOriginalState on ILightSourceRewriter
 */

// ---- Component helpers ----

function LRDebug_FirstPointLight(entity: CGameplayEntity): CPointLightComponent {
    var components: array<CComponent>;
    components = entity.GetComponentsByClassName('CPointLightComponent');
    if (components.Size() > 0) return (CPointLightComponent)components[0];
    return NULL;
}

function LRDebug_FirstSpotLight(entity: CGameplayEntity): CSpotLightComponent {
    var components: array<CComponent>;
    components = entity.GetComponentsByClassName('CSpotLightComponent');
    if (components.Size() > 0) return (CSpotLightComponent)components[0];
    return NULL;
}

// ---- Entity classification ----

function LRDebug_IsCandle(entity: CGameplayEntity): bool {
    return StrFindFirst(entity.ToString(), "candle") != -1 &&
        StrFindFirst(entity.ToString(), "candle_holder") == -1;
}

function LRDebug_GuessRewriterType(entity: CGameplayEntity): ELightRewriteType {
    if (LRDebug_IsCandle(entity)) return LRT_Candle;
    return LRT_Unknown;
}

// ---- Path label ----

/**
 * Example entity.ToString():
 * ```
 * CLayer "full\editor\level\path.somext"::full\path\to\entity.w2ent
 * ```
 */
function LRDebug_BuildPathLabel(entity: CGameplayEntity): string {
    var descriptor, layerPart, entityPath, levelPath, fileName, filePath, html: string;
    var fontSize: int;

    if (!entity) return "";

    fontSize = 13;
    descriptor = entity.ToString();

    if (StrFindFirst(descriptor, "::") != -1) {
        layerPart = StrBeforeFirst(descriptor, "::");
        entityPath = StrAfterFirst(descriptor, "::");
        levelPath = layerPart;

        if (StrFindFirst(layerPart, "\"") != -1) {
            levelPath = StrBeforeFirst(StrAfterFirst(layerPart, "\""), "\"");
        }

        fileName = StrAfterLast(entityPath, StrChar(92));
        filePath = StrBeforeLast(entityPath, StrChar(92));
    }
    else {
        // Fallback: the raw descriptor when it has no layer/entity split
        filePath = descriptor;
    }

    html = LRDebug_AppendPathLine(html, fileName, fontSize + 3);
    html = LRDebug_AppendPathLine(html, filePath, fontSize - 1);
    html = LRDebug_AppendPathLine(html, levelPath, fontSize + 2);
    return html;
}

function LRDebug_AppendPathLine(html: string, text: string, size: int): string {
    if (text == "") return html;
    if (html != "") html += "<br/>";
    return html + "<font size='" + size + "'>" + LRDebug_EscapeHtml(text) + "</font>";
}

function LRDebug_EscapeHtml(str: string): string {
    var r: string;

    r = StrReplaceAll(str, "&", "&amp;");
    r = StrReplaceAll(r, "<", "&lt;");
    r = StrReplaceAll(r, ">", "&gt;");
    return r;
}

// ---- CGameplayEntity extensions ----

/** The params used to edit the light source */
@addField(CGameplayEntity) public var lrDebugParams: CLightRewriteSourceParams;

/** Pre-edit snapshot the export diffs against, so profile-inherited values aren't re-emitted */
@addField(CGameplayEntity) public var lrDebugBaseline: CLightRewriteSourceParams;

@addField(CGameplayEntity) public var lrDebugSpotOwned: bool;

/** Lazy getter. Copies current effective params on first call, keeping a baseline for the export */
@addMethod(CGameplayEntity)
public function LRDebug_GetParams(rewriter: ILightSourceRewriter): CLightRewriteSourceParams {
    var effective: CLightRewriteSourceParams;

    if (!lrDebugParams) {
        lrDebugParams = new CLightRewriteSourceParams in this;
        lrDebugBaseline = new CLightRewriteSourceParams in this;

        effective = rewriter.LRDebug_GetEffectiveParams();
        effective.ApplyTo(lrDebugParams);
        effective.ApplyTo(lrDebugBaseline);

        // A profile with no spotlight still needs a baseline to diff a mid-session spotlight against
        if (!lrDebugBaseline.spotlight) {
            lrDebugBaseline.spotlight = new CLightRewriteSpotlightParams in this;
        }

        lrDebugParams.enabled.has = true;
        lrDebugParams.enabled.value = true;
    }
    return lrDebugParams;
}

@addMethod(CGameplayEntity)
public function LRDebug_ClearDebugParams() {
    lrDebugParams = NULL;
    lrDebugBaseline = NULL;
    lrDebugSpotOwned = false;
}

// ---- ILightSourceRewriter extensions ----

/** Whether the rewriter is in its original state */
@addField(ILightSourceRewriter) public var inOriginalState: bool;

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
public function LRDebug_GetEffectiveParams(): CLightRewriteSourceParams {
    return GetEffectiveParams();
}

// Override rewriter params

@addMethod(ILightSourceRewriter)
public function LRDebug_SetMenuOverrideParams(params: CLightRewriteSourceParams) {
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
public function LRDebug_GetOrCreateRewriter(): ILightSourceRewriter {
    var params: CLightRewriteSourceParams;

    if (lightSourceRewriter) return lightSourceRewriter;

    params = theGame.GetLightRewriteSettings().FindParamsForEntity(this);
    if (!params) {
        params = new CLightRewriteSourceParams in this;
        params.enabled.has = true;
        params.enabled.value = true;
        params.rewriterType.has = true;
        params.rewriterType.value = LRDebug_GuessRewriterType(this);
        params.tag = 'LR_DebugLight';
        params.displayName = "debug";
    }

    bypassLightRewrite = false;
    lightSourceRewriter = theGame.lightRewrite.CreateRewriterFromParams(params, this);
    return lightSourceRewriter;
}
