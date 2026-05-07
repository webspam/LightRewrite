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

@addField(CGameplayEntity) public var lrdebugOneliner : LRDebug_LightOneLiner;

statemachine class LRDebug_LightOneLiner extends SU_Oneliner {
    public var entity : CGameplayEntity;
    public var pointLights : int;
    public var spotLights : int;
    public var active : bool;
    public var highlighted : bool;

    public function Init(tracked_entity : CGameplayEntity, pointLights_ : int, spotLights_ : int) {
        this.entity = tracked_entity;
        this.pointLights = pointLights_;
        this.spotLights = spotLights_;
        this.text = GenerateText();
    }

    // Changes to text require re-registering the oneliner.
    public function LRDebug_RegenerateText() {
        this.text = GenerateText();
        this.update();
    }

    public function LRDebug_Start() {
        if (this.active) return;

        this.active = true;
        this.GotoState('FollowEntity');
    }

    public function LRDebug_SetHighlighted(isHighlighted : bool) {
        this.highlighted = isHighlighted;
        this.LRDebug_RegenerateText();
    }

    private function CountToHtml(prefix : string, count : int) : string {
        var html : string = "<font color='";

        if (count > 0) html += "#00ff00";
        else html += "#aaaaaa";

        return html + "'>" + prefix + " " + count + "</font>";
    }

    private function EscapeHtml(str : string) : string {
        var r : string;

        r = StrReplaceAll(str, "&", "&amp;");
        r = StrReplaceAll(r, "<", "&lt;");
        r = StrReplaceAll(r, ">", "&gt;");
        return r;
    }

    private function ToHtmlBlock(size : int, text : string) : string {
        return "<br/><font size='" + size + "'>" + text + "</font>";
    }

    /**
     * Example entity.ToString():
     * ```
     * CLayer "full\editor\level\path.somext"::full\path\to\entity.w2ent
     * ```
     */
    private function GenerateText() : string {
        var descriptor : string;
        var layerPart, entityPath, levelPath, fileName, filePath : string;
        var headerHtml, body, countString, marker : string;
        var attrId : name;
        var fontSize : int;
        var attrIndex : int;
        var showPaths : bool;

        descriptor = entity.ToString();
        fontSize = 13;
        countString = CountToHtml("P", pointLights) + " / " + CountToHtml("S", spotLights);
        marker = "<font color='#ff0000'>-</font> ";

        // Read display state from the player's manager objects.
        attrIndex = thePlayer.lrDebugAttrEditor.GetCurrentAttrIndex();
        showPaths = thePlayer.lrDebugLabelManager.showPathLabels;

        if (this.highlighted) {
            countString = marker + countString + " <font color='#ff0000'>-</font>";

            attrId = LRDebug_GetAttributeId(attrIndex);
            headerHtml = "<font color='#ff0000'>"
                + LRDebug_GetAttributeLabel(attrId) + ": "
                + LRDebug_GetAttributeValueString(entity, attrId)
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
