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
 * IK_NumPad7=(Action=LRDebug_TogglePlayerLabels)
 * IK_NumPad8=(Action=LRDebug_ToggleLabelPaths)
 */

function LRDebug_EscapeHtmlMinimal(str : string) : string {
    var r : string;

    r = StrReplaceAll(str, "&", "&amp;");
    r = StrReplaceAll(r, "<", "&lt;");
    r = StrReplaceAll(r, ">", "&gt;");
    return r;
}

function LRDebug_CountComponents(entity : CGameplayEntity, className : name) : int {
    var components : array<CComponent> = entity.GetComponentsByClassName(className);
    return components.Size();
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
        if (this.IsInState('FollowEntity')) return;

        this.GotoState('FollowEntity');
    }

    /**
     * Example entity.ToString():
     * ```
     * CLayer "full\editor\level\path.somext"::full\path\to\entity.w2ent
     * ```
     */
    private function LRDebug_GenerateText() : string {
        var layerPart, entityPath, levelPath : string;

        var fontSize : int = 12;
        var itemName : string = "P " + IntToString(pointLights) + " / S " + IntToString(spotLights);
        var body : string = "<font size='" + fontSize + "'>" + itemName + "</font>";
        var descriptor : string = entity.ToString();

        if (thePlayer.lrDebugShowPathLabels) {
            if (StrFindFirst(descriptor, "::") != -1) {
                layerPart = StrBeforeFirst(descriptor, "::");
                entityPath = StrAfterFirst(descriptor, "::");
                body = body + "<br/><font size='" + fontSize + "'>"
                    + LRDebug_EscapeHtmlMinimal(entityPath) + "</font>";
                if (StrFindFirst(layerPart, "\"") != -1) {
                    levelPath = StrBeforeFirst(StrAfterFirst(layerPart, "\""), "\"");
                    body = body + "<br/><font size='" + fontSize + "'>"
                        + LRDebug_EscapeHtmlMinimal(levelPath) + "</font>";
                }
            }
        }

        return "<p align=\"center\">" + body + "</p>";
    }
}

state Idle in LRDebug_LightOneLiner {
    event OnEnterState(previous_state_name : name) {
        super.OnEnterState(previous_state_name);

        parent.unregister();
    }
}

state FollowEntity in LRDebug_LightOneLiner {
    private const var NORMAL_RANGE : float; default NORMAL_RANGE = 10.0;
    private const var FOCUS_RANGE  : float; default FOCUS_RANGE  = 25.0;

    event OnEnterState(previous_state_name : name) {
        super.OnEnterState(previous_state_name);

        parent.register();
        FollowEntity();
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

        parent.GotoState('Idle');
    }
}

@addField(CR4Player) private var lrdebugTagSeq : int;
@addField(CR4Player) public var lrDebugLabels : bool;
@addField(CR4Player) public var lrDebugShowPathLabels : bool;

@addField(CGameplayEntity) public var lrdebugOneliner : LRDebug_LightOneLiner;

@wrapMethod(CR4Player)
function OnSpawned(spawnData : SEntitySpawnData) {
    wrappedMethod(spawnData);

    AddTimer('LRDebug_DeferredPlayerLabelInstall', 1.f, false);
}

@addMethod(CR4Player)
timer function LRDebug_DeferredPlayerLabelInstall(dt : float, id : int) {
    if (!theGame || !thePlayer) return;

    theInput.RegisterListener(this, 'LRDebug_OnInputTogglePlayerLabels', 'LRDebug_TogglePlayerLabels');
    theInput.RegisterListener(this, 'LRDebug_OnInputToggleLabelPaths', 'LRDebug_ToggleLabelPaths');
}

@addMethod(CR4Player)
timer function LRDebug_RefreshOnelinersTimer(dt : float, id : int) {
    var entities : array<CGameplayEntity>;
    var entity : CGameplayEntity;
    var i, count, pointLights, spotLights : int;

    if (!this.lrDebugLabels || !theGame || !thePlayer) return;

    LRDebug_FindNearbyLights(entities);

    count = entities.Size();
    for (i = 0; i < count; i += 1) {
        entity = entities[i];
        if (!entity) continue;

        if (entity.lrdebugOneliner) {
            entity.lrdebugOneliner.LRDebug_Start();
            continue;
        }

        pointLights = LRDebug_CountComponents(entity, 'CPointLightComponent');
        spotLights = LRDebug_CountComponents(entity, 'CSpotLightComponent');
        if (pointLights == 0 && spotLights == 0) continue;

        LRDebug_CreateOnelinerForEntity(entity, pointLights, spotLights);
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
public function LRDebug_OnInputTogglePlayerLabels(action : SInputAction) : bool {
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
