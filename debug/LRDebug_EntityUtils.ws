/**
 * Entity and component utilities for the LRDebug light editing system.
 *
 * - Free functions for component/rewriter access
 * - @addField and @addMethod extensions on CGameplayEntity and ILightSourceRewriter
 * - @wrapMethod hooks that track inOriginalState on ILightSourceRewriter
 */

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

// ---- Component helpers ----

function LRDebug_FirstPointLight(entity : CGameplayEntity) : CPointLightComponent {
    return (CPointLightComponent)entity.GetComponent('CPointLightComponent0');
}

function LRDebug_FirstSpotLight(entity : CGameplayEntity) : CSpotLightComponent {
    return (CSpotLightComponent)entity.GetComponent('CSpotLightComponent0');
}

function LRDebug_CountComponents(entity : CGameplayEntity, className : name) : int {
    var components : array<CComponent> = entity.GetComponentsByClassName(className);
    return components.Size();
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

// ---- Attribute value display ----

function LRDebug_GetAttributeValueString(entity : CGameplayEntity, attr : name) : string {
    var params : CLightRewriteSourceParams;
    var point : CPointLightComponent;
    var valF : float;
    var valI : int;

    if (!entity) return "?";

    params = entity.lrDebugParams;
    point = LRDebug_FirstPointLight(entity);

    switch (attr) {
        case 'brightness':
            if (params && params.hasBrightness) valF = params.brightness;
            else if (point) valF = point.brightness;
            return FloatToString(valF);

        case 'radius':
            if (params && params.hasRadius) valF = params.radius;
            else if (point) valF = point.radius;
            return FloatToString(valF);

        case 'attenuation':
            if (params && params.hasAttenuation) valF = params.attenuation;
            else if (point) valF = point.attenuation;
            return FloatToString(valF);

        case 'shadowFadeDistance':
            if (params && params.hasShadowFadeDistance) valF = params.shadowFadeDistance;
            else if (point) valF = point.shadowFadeDistance;
            return FloatToString(valF);

        case 'shadowFadeRange':
            if (params && params.hasShadowFadeRange) valF = params.shadowFadeRange;
            else if (point) valF = point.shadowFadeRange;
            return FloatToString(valF);

        case 'shadowBlendFactor':
            if (params && params.hasShadowBlendFactor) valF = params.shadowBlendFactor;
            else if (point) valF = point.shadowBlendFactor;
            return FloatToString(valF);

        case 'useSpotlightColor':
            if (params && params.hasUseSpotlightColor) {
                if (params.useSpotlightColor) return "true";
                return "false";
            }
            return "?";

        case 'alignPointLights':
            if (params && params.hasAlignPointLights) {
                if (params.alignPointLights) return "true";
                return "false";
            }
            return "?";

        case 'alignOffsetZ':
            if (params && params.hasAlignPointLights) valF = params.pointLightOffset.Z;
            else valF = 0.0;
            return FloatToString(valF);

        case 'overrideColour':
            if (params && params.hasColour) return "true";
            return "false";

        case 'colourR':
            if (params && params.hasColour) valI = params.color.Red;
            else if (point) valI = point.color.Red;
            return IntToString(valI);

        case 'colourG':
            if (params && params.hasColour) valI = params.color.Green;
            else if (point) valI = point.color.Green;
            return IntToString(valI);

        case 'colourB':
            if (params && params.hasColour) valI = params.color.Blue;
            else if (point) valI = point.color.Blue;
            return IntToString(valI);
    }

    return "?";
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

// ---- World/camera helpers ----

function LRDebug_GetCameraPositionAndDirection(out cameraPosition : Vector, out cameraDirection : Vector) {
    var director : CCameraDirector = theGame.GetWorld().GetCameraDirector();

    cameraPosition = director.GetCameraPosition();
    cameraDirection = director.GetCameraDirection();
}

function LRDebug_FindNearbyLights(out entities : array<CGameplayEntity>) {
    var maxRange : float = 10.0;

    if (theGame.IsFocusModeActive()) maxRange = 25.0;
    FindGameplayEntitiesInRange(entities, thePlayer, maxRange, 1024, , FLAG_ExcludePlayer);
}
