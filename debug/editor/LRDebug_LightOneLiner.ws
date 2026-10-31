/**
 * Floating label that tracks a light-bearing CGameplayEntity in world space.
 *
 * One instance is created per entity and reused for its lifetime.
 * The label transitions between Idle and FollowEntity states rather than
 * being destroyed and recreated as the player moves in and out of range.
 *
 * Markup is only regenerated on explicit events (highlight change, path-label
 * toggle, attribute cycle). The FollowEntity loop does no markup work per tick.
 */

@addField(CGameplayEntity) public var lrdebugOneliner: LRDebug_LightOneLiner;

statemachine class LRDebug_LightOneLiner extends LRDebug_WorldMarker {
    public var entity     : CGameplayEntity;
    public var pointLights: int;
    public var spotLights : int;
    public var active     : bool;
    public var highlighted: bool;

    public function InitForEntity(
        id: int,
        tracked_entity: CGameplayEntity,
        pointLights_: int,
        spotLights_: int
    ) {
        this.entity = tracked_entity;
        this.pointLights = pointLights_;
        this.spotLights = spotLights_;
        Init(GenerateText(), id);
    }

    public function RegenerateText() {
        SetText(GenerateText());
    }

    public function Start() {
        if (this.active) return;

        this.active = true;
        this.GotoState('FollowEntity');
    }

    public function SetHighlighted(isHighlighted: bool) {
        this.highlighted = isHighlighted;
        this.RegenerateText();
    }

    private function CountToHtml(prefix: string, count: int): string {
        var html: string = "<font color='";

        if (count > 0) html += "#00ff00";
        else html += "#aaaaaa";

        return html + "'>" + prefix + " " + count + "</font>";
    }

    private function ActiveCountToHtml(prefix: string, count: int, activeIndex: int): string {
        if (count < 2) return CountToHtml(prefix, count);
        return "<font color='#00ff00'>" + prefix + " " + (activeIndex + 1) + "/" + count + "</font>";
    }

    public function GetAttributeValueString(attr: name, type: name): string {
        var params: CLightRewriteSourceParams;
        var lightParams: ILightRewriteParams;
        var spotlight: CLightRewriteSpotlightParams;
        var light: CLightComponent;
        var spotComp: CSpotLightComponent;
        var position: Vector;
        var rotation: EulerAngles;
        var valF: float;
        var valI: int;
        var activeIndex: int;

        if (!entity) return "?";

        params = entity.lrDebugParams;

        // Toggled off: drop overrides so every branch falls through to the live original values
        if (params && entity.lightSourceRewriter && entity.lightSourceRewriter.inOriginalState) {
            params = NULL;
        }

        activeIndex = thePlayer.lrDebugAttrEditor.GetActiveLightIndex(entity, type);

        if (type == 'spot') {
            if (params) {
                spotlight = params.GetEffectiveSpotLightParams(activeIndex);
                lightParams = spotlight;
            }
            spotComp = LRDebug_SpotLightAt(entity, activeIndex);
            light = spotComp;
        }
        else {
            if (params) lightParams = params.GetEffectivePointLightParams(activeIndex);
            light = LRDebug_PointLightAt(entity, activeIndex);
        }

        switch (attr) {
            case 'brightness':
                if (light) valF = light.brightness;
                if (lightParams && lightParams.brightness) {
                    valF = lightParams.brightness.Resolve(valF);
                }
                return FloatToString(valF);

            case 'radius':
                if (light) valF = light.radius;
                if (lightParams && lightParams.radius) valF = lightParams.radius.Resolve(valF);
                return FloatToString(valF);

            case 'attenuation':
                if (light) valF = light.attenuation;
                if (lightParams && lightParams.attenuation) {
                    valF = lightParams.attenuation.Resolve(valF);
                }
                return FloatToString(valF);

            case 'shadowFadeDistance':
                if (light) valF = light.shadowFadeDistance;
                if (lightParams && lightParams.shadowFadeDistance) {
                    valF = lightParams.shadowFadeDistance.Resolve(valF);
                }
                return FloatToString(valF);

            case 'shadowFadeRange':
                if (light) valF = light.shadowFadeRange;
                if (lightParams && lightParams.shadowFadeRange) {
                    valF = lightParams.shadowFadeRange.Resolve(valF);
                }
                return FloatToString(valF);

            case 'shadowBlendFactor':
                if (lightParams && lightParams.shadowBlendFactor.has) {
                    valF = lightParams.shadowBlendFactor.value;
                }
                else if (light) {
                    valF = light.shadowBlendFactor;
                }
                return FloatToString(valF);

            case 'useSpotlightColor':
                if (type == 'spot') return "n/a";
                if (params && params.useSpotlightColor.has) {
                    if (params.useSpotlightColor.value) return "true";
                    return "false";
                }
                return "?";

            case 'alignPointLights':
                if (type == 'spot') return "n/a";
                if (params && params.alignPointLights.has) {
                    if (params.alignPointLights.value) return "true";
                    return "false";
                }
                return "?";

            case 'alignOffsetZ':
                if (entity.LRDebug_UsesFireFxOffset(type)) {
                    if (params && params.alignPointLights.has) valF = params.pointLightOffset.Z;
                    return FloatToString(valF);
                }
                if (type == 'spot') {
                    if (spotlight && spotlight.offset.has) {
                        valF = spotlight.offset.value.Z;
                    }
                    else if (spotComp) {
                        position = spotComp.GetLocalPosition();
                        valF = position.Z;
                    }
                    return FloatToString(valF);
                }
                if (lightParams && lightParams.offset.has) {
                    valF = lightParams.offset.value.Z;
                }
                else if (light) {
                    position = light.GetLocalPosition();
                    valF = position.Z;
                }
                return FloatToString(valF);

            case 'innerAngle':
                if (spotlight && spotlight.innerAngle.has) valF = spotlight.innerAngle.value;
                else if (spotComp) valF = spotComp.innerAngle;
                return FloatToString(valF);

            case 'outerAngle':
                if (spotlight && spotlight.outerAngle.has) valF = spotlight.outerAngle.value;
                else if (spotComp) valF = spotComp.outerAngle;
                return FloatToString(valF);

            case 'softness':
                if (spotlight && spotlight.softness.has) valF = spotlight.softness.value;
                else if (spotComp) valF = spotComp.softness;
                return FloatToString(valF);

            case 'rotation':
                rotation = SpotRotation(spotlight, spotComp);
                return FloatToString(rotation.Pitch) + ", "
                    + FloatToString(rotation.Yaw) + ", "
                    + FloatToString(rotation.Roll);

            case 'rotationPitch':
                rotation = SpotRotation(spotlight, spotComp);
                return FloatToString(rotation.Pitch);

            case 'rotationYaw':
                rotation = SpotRotation(spotlight, spotComp);
                return FloatToString(rotation.Yaw);

            case 'rotationRoll':
                rotation = SpotRotation(spotlight, spotComp);
                return FloatToString(rotation.Roll);

            case 'overrideColour':
                if (lightParams && lightParams.color.has) return "true";
                return "false";

            case 'colourR':
                if (lightParams && lightParams.color.has) valI = lightParams.color.value.Red;
                else if (light) valI = light.color.Red;
                return IntToString(valI);

            case 'colourG':
                if (lightParams && lightParams.color.has) valI = lightParams.color.value.Green;
                else if (light) valI = light.color.Green;
                return IntToString(valI);

            case 'colourB':
                if (lightParams && lightParams.color.has) valI = lightParams.color.value.Blue;
                else if (light) valI = light.color.Blue;
                return IntToString(valI);

            case 'shadowMode':
                if (lightParams && lightParams.castShadows.has) {
                    return ShadowModeLabel(lightParams.castShadows.value);
                }
                else if (light) {
                    return ShadowModeLabel(light.shadowCastingMode);
                }
                return "?";
        }

        return "?";
    }

    private function SpotRotation(
        spotlight: CLightRewriteSpotlightParams,
        spotComp: CSpotLightComponent
    ): EulerAngles {
        var rotation: EulerAngles;

        if (spotlight && spotlight.rotation.has) return spotlight.rotation.value;
        if (spotComp) rotation = spotComp.GetLocalRotation();
        return rotation;
    }

    private function ToHtmlBlock(text: string, size: int, optional colour: string): string {
        var colourAttr: string;

        if (colour != "") colourAttr = " color='" + colour + "'";
        return "<br/><font size='" + size + "'" + colourAttr + ">" + text + "</font>";
    }

    private function ShadowModeLabel(mode: ELightShadowCastingMode): string {
        switch (mode) {
            case LSCM_None:         return "None";
            case LSCM_Normal:       return "Normal";
            case LSCM_OnlyDynamic:  return "OnlyDynamic";
            case LSCM_OnlyStatic:   return "OnlyStatic";
        }
        return "?";
    }

    private function ShadowLineHtml(prefix: string, light: CLightComponent, fontSize: int): string {
        var text: string = prefix + ": " + ShadowModeLabel(light.shadowCastingMode);

        if (light.shadowCastingMode == LSCM_None) {
            return ToHtmlBlock(text, fontSize, "#999999");
        }
        return ToHtmlBlock(text, fontSize);
    }

    private function UsageMaskLineHtml(
        prefix: string,
        light: CLightComponent,
        params: CLightRewriteSourceParams,
        type: name,
        index: int,
        fontSize: int
    ): string {
        var edit: SLightRewriteUsageMaskEdit = LRDebug_EffectiveUsageMask(params, type, index);
        var liveMask: int = light.LR_GetLightUsageMask();

        return ToHtmlBlock(
            prefix + ": "
                + UsageFlagHtml(edit, liveMask, LRLUM_ExcludeFromSceneRender) + "  "
                + UsageFlagHtml(edit, liveMask, LRLUM_RenderToEnvProbe) + "  "
                + UsageFlagHtml(edit, liveMask, LRLUM_InteriorOnly) + "  "
                + UsageFlagHtml(edit, liveMask, LRLUM_ExteriorOnly),
            fontSize
        );
    }

    private function UsageFlagHtml(
        edit: SLightRewriteUsageMaskEdit,
        liveMask: int,
        flag: ELightRewriteUsageMask
    ): string {
        var liveOn: bool = (liveMask & (int)flag) != 0;
        var colour: string;

        switch (LRDebug_GetUsageFlagState(edit, flag)) {
            case LRDebug_LUM_On:   colour = "#ffffff";  break;
            case LRDebug_LUM_Off:  colour = "#ff9999";  break;
            default:
                colour = liveOn ? "#bbbbbb" : "#555555";
                break;
        }

        return "<font color='" + colour + "'>" + UsageFlagShortLabel(flag) + "</font>";
    }

    private function UsageFlagShortLabel(flag: ELightRewriteUsageMask): string {
        switch (flag) {
            case LRLUM_ExcludeFromSceneRender:  return "NoScene";
            case LRLUM_RenderToEnvProbe:        return "Env";
            case LRLUM_InteriorOnly:            return "Int";
            case LRLUM_ExteriorOnly:            return "Ext";
        }
        return "?";
    }

    private function GetUsageMaskDisplayParams(): CLightRewriteSourceParams {
        var rewriter: ILightSourceRewriter = entity.lightSourceRewriter;

        if (rewriter && rewriter.inOriginalState) return NULL;
        if (entity.lrDebugParams) return entity.lrDebugParams;
        if (rewriter) return rewriter.LRDebug_GetEffectiveParams();
        return NULL;
    }

    private function ShadowStatusHtml(fontSize: int): string {
        var html, prefix: string;
        var components: array<CComponent>;
        var light: CLightComponent;
        var params: CLightRewriteSourceParams = GetUsageMaskDisplayParams();
        var i: int;

        components = entity.GetComponentsByClassName('CPointLightComponent');
        for (i = 0; i < components.Size(); i += 1) {
            prefix = "P" + (i + 1);
            light = (CLightComponent)components[i];
            html += ShadowLineHtml(prefix, light, fontSize);
            html += UsageMaskLineHtml(prefix, light, params, 'point', i, fontSize);
        }

        components.Clear();
        components = entity.GetComponentsByClassName('CSpotLightComponent');
        for (i = 0; i < components.Size(); i += 1) {
            prefix = "S" + (i + 1);
            light = (CLightComponent)components[i];
            html += ShadowLineHtml(prefix, light, fontSize);
            html += UsageMaskLineHtml(prefix, light, params, 'spot', i, fontSize);
        }

        return html;
    }

    private function GenerateText(): string {
        var headerHtml, body, countString, marker, pSeg, sSeg: string;
        var attrId: name;
        var type: name;

        var fontSize: int = 13;

        countString = CountToHtml("P", pointLights) + " / " + CountToHtml("S", spotLights);
        marker = "<font color='#dd88ff'>-</font> ";

        // Read display state from the player's manager objects.
        if (this.highlighted) {
            type = thePlayer.lrDebugAttrEditor.GetSelectedLightType(entity);

            pSeg = CountToHtml("P", pointLights);
            sSeg = CountToHtml("S", spotLights);

            if (type == 'spot') {
                sSeg = ActiveCountToHtml(
                    "S",
                    spotLights,
                    thePlayer.lrDebugAttrEditor.GetActiveLightIndex(entity, type)
                );
                sSeg = "<font color='#dd88ff'>[</font>" + sSeg + "<font color='#dd88ff'>]</font>";
            }
            else {
                pSeg = ActiveCountToHtml(
                    "P",
                    pointLights,
                    thePlayer.lrDebugAttrEditor.GetActiveLightIndex(entity, type)
                );
                pSeg = "<font color='#dd88ff'>[</font>" + pSeg + "<font color='#dd88ff'>]</font>";
            }
            countString = marker + pSeg + " / " + sSeg + " <font color='#dd88ff'>-</font>";

            attrId = thePlayer.lrDebugAttrEditor.GetCurrentAttrId(type);
            headerHtml = "<font color='#dd88ff'>"
                + thePlayer.lrDebugAttrEditor.GetCurrentAttrLabel(type) + ": "
                + GetAttributeValueString(attrId, type)
                + "</font><br/>";
        }
        body = "<font size='" + fontSize + "'>" + headerHtml + countString + "</font>";

        if (theInput.IsActionPressed('ShowDeveloperModeAlt')) {
            body += ShadowStatusHtml(fontSize);
        }

        return body;
    }
}

state Idle in LRDebug_LightOneLiner {}

state FollowEntity in LRDebug_LightOneLiner {
    event OnEnterState(previous_state_name: name) {
        super.OnEnterState(previous_state_name);
        FollowEntity();
    }

    event OnLeaveState(next_state_name: name) {
        parent.Hide();
        super.OnLeaveState(next_state_name);
    }

    entry function FollowEntity(): void {
        var maxRange: float = 999.9;

        while (
            thePlayer.lrDebugLabels &&
            VecDistanceSquared(
                thePlayer.GetWorldPosition(),
                parent.entity.GetWorldPosition()
            ) <= (maxRange * maxRange)
        ) {
            parent.SetWorldPosition(parent.entity.GetWorldPosition() + Vector(0, 0, 0.25f));
            SleepOneFrame();

            maxRange = thePlayer.lrDebugTargeting.GetMaxRange();
        }

        parent.active = false;
        parent.GotoState('Idle');
    }
}
