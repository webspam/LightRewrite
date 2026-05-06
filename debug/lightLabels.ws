/**
 * Debug light entites in-game
 *
 * Requires: oneliners via mod_sharedutils_oneliners
 *
 * - Nearby CGameplayEntity instances with point/spot light components: scan 10 m,
 *   show counts. Each entity keeps one LRDebug_EntityLightOneLiner for its
 *   lifetime: out of range or labels toggled off calls unregister; coming
 *   back in range re-uses the same object via register + FollowEntity.
 * - Label markup (HTML for SU_Oneliner) is pushed at register time. The path-labels toggle
 *   is the sole code path that recomputes markup and re-registers; the refresh timer
 *   does no markup work per tick.
 *
 * Example input.settings:
 *
 * IK_NumPad7=(Action=LRDebug_ToggleLabels)
 * IK_NumPad8=(Action=LRDebug_ToggleLabelPaths)
 */

function LRDebug_EscapeHtmlMinimal(str : string) : string {
    var r : string;

    r = StrReplaceAll(str, "&", "&amp;");
    r = StrReplaceAll(r, "<", "&lt;");
    r = StrReplaceAll(r, ">", "&gt;");
    return r;
}

function LRDebug_ToHtmlBlock(size : int, text : string) : string {
    return "<br/><font size='" + size + "'>" + text + "</font>";
}

function LRDebug_CountComponents(entity : CGameplayEntity, className : name) : int {
    var components : array<CComponent> = entity.GetComponentsByClassName(className);
    return components.Size();
}

function LRDebug_GetAttributeCount() : int { return 13; }

function LRDebug_GetAttributeId(idx : int) : name {
    switch (idx) {
        case 0:  return 'brightness';
        case 1:  return 'radius';
        case 2:  return 'attenuation';
        case 3:  return 'shadowFadeDistance';
        case 4:  return 'shadowFadeRange';
        case 5:  return 'shadowBlendFactor';
        case 6:  return 'useSpotlightColor';
        case 7:  return 'alignPointLights';
        case 8:  return 'alignOffsetZ';
        case 9:  return 'overrideColour';
        case 10: return 'colourR';
        case 11: return 'colourG';
        case 12: return 'colourB';
    }
    return 'unknown';
}

function LRDebug_GetAttributeLabel(attr : name) : string {
    switch (attr) {
        case 'brightness':        return "brightness";
        case 'radius':            return "radius";
        case 'attenuation':       return "attenuation";
        case 'shadowFadeDistance': return "shadow distance";
        case 'shadowFadeRange':   return "shadow range";
        case 'shadowBlendFactor': return "shadow blend";
        case 'useSpotlightColor': return "use spotlight colour";
        case 'alignPointLights':  return "align point lights";
        case 'alignOffsetZ':      return "align offset Z";
        case 'overrideColour':    return "override colour";
        case 'colourR':           return "colour R";
        case 'colourG':           return "colour G";
        case 'colourB':           return "colour B";
    }
    return "unknown";
}

function LRDebug_GetAttributeStep(attr : name) : float {
    // Derived from Candle sliders in LightRewrite.xml (except alignOffsetZ, which is explicit).
    switch (attr) {
        case 'brightness':        return 0.5;
        case 'radius':            return 0.5;
        case 'attenuation':       return 0.05;
        case 'shadowFadeDistance': return 0.5;
        case 'shadowFadeRange':   return 0.5;
        case 'shadowBlendFactor': return 0.05;
        case 'alignOffsetZ':      return 0.05;
    }
    return 1.0;
}

function LRDebug_FirstPointLight(entity : CGameplayEntity) : CPointLightComponent {
    return (CPointLightComponent)entity.GetComponent('CPointLightComponent0');
}

function LRDebug_FirstSpotLight(entity : CGameplayEntity) : CSpotLightComponent {
    return (CSpotLightComponent)entity.GetComponent('CSpotLightComponent0');
}

function LRDebug_GetAttributeValueString(entity : CGameplayEntity, attr : name) : string {
    var params : CLightRewriteSourceParams;
    var point : CPointLightComponent;
    var valF : float;
    var valI : int;

    if (!entity) return "?";

    params = entity.lrDebugTempParams;
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

function LRDebug_GuessRewriterType(entity : CGameplayEntity) : ELightRewriteType {
    var desc : string = entity.ToString();
    if (StrFindFirst(desc, "candle") != -1) return LRT_Candle;
    return LRT_Unknown;
}

@addMethod(ILightSourceRewriter)
public function LRDebug_SetMenuOverrideParams(p : CLightRewriteSourceParams) {
    this.menuOverrideParams = p;
}

@addMethod(ILightSourceRewriter)
public function LRDebug_ClearMenuOverrideParams() {
    this.menuOverrideParams = NULL;
}

function LRDebug_EnsureEntityHasRewriter(entity : CGameplayEntity) : ILightSourceRewriter {
    var params : CLightRewriteSourceParams;
    var rewriter : ILightSourceRewriter;

    if (!entity) return NULL;
    if (entity.lightSourceRewriter) return entity.lightSourceRewriter;

    params = theGame.GetLightRewriteSettings().FindParamsForEntity(entity);
    if (!params) {
        params = new CLightRewriteSourceParams in entity;
        params.hasEnabled = true;
        params.enabled = true;
        params.hasRewriterType = true;
        params.rewriterType = LRDebug_GuessRewriterType(entity);
        params.tag = 'LR_DebugTemp';
        params.displayName = "debug";
    }

    entity.bypassLightRewrite = false;
    rewriter = theGame.lightRewrite.CreateRewriterFromParams(params, entity);
    entity.lightSourceRewriter = rewriter;
    return rewriter;
}

function LRDebug_GetCameraPositionAndDirection(out camPos : Vector, out camDir : Vector) {
    var director : CCameraDirector = theGame.GetWorld().GetCameraDirector();
    if (!director) return;

    camPos = director.GetCameraPosition();
    camDir = director.GetCameraDirection();
}

function LRDebug_FindNearbyLights(out entities : array<CGameplayEntity>) {
    var maxRange : float;

    if (theGame.IsFocusModeActive()) maxRange = 25.0;
    else maxRange = 10.0;

    FindGameplayEntitiesInRange(entities, thePlayer, maxRange, 1024, , FLAG_ExcludePlayer);
}

statemachine class LRDebug_LightOneLiner extends SU_Oneliner {
    public var entity : CGameplayEntity;
    public var pointLights, spotLights : int;
    public var active : bool;
    public var highlighted : bool;

    public function Init(tracked_entity : CGameplayEntity, pointLights_ : int, spotLights_ : int) {
        this.entity = tracked_entity;
        this.pointLights = pointLights_;
        this.spotLights = spotLights_;
        this.text = LRDebug_GenerateText();
    }

    // Changes to text require re-registering the oneliner
    public function LRDebug_RegenerateText() {
        this.text = LRDebug_GenerateText();
        this.update();
    }

    public function LRDebug_Start() {
        if (this.active) return;

        this.active = true;
        this.GotoState('FollowEntity');
    }

    public function LRDebug_SetHighlighted(highlighted : bool) {
        this.highlighted = highlighted;
        this.LRDebug_RegenerateText();
    }

    private function CountToHtml(prefix : string, count : int) : string {
        var html : string = "<font color='";

        if (count > 0) html += "#00ff00";
        else html += "#aaaaaa";

        return html + "'>" + prefix + " " + count + "</font>";
    }

    /**
     * Example entity.ToString():
     * ```
     * CLayer "full\editor\level\path.somext"::full\path\to\entity.w2ent
     * ```
     */
    private function LRDebug_GenerateText() : string {
        var layerPart, entityPath, levelPath, fileName, filePath, pointsColour, spotsColour, body : string;
        var headerHtml : string;
        var attrId : name;
        var attrLabel : string;
        var attrValue : string;

        var descriptor : string = entity.ToString();
        var fontSize : int = 13;
        var countString : string = CountToHtml("P", pointLights) + " / " + CountToHtml("S", spotLights);
        var marker : string = "<font color='#ff0000'>-</font> ";

        if (this.highlighted) {
            countString = marker + countString + " <font color='#ff0000'>-</font>";

            attrId = LRDebug_GetAttributeId(thePlayer.lrDebugAttrIndex);
            attrLabel = LRDebug_GetAttributeLabel(attrId);
            attrValue = LRDebug_GetAttributeValueString(entity, attrId);
            headerHtml = "<font color='#ff0000'>" + attrLabel + ": " + attrValue + "</font><br/>";
        }
        body = "<font size='" + fontSize + "'>" + headerHtml + countString + "</font>";

        if (pointLights > 0) pointsColour = "#";
        else pointsColour = "black";
        if (spotLights > 0) spotsColour = "red";
        else spotsColour = "black";

        if (thePlayer.lrDebugShowPathLabels) {
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
                // Fallback to just displaying the descriptor as the file path
                filePath = descriptor;
            }

            if (fileName != "") {
                body += LRDebug_ToHtmlBlock(fontSize + 3, LRDebug_EscapeHtmlMinimal(fileName));
            }
            if (filePath != "") {
                body += LRDebug_ToHtmlBlock(fontSize - 1, LRDebug_EscapeHtmlMinimal(filePath));
            }
            if (levelPath != "") {
                body += LRDebug_ToHtmlBlock(fontSize + 2, LRDebug_EscapeHtmlMinimal(levelPath));
            }
        }

        return body;
    }
}

state Idle in LRDebug_LightOneLiner {}

state FollowEntity in LRDebug_LightOneLiner {
    private const var NORMAL_RANGE : float; default NORMAL_RANGE = 10.0;
    private const var FOCUS_RANGE  : float; default FOCUS_RANGE  = 25.0;

    event OnEnterState(previous_state_name : name) {
        super.OnEnterState(previous_state_name);

        parent.register();
        FollowEntity();
    }

    event OnLeaveState(next_state_name : name) {
        parent.unregister();

        super.OnLeaveState(next_state_name);
    }

    entry function FollowEntity() : void {
        var maxRange : float = FOCUS_RANGE;

        while (
            thePlayer.lrDebugLabels &&
            VecDistanceSquared(thePlayer.GetWorldPosition(), parent.entity.GetWorldPosition()) <= (maxRange * maxRange)
        ) {
            parent.position = parent.entity.GetWorldPosition() + Vector(0, 0, 0.25f);
            SleepOneFrame();

            if (theGame.IsFocusModeActive()) maxRange = FOCUS_RANGE;
            else maxRange = NORMAL_RANGE;
        }

        parent.active = false;
        parent.GotoState('Idle');
    }
}

@addField(CR4Player) private var lrdebugTagSeq : int;
@addField(CR4Player) public var lrDebugLabels : bool;
@addField(CR4Player) public var lrDebugShowPathLabels : bool;
@addField(CR4Player) private var lrDebugTarget : CGameplayEntity;
@addField(CR4Player) public var lrDebugAttrIndex : int;

@addField(CGameplayEntity) public var lrdebugOneliner : LRDebug_LightOneLiner;
@addField(CGameplayEntity) public var lrDebugTempParams : CLightRewriteSourceParams;

@wrapMethod(CR4Player)
function OnSpawned(spawnData : SEntitySpawnData) {
    wrappedMethod(spawnData);

    AddTimer('LRDebug_DeferredLabelInstall', 1.f, false);
}

@addMethod(CR4Player)
timer function LRDebug_DeferredLabelInstall(dt : float, id : int) {
    if (!theGame || !thePlayer) return;

    theInput.RegisterListener(this, 'LRDebug_OnInputToggleLabels', 'LRDebug_ToggleLabels');
    theInput.RegisterListener(this, 'LRDebug_OnInputToggleLabelPaths', 'LRDebug_ToggleLabelPaths');
    theInput.RegisterListener(this, 'LRDebug_OnInputCycleAttrPrev', 'LRDebug_CycleAttrPrev');
    theInput.RegisterListener(this, 'LRDebug_OnInputCycleAttrNext', 'LRDebug_CycleAttrNext');
    theInput.RegisterListener(this, 'LRDebug_OnInputAdjustDown', 'LRDebug_AdjustDown');
}

@addMethod(CR4Player)
timer function LRDebug_RefreshOnelinersTimer(dt : float, id : int) {
    var entities : array<CGameplayEntity>;
    var entity : CGameplayEntity;
    var i, count, pointLights, spotLights : int;
    var camPos, camDir, entPos, toEnt : Vector;
    var score, bestScore, dot, visibilityRange : float;
    var bestEntity : CGameplayEntity;

    if (!this.lrDebugLabels || !theGame || !thePlayer) return;

    LRDebug_FindNearbyLights(entities);

    bestScore = -1.0;
    bestEntity = NULL;
    LRDebug_GetCameraPositionAndDirection(camPos, camDir);
    camDir = VecNormalize(camDir);

    if (theGame.IsFocusModeActive()) visibilityRange = 25.0;
    else visibilityRange = 10.0;

    count = entities.Size();
    for (i = 0; i < count; i += 1) {
        entity = entities[i];
        if (!entity) continue;

        if (entity.lrdebugOneliner) {
            entity.lrdebugOneliner.LRDebug_Start();
        }
        else {
            pointLights = LRDebug_CountComponents(entity, 'CPointLightComponent');
            spotLights = LRDebug_CountComponents(entity, 'CSpotLightComponent');
            if (pointLights == 0 && spotLights == 0) continue;

            LRDebug_CreateOnelinerForEntity(entity, pointLights, spotLights);
        }

        entPos = entity.GetWorldPosition();
        if (VecDistanceSquared(thePlayer.GetWorldPosition(), entPos) > (visibilityRange * visibilityRange)) continue;

        toEnt = entPos - camPos;
        if (VecLengthSquared(toEnt) < 0.001) continue;

        toEnt = VecNormalize(toEnt);
        dot = VecDot(toEnt, camDir);
        score = dot * 4.0;

        // Rough in-front filter to reduce “behind camera” picks
        if (dot < 0.6) continue;

        if (score > bestScore) {
            bestScore = score;
            bestEntity = entity;
        }
    }

    if (bestEntity != this.lrDebugTarget) {
        if (this.lrDebugTarget && this.lrDebugTarget.lrdebugOneliner) {
            this.lrDebugTarget.lrdebugOneliner.LRDebug_SetHighlighted(false);
        }

        this.lrDebugTarget = bestEntity;

        if (this.lrDebugTarget && this.lrDebugTarget.lrdebugOneliner) {
            this.lrDebugTarget.lrdebugOneliner.LRDebug_SetHighlighted(true);
        }
    }
}

@addMethod(CR4Player)
private function LRDebug_CreateOnelinerForEntity(
    entity : CGameplayEntity,
    pointLights : int,
    spotLights : int
) {
    var label : LRDebug_LightOneLiner = new LRDebug_LightOneLiner in entity;

    label.Init(entity, pointLights, spotLights);

    this.lrdebugTagSeq += 1;
    label.setTag("lrdebug-" + this.lrdebugTagSeq);

    entity.lrdebugOneliner = label;
    label.LRDebug_Start();
}

@addMethod(CR4Player)
public function LRDebug_OnInputToggleLabels(action : SInputAction) : bool {
    if (!IsPressed(action) || !thePlayer) return false;

    this.lrDebugLabels = !this.lrDebugLabels;
    LogChannel('LRDebug', "LRDebug_Toggle: " + this.lrDebugLabels);

    RemoveTimer('LRDebug_RefreshOnelinersTimer');
    if (this.lrDebugLabels) {
        AddTimer('LRDebug_RefreshOnelinersTimer', 0.25f, true);
    }

    return true;
}

@addMethod(CR4Player)
public function LRDebug_OnInputToggleLabelPaths(action : SInputAction) : bool {
    var entities : array<CGameplayEntity>;
    var i, count : int;

    if (!IsPressed(action) || !thePlayer) return false;

    this.lrDebugShowPathLabels = !this.lrDebugShowPathLabels;

    LRDebug_FindNearbyLights(entities);

    count = entities.Size();
    for (i = 0; i < count; i += 1) {
        if (!entities[i].lrdebugOneliner) continue;

        entities[i].lrdebugOneliner.LRDebug_RegenerateText();
    }

    return true;
}

@addMethod(CR4Player)
private function LRDebug_CycleAttribute(delta : int) {
    var count : int = LRDebug_GetAttributeCount();
    if (count <= 0) return;

    this.lrDebugAttrIndex += delta;
    while (this.lrDebugAttrIndex < 0) this.lrDebugAttrIndex += count;
    while (this.lrDebugAttrIndex >= count) this.lrDebugAttrIndex -= count;

    if (this.lrDebugTarget && this.lrDebugTarget.lrdebugOneliner) {
        this.lrDebugTarget.lrdebugOneliner.LRDebug_RegenerateText();
    }
}

@addMethod(CR4Player)
public function LRDebug_OnInputCycleAttrPrev(action : SInputAction) : bool {
    if (!IsPressed(action) || !thePlayer) return false;
    LRDebug_CycleAttribute(-1);
    return true;
}

@addMethod(CR4Player)
public function LRDebug_OnInputCycleAttrNext(action : SInputAction) : bool {
    if (!IsPressed(action) || !thePlayer) return false;
    LRDebug_CycleAttribute(1);
    return true;
}

@addMethod(CGameplayEntity)
public function LRDebug_EnsureTempParams() : CLightRewriteSourceParams {
    if (!lrDebugTempParams) {
        lrDebugTempParams = new CLightRewriteSourceParams in this;
        lrDebugTempParams.hasEnabled = true;
        lrDebugTempParams.enabled = true;
    }
    return lrDebugTempParams;
}

function LRDebug_IsCandle(entity : CGameplayEntity) : bool {
    return StrFindFirst(entity.ToString(), "candle") != -1 && StrFindFirst(entity.ToString(), "candle_holder") == -1;
}

@addMethod(CR4Player)
private function LRDebug_AdjustTargetedAttribute(sign : int) {
    var target : CGameplayEntity = this.lrDebugTarget;
    var attr : name = LRDebug_GetAttributeId(this.lrDebugAttrIndex);
    var step : float;
    var point : CPointLightComponent;
    var spot : CSpotLightComponent;
    var sourceLight : CLightComponent;
    var params : CLightRewriteSourceParams;
    var rewriter : ILightSourceRewriter;

    if (!target) return;
    if (!target.lrdebugOneliner) return;

    rewriter = LRDebug_EnsureEntityHasRewriter(target);
    if (!rewriter) return;

    params = target.LRDebug_EnsureTempParams();
    if (!params) return;

    point = LRDebug_FirstPointLight(target);
    spot = LRDebug_FirstSpotLight(target);
    step = LRDebug_GetAttributeStep(attr);

    if (spot && spot.IsEnabled() && LRDebug_IsCandle(target)) {
        sourceLight = spot;
    }
    else {
        sourceLight = point;
    }

    switch (attr) {
        case 'brightness':
            if (!params.hasBrightness) {
                params.hasBrightness = true;
                if (sourceLight) params.brightness = sourceLight.brightness;
            }
            params.brightness += (step * sign);
            break;

        case 'radius':
            if (!params.hasRadius) {
                params.hasRadius = true;
                if (sourceLight) params.radius = sourceLight.radius;
            }
            params.radius += step * sign;
            break;

        case 'attenuation':
            if (!params.hasAttenuation) {
                params.hasAttenuation = true;
                if (sourceLight) params.attenuation = sourceLight.attenuation;
            }
            params.attenuation += step * sign;
            break;

        case 'shadowFadeDistance':
            if (!params.hasShadowFadeDistance) {
                params.hasShadowFadeDistance = true;
                if (sourceLight) params.shadowFadeDistance = sourceLight.shadowFadeDistance;
            }
            params.shadowFadeDistance += step * sign;
            break;

        case 'shadowFadeRange':
            if (!params.hasShadowFadeRange) {
                params.hasShadowFadeRange = true;
                if (sourceLight) params.shadowFadeRange = sourceLight.shadowFadeRange;
            }
            params.shadowFadeRange += step * sign;
            break;

        case 'shadowBlendFactor':
            if (!params.hasShadowBlendFactor) {
                params.hasShadowBlendFactor = true;
                if (sourceLight) params.shadowBlendFactor = sourceLight.shadowBlendFactor;
            }
            params.shadowBlendFactor += step * sign;
            break;

        case 'useSpotlightColor':
            params.hasUseSpotlightColor = true;
            params.useSpotlightColor = (sign > 0);
            break;

        case 'alignPointLights':
            params.hasAlignPointLights = true;
            params.alignPointLights = (sign > 0);
            break;

        case 'alignOffsetZ':
            if (!params.hasAlignPointLights) {
                params.hasAlignPointLights = true;
                params.alignPointLights = true;
            }
            params.pointLightOffset.Z += step * sign;
            break;

        case 'overrideColour':
            params.hasColour = (sign > 0);
            if (params.hasColour && point) {
                params.color = sourceLight.color;
            }
            break;

        case 'colourR':
            if (!params.hasColour) {
                params.hasColour = true;
                if (sourceLight) params.color = sourceLight.color;
            }
            params.color.Red = (byte)Clamp(params.color.Red + sign, 0, 255);
            break;

        case 'colourG':
            if (!params.hasColour) {
                params.hasColour = true;
                if (sourceLight) params.color = sourceLight.color;
            }
            params.color.Green = (byte)Clamp(params.color.Green + sign, 0, 255);
            break;

        case 'colourB':
            if (!params.hasColour) {
                params.hasColour = true;
                if (sourceLight) params.color = sourceLight.color;
            }
            params.color.Blue = (byte)Clamp(params.color.Blue + sign, 0, 255);
            break;
    }

    rewriter.LRDebug_SetMenuOverrideParams(params);
    rewriter.RewriteLight();
    target.lrdebugOneliner.LRDebug_RegenerateText();
}

@addMethod(CR4Player)
public function LRDebug_OnInputAdjustDown(action : SInputAction) : bool {
    var sign : int;

    if (!action.value) return false;

    // Convert from +/- 3.0 (or any other value) to (int)+/-1
    if (action.value > 0.0) sign = 1;
    else sign = -1;

    LRDebug_AdjustTargetedAttribute(sign);
    return true;
}
