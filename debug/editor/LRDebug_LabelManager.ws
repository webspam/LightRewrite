/**
 * Creates and updates the overlay's labels: the per-light oneliners, the toast,
 * and the UI / edit-status indicators. Owns the singleton labels and keeps their
 * fiddly setup in one place.
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

    public function Update(targeting: LRDebug_Targeting) {
        var entities: array<CGameplayEntity>;
        var entity: CGameplayEntity;
        var i, count: int;
        var targetChanged: bool;

        FindNearbyLights(entities);

        count = entities.Size();
        for (i = 0; i < count; i += 1) {
            entity = entities[i];
            if (!entity) continue;

            if (entity.lrdebugOneliner) {
                entity.lrdebugOneliner.Start();
                continue;
            }

            CreateOnelinerForEntity(entity);
        }

        targetChanged = targeting.Scan(entities);
        if (targetChanged) UpdatePathLabel(targeting.GetTarget());
    }

    public function HideScreenLabels() {
        pathLabel.Hide();
        groupLabel.Hide();
    }

    public function TogglePathLabels() {
        showPathLabels = !showPathLabels;
        UpdatePathLabel(thePlayer.lrDebugTargeting.GetTarget());
    }

    private function UpdatePathLabel(target: CGameplayEntity) {
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

    /** Regenerate the reverted lights' labels so their values reflect the restored state */
    public function Undo(history: LRDebug_EditHistory) {
        var record: LRDebug_EditEntry;
        var i, count: int;

        record = history.Undo();
        if (!record) {
            ShowToast("Nothing to undo");
            return;
        }

        count = record.entities.Size();
        for (i = 0; i < count; i += 1) {
            if (record.entities[i] && record.entities[i].lrdebugOneliner) {
                record.entities[i].lrdebugOneliner.RegenerateText();
            }
        }

        ShowToast("Undo: " + record.label);
    }

    public function ResetTarget() {
        var target: CGameplayEntity = thePlayer.lrDebugTargeting.GetTarget();
        var rewriter: ILightSourceRewriter;

        if (!target) return;

        rewriter = target.LRDebug_GetOrCreateRewriter();
        rewriter.LRDebug_ClearMenuOverrideParams();
        target.LRDebug_ClearDebugParams();
        thePlayer.lrDebugHistory.ForgetEntity(target);
        rewriter.RestoreOriginalState();
        rewriter.RewriteLight();

        RefreshTargetOneliner();
    }

    private function FindNearbyLights(out entities: array<CGameplayEntity>) {
        FindGameplayEntitiesInRange(
            entities,
            thePlayer,
            thePlayer.lrDebugTargeting.GetMaxRange(),
            1024,
            theGame.lightRewrite.TAG_HAS_LIGHT,
            FLAG_ExcludePlayer
        );
    }

    private function CountComponents(entity: CGameplayEntity, className: name): int {
        var components: array<CComponent> = entity.GetComponentsByClassName(className);
        return components.Size();
    }

    private function CreateOnelinerForEntity(entity: CGameplayEntity) {
        var label: LRDebug_LightOneLiner;

        var pointLights: int = CountComponents(entity, 'CPointLightComponent');
        var spotLights: int = CountComponents(entity, 'CSpotLightComponent');

        if (pointLights == 0 && spotLights == 0) return;

        label = new LRDebug_LightOneLiner in entity;
        label.Init(entity, pointLights, spotLights);

        tagSeq += 1;
        label.setTag("lrdebug-" + tagSeq);

        entity.lrdebugOneliner = label;
        label.Start();
    }
}
