/**
 * Manages the lifecycle of LRDebug_LightOneLiner instances and target selection.
 *
 * Scan() is called each timer tick to:
 *   - Ensure every nearby light entity has an oneliner (creates if missing, restarts if idle)
 *   - Pick the most camera-forward entity within range as the highlighted target
 */
class LRDebug_LabelManager {
    private var tagSeq        : int;
    private var showPathLabels: bool;
    private var target        : CGameplayEntity;
    private var toast         : LRDebug_ToastOneLiner;
    private var pathLabel     : LRDebug_PathLabel;
    private var groupLabel    : LRDebug_ScreenLabel;
    private var locked        : bool;

    public function Init() {
        toast = new LRDebug_ToastOneLiner in this;
        pathLabel = new LRDebug_PathLabel in this;
        pathLabel.Init(0x40006000, 0.5, 0.92);
        groupLabel = new LRDebug_ScreenLabel in this;
        groupLabel.Init(0x40006001, 0.5, 0.98);
        groupLabel.SetText("<font size='10' color='#dd88ff'>#</font>");
    }

    private function ShowToast(text: string) {
        toast.Init("<font size='14'>" + text + "</font>", 1.0);
        toast.Start();
    }

    public function ToggleLock() {
        locked = !locked;
    }

    public function Scan() {
        var entities: array<CGameplayEntity>;
        var entity: CGameplayEntity;
        var i, count, pointLights, spotLights: int;
        var camPos, camDir, entPos, toEnt: Vector;
        var score, bestScore, dot, visibilityRange: float;
        var bestEntity: CGameplayEntity;

        if (locked) return;

        FindNearbyLights(entities);

        bestScore = -1.0;
        bestEntity = NULL;
        GetCameraPositionAndDirection(camPos, camDir);
        camDir = VecNormalize(camDir);

        visibilityRange = 10.0;

        if (theInput.IsActionPressed('LRDebug_ModifierKey')) visibilityRange *= 3.0;
        if (theGame.IsFocusModeActive()) visibilityRange *= 3.0;

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

            UpdatePathLabel();
        }
    }

    public function TogglePathLabels() {
        showPathLabels = !showPathLabels;
        UpdatePathLabel();
    }

    private function UpdatePathLabel() {
        if (!showPathLabels || !target) {
            pathLabel.Hide();
            return;
        }

        pathLabel.ShowPath(target);
    }

    public function HideScreenLabels() {
        pathLabel.Hide();
        groupLabel.Hide();
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

    public function ShowGroupLabel() {
        groupLabel.Show();
    }

    public function HideGroupLabel() {
        groupLabel.Hide();
    }

    /** Modifier-key handlers reuse one key per light type, so they need the target's type. */
    public function GetTargetLightType(editor: LRDebug_AttributeEditor): name {
        if (!target) return 'point';

        return editor.GetSelectedLightType(target);
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

    public function ResetTarget() {
        var rewriter: ILightSourceRewriter;

        if (!target) return;

        rewriter = target.LRDebug_GetOrCreateRewriter();
        rewriter.LRDebug_ClearMenuOverrideParams();
        target.LRDebug_ClearDebugParams();
        rewriter.RestoreOriginalState();
        rewriter.RewriteLight();

        RefreshTargetOneliner();
    }

    private function FindNearbyLights(out entities: array<CGameplayEntity>) {
        var maxRange: float = 10.0;

        if (theInput.IsActionPressed('LRDebug_ModifierKey')) maxRange *= 3.0;
        if (theGame.IsFocusModeActive()) maxRange *= 3.0;

        // Find in a large radius can exceed 1024 entities
        if (maxRange > 10.0) {
            FindGameplayEntitiesInRange(
                entities,
                thePlayer,
                maxRange,
                1024,
                theGame.lightRewrite.TAG_HAS_LIGHT,
                FLAG_ExcludePlayer
            );
        }
        // OnSpawned is overriden by many subclasses, some do not call super.OnSpawned
        // By omitting the tag filter, we can still see them.
        else {
            FindGameplayEntitiesInRange(entities, thePlayer, maxRange, 1024, , FLAG_ExcludePlayer);
        }
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
