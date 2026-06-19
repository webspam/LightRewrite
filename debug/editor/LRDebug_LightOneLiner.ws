/**
 * Floating label that tracks a light-bearing CGameplayEntity in world space.
 *
 * One instance is created per entity and reused for its lifetime.
 * The label transitions between Idle and FollowEntity states rather than
 * being destroyed and recreated as the player moves in and out of range.
 *
 * Markup is only regenerated on explicit events (highlight change, path-label
 * toggle, attribute cycle). The FollowEntity loop does no markup work per tick.
 *
 * Requires: mod_sharedutils_oneliners (SU_Oneliner)
 */

@addField(CGameplayEntity) public var lrdebugOneliner: LRDebug_LightOneLiner;

statemachine class LRDebug_LightOneLiner extends SU_Oneliner {
    public var entity     : CGameplayEntity;
    public var pointLights: int;
    public var spotLights : int;
    public var active     : bool;
    public var highlighted: bool;

    public function Init(tracked_entity: CGameplayEntity, pointLights_: int, spotLights_: int) {
        this.entity = tracked_entity;
        this.pointLights = pointLights_;
        this.spotLights = spotLights_;
        this.text = GenerateText();
    }

    // Changes to text require re-registering the oneliner.
    public function RegenerateText() {
        this.text = GenerateText();
        this.update();
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

    private function GetAttributeValueString(attr: name, type: name): string {
        var params: CLightRewriteSourceParams;
        var lightParams: ILightRewriteParams;
        var spotP: CLightRewriteSpotlightParams;
        var light: CLightComponent;
        var spotComp: CSpotLightComponent;
        var position: Vector;
        var valF: float;
        var valI: int;

        if (!entity) return "?";

        params = entity.lrDebugParams;

        if (type == 'spot') {
            if (params) {
                lightParams = params.spotlight;
                spotP = params.spotlight;
            }
            light = LRDebug_FirstSpotLight(entity);
            spotComp = LRDebug_FirstSpotLight(entity);
        }
        else {
            lightParams = params;
            light = LRDebug_FirstPointLight(entity);
        }

        switch (attr) {
            case 'brightness':
                if (lightParams && lightParams.brightness.has) valF = lightParams.brightness.value;
                else if (light) valF = light.brightness;
                return FloatToString(valF);

            case 'radius':
                if (lightParams && lightParams.radius.has) valF = lightParams.radius.value;
                else if (light) valF = light.radius;
                return FloatToString(valF);

            case 'attenuation':
                if (lightParams && lightParams.attenuation.has) {
                    valF = lightParams.attenuation.value;
                }
                else if (light) {
                    valF = light.attenuation;
                }
                return FloatToString(valF);

            case 'shadowFadeDistance':
                if (lightParams && lightParams.shadowFadeDistance.has) {
                    valF = lightParams.shadowFadeDistance.value;
                }
                else if (light) {
                    valF = light.shadowFadeDistance;
                }
                return FloatToString(valF);

            case 'shadowFadeRange':
                if (lightParams && lightParams.shadowFadeRange.has) {
                    valF = lightParams.shadowFadeRange.value;
                }
                else if (light) {
                    valF = light.shadowFadeRange;
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
                if (type == 'spot') {
                    if (spotP && spotP.offset.has) {
                        valF = spotP.offset.value.Z;
                    }
                    else if (spotComp) {
                        position = spotComp.GetLocalPosition();
                        valF = position.Z;
                    }
                    return FloatToString(valF);
                }
                if (params && params.alignPointLights.has) valF = params.pointLightOffset.Z;
                else valF = 0.0;
                return FloatToString(valF);

            case 'innerAngle':
                if (spotP && spotP.innerAngle.has) valF = spotP.innerAngle.value;
                else if (spotComp) valF = spotComp.innerAngle;
                return FloatToString(valF);

            case 'outerAngle':
                if (spotP && spotP.outerAngle.has) valF = spotP.outerAngle.value;
                else if (spotComp) valF = spotComp.outerAngle;
                return FloatToString(valF);

            case 'softness':
                if (spotP && spotP.softness.has) valF = spotP.softness.value;
                else if (spotComp) valF = spotComp.softness;
                return FloatToString(valF);

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
        }

        return "?";
    }

    private function EscapeHtml(str: string): string {
        var r: string;

        r = StrReplaceAll(str, "&", "&amp;");
        r = StrReplaceAll(r, "<", "&lt;");
        r = StrReplaceAll(r, ">", "&gt;");
        return r;
    }

    private function ToHtmlBlock(size: int, text: string): string {
        return "<br/><font size='" + size + "'>" + text + "</font>";
    }

    /**
     * Example entity.ToString():
     * ```
     * CLayer "full\editor\level\path.somext"::full\path\to\entity.w2ent
     * ```
     */
    private function GenerateText(): string {
        var descriptor: string;
        var layerPart, entityPath, levelPath, fileName, filePath: string;
        var headerHtml, body, countString, marker, pSeg, sSeg: string;
        var attrId: name;
        var type: name;
        var fontSize: int;
        var showPaths: bool;

        descriptor = entity.ToString();
        fontSize = 13;
        countString = CountToHtml("P", pointLights) + " / " + CountToHtml("S", spotLights);
        marker = "<font color='#dd88ff'>-</font> ";

        // Read display state from the player's manager objects.
        showPaths = thePlayer.lrDebugLabelManager.showPathLabels;

        if (this.highlighted) {
            type = thePlayer.lrDebugAttrEditor.GetSelectedLightType(entity);

            pSeg = CountToHtml("P", pointLights);
            sSeg = CountToHtml("S", spotLights);
            if (type == 'spot') {
                sSeg = "<font color='#dd88ff'>[</font>" + sSeg + "<font color='#dd88ff'>]</font>";
            }
            else {
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

        if (showPaths) {
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
                // Fallback: display the raw descriptor as the path.
                filePath = descriptor;
            }

            if (fileName != "") {
                body += ToHtmlBlock(fontSize + 3, EscapeHtml(fileName));
            }
            if (filePath != "") {
                body += ToHtmlBlock(fontSize - 1, EscapeHtml(filePath));
            }
            if (levelPath != "") {
                body += ToHtmlBlock(fontSize + 2, EscapeHtml(levelPath));
            }
        }

        return body;
    }
}

state Idle in LRDebug_LightOneLiner {}

state FollowEntity in LRDebug_LightOneLiner {
    private const var NORMAL_RANGE: float;  default NORMAL_RANGE = 10.0;
    private const var FOCUS_RANGE : float;  default FOCUS_RANGE = 25.0;

    event OnEnterState(previous_state_name: name) {
        super.OnEnterState(previous_state_name);
        parent.register();
        FollowEntity();
    }

    event OnLeaveState(next_state_name: name) {
        parent.unregister();
        super.OnLeaveState(next_state_name);
    }

    entry function FollowEntity(): void {
        var maxRange: float = FOCUS_RANGE;

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
