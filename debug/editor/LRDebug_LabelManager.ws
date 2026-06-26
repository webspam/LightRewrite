/**
 * Manages the lifecycle of LRDebug_LightOneLiner instances and target selection.
 *
 * Scan() is called each timer tick to:
 *   - Ensure every nearby light entity has an oneliner (creates if missing, restarts if idle)
 *   - Pick the most camera-forward entity within range as the highlighted target
 *
 * showPathLabels is public so LRDebug_LightOneLiner.GenerateText can read it
 * via thePlayer.lrDebugLabelManager.showPathLabels without a separate accessor.
 */
class LRDebug_LabelManager {
    private var tagSeq       : int;
    public var showPathLabels: bool;
    private var target       : CGameplayEntity;
    private var toast        : LRDebug_ToastOneLiner;

    public function Init() {
        toast = new LRDebug_ToastOneLiner in this;
    }

    private function ShowToast(text: string) {
        toast.Init("<font size='14'>" + text + "</font>", 1.0);
        toast.Start();
    }

    public function Scan() {
        var entities: array<CGameplayEntity>;
        var entity: CGameplayEntity;
        var i, count, pointLights, spotLights: int;
        var camPos, camDir, entPos, toEnt: Vector;
        var score, bestScore, dot, visibilityRange: float;
        var bestEntity: CGameplayEntity;

        FindNearbyLights(entities);

        bestScore = -1.0;
        bestEntity = NULL;
        GetCameraPositionAndDirection(camPos, camDir);
        camDir = VecNormalize(camDir);

        if (theGame.IsFocusModeActive()) visibilityRange = 25.0;
        else visibilityRange = 10.0;

        count = entities.Size();
        for (i = 0; i < count; i += 1) {
            entity = entities[i];
            if (!entity) continue;

            if (entity.lrdebugOneliner) {
                entity.lrdebugOneliner.Start();
            }
            else {
                pointLights = CountComponents(entity, 'CPointLightComponent');
                spotLights = CountComponents(entity, 'CSpotLightComponent');
                if (pointLights == 0 && spotLights == 0) continue;

                CreateOnelinerForEntity(entity, pointLights, spotLights);
            }

            entPos = entity.GetWorldPosition();
            if (VecDistanceSquared(thePlayer.GetWorldPosition(), entPos) > (visibilityRange * visibilityRange)) {
                continue;
            }

            toEnt = entPos - camPos;
            if (VecLengthSquared(toEnt) < 0.001) continue;

            toEnt = VecNormalize(toEnt);
            dot = VecDot(toEnt, camDir);
            score = dot * 4.0;

            // Rough in-front filter to reduce "behind camera" picks.
            if (dot < 0.6) continue;

            if (score > bestScore) {
                bestScore = score;
                bestEntity = entity;
            }
        }

        if (bestEntity != target) {
            if (target && target.lrdebugOneliner) {
                target.lrdebugOneliner.SetHighlighted(false);
            }

            target = bestEntity;

            if (target && target.lrdebugOneliner) {
                target.lrdebugOneliner.SetHighlighted(true);
            }

            if (thePlayer.lrDebugTargetMarkers) {
                thePlayer.lrDebugTargetMarkers.SetTarget(target);
            }
        }
    }

    /**
     * Toggles path-label visibility and regenerates markup on all nearby oneliners.
     */
    public function TogglePathLabels() {
        showPathLabels = !showPathLabels;
        RegenerateNearbyOneliners();
    }

    public function RegenerateNearbyOneliners() {
        var entities: array<CGameplayEntity>;
        var i, count: int;

        FindNearbyLights(entities);

        count = entities.Size();
        for (i = 0; i < count; i += 1) {
            if (!entities[i].lrdebugOneliner) continue;

            entities[i].lrdebugOneliner.RegenerateText();
        }
    }

    public function RefreshTargetOneliner() {
        if (!target || !target.lrdebugOneliner) return;

        target.lrdebugOneliner.RegenerateText();
    }

    public function SwapLightSelection(editor: LRDebug_AttributeEditor) {
        if (!target) return;

        editor.SwapLightSelection(target);
        RefreshTargetOneliner();
    }

    /** Modifier-key handlers reuse one key per light type, so they need the target's type. */
    public function GetTargetLightType(editor: LRDebug_AttributeEditor): name {
        if (!target) return 'point';

        return editor.GetSelectedLightType(target);
    }

    /** CycleAttribute needs the target, which only the manager holds. */
    public function CycleSelectedAttribute(editor: LRDebug_AttributeEditor, delta: int) {
        if (!target) return;

        editor.CycleAttribute(delta, target);
        RefreshTargetOneliner();
    }

    /**
     * Applies a signed attribute adjustment to the target entity and refreshes its
     * oneliner if the adjustment took effect.
     */
    public function ApplyAttributeAdjustment(
        value: float,
        editor: LRDebug_AttributeEditor,
        optional attr: name
    ) {
        if (!editor.AdjustAttribute(value, target, attr)) return;

        RefreshTargetOneliner();
    }

    /**
     * Applies a continuous (analog) delta to the target's selected attribute and
     * refreshes its oneliner if the adjustment took effect.
     */
    public function ApplyContinuousAdjustment(
        delta: float,
        editor: LRDebug_AttributeEditor,
        optional attr: name
    ) {
        if (!editor.AdjustAttributeContinuous(delta, target, attr)) return;

        RefreshTargetOneliner();
    }

    public function MoveTargetXY(dx: float, dy: float, editor: LRDebug_AttributeEditor) {
        if (!editor.MoveOffsetXY(dx, dy, target)) return;

        RefreshTargetOneliner();
    }

    /**
     * Toggles a boolean attribute on the target and refreshes its oneliner.
     */
    public function ApplyToggle(editor: LRDebug_AttributeEditor, optional attr: name) {
        if (!editor.ToggleAttribute(target, attr)) return;

        RefreshTargetOneliner();
    }

    /**
     * Toggles the rewriter on the targeted entity between its original and rewritten
     * state.
     */
    public function ToggleRewriterOnTarget() {
        var rewriter: ILightSourceRewriter;

        if (!target) return;

        rewriter = target.LRDebug_GetOrCreateRewriter();
        if (rewriter.inOriginalState) {
            rewriter.RewriteLight();
            ShowToast("LightRewrite: ON");
        }
        else {
            rewriter.RestoreOriginalState();
            ShowToast("LightRewrite: OFF");
        }

        RefreshTargetOneliner();
    }

    private function FindNearbyLights(out entities: array<CGameplayEntity>) {
        var maxRange: float = 10.0;

        if (theGame.IsFocusModeActive()) maxRange = 25.0;
        FindGameplayEntitiesInRange(entities, thePlayer, maxRange, 1024, , FLAG_ExcludePlayer);
    }

    private function GetCameraPositionAndDirection(
        out cameraPosition: Vector,
        out cameraDirection: Vector
    ) {
        var director: CCameraDirector = theGame.GetWorld().GetCameraDirector();

        cameraPosition = director.GetCameraPosition();
        cameraDirection = director.GetCameraDirection();
    }

    private function CountComponents(entity: CGameplayEntity, className: name): int {
        var components: array<CComponent> = entity.GetComponentsByClassName(className);
        return components.Size();
    }

    private function CreateOnelinerForEntity(
        entity: CGameplayEntity,
        pointLights: int,
        spotLights: int
    ) {
        var label: LRDebug_LightOneLiner = new LRDebug_LightOneLiner in entity;

        label.Init(entity, pointLights, spotLights);

        tagSeq += 1;
        label.setTag("lrdebug-" + tagSeq);

        entity.lrdebugOneliner = label;
        label.Start();
    }
}
