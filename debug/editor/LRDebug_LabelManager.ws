/**
 * Manages the lifecycle of LRDebug_LightOneLiner instances.
 *
 * Scan() is called each timer tick to ensure every nearby light entity has an
 * oneliner (creating if missing, restarting if idle), then hands the entities to
 * LRDebug_Targeting so it can pick the highlighted target.
 */
class LRDebug_LabelManager {
    private var tagSeq        : int;
    private var toast         : LRDebug_ToastOneLiner;
    private var groupLabel    : LRDebug_ScreenLabel;
    private var pathLabel     : LRDebug_PathLabel;
    private var showPathLabels: bool;

    public function Init() {
        toast = new LRDebug_ToastOneLiner in this;
        pathLabel = new LRDebug_PathLabel in this;
        pathLabel.Init(0x40006000, 0.5, 0.92);
        groupLabel = new LRDebug_ScreenLabel in this;
        groupLabel.Init(0x40006001, 0.5, 0.98);
        groupLabel.SetText("<font size='40' color='#dd88ff'>&#8734;</font>");
    }

    private function ShowToast(text: string) {
        toast.Init("<font size='14'>" + text + "</font>", 1.0);
        toast.Start();
    }

    public function Scan() {
        var entities: array<CGameplayEntity>;

        FindNearbyLights(entities);
        EnsureOneliners(entities);
        thePlayer.lrDebugTargeting.Select(entities);
    }

    private function EnsureOneliners(entities: array<CGameplayEntity>) {
        var entity: CGameplayEntity;
        var i, count, pointLights, spotLights: int;

        count = entities.Size();
        for (i = 0; i < count; i += 1) {
            entity = entities[i];
            if (!entity) continue;

            if (entity.lrdebugOneliner) {
                entity.lrdebugOneliner.Start();
                continue;
            }

            pointLights = CountComponents(entity, 'CPointLightComponent');
            spotLights = CountComponents(entity, 'CSpotLightComponent');
            if (pointLights == 0 && spotLights == 0) continue;

            CreateOnelinerForEntity(entity, pointLights, spotLights);
        }
    }

    public function HideScreenLabels() {
        pathLabel.Hide();
        groupLabel.Hide();
    }

    public function TogglePathLabels() {
        showPathLabels = !showPathLabels;
        UpdatePathLabel(thePlayer.lrDebugTargeting.GetTarget());
    }

    public function UpdatePathLabel(target: CGameplayEntity) {
        if (!showPathLabels || !target) {
            pathLabel.Hide();
            return;
        }

        pathLabel.ShowPath(target);
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
        var target: CGameplayEntity = thePlayer.lrDebugTargeting.GetTarget();

        if (!target || !target.lrdebugOneliner) return;

        target.lrdebugOneliner.RegenerateText();
    }

    public function ShowGroupLabel() {
        groupLabel.Show();
    }

    public function HideGroupLabel() {
        groupLabel.Hide();
    }

    /**
     * Toggles the rewriter on the targeted entity between its original and rewritten
     * state.
     */
    public function ToggleRewriterOnTarget() {
        var target: CGameplayEntity = thePlayer.lrDebugTargeting.GetTarget();
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
        var target: CGameplayEntity = thePlayer.lrDebugTargeting.GetTarget();
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
