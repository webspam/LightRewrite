/**
 * Creates and updates the overlay's labels: the per-light oneliners, the toast,
 * and the UI / edit-status indicators. Owns the singleton labels and keeps their
 * fiddly setup in one place.
 */
class LRDebug_LabelManager {
    private var tagSeq         : int;
    private var toast          : LRDebug_ToastOneLiner;
    private var groupLabel     : LRDebug_ScreenLabel;
    private var groupCountLabel: LRDebug_ScreenLabel;
    private var scaleLabel     : LRDebug_ScreenLabel;
    private var timeLabel      : LRDebug_ScreenLabel;
    private var timeModeLabel  : LRDebug_ScreenLabel;
    private var pathLabel      : LRDebug_PathLabel;
    private var attrLabels     : LRDebug_AttributeLabels;
    private var clockFace      : LRDebug_ClockFace;
    private var showPathLabels: bool;  default showPathLabels = true;

    public function Init() {
        toast = new LRDebug_ToastOneLiner in this;
        pathLabel = new LRDebug_PathLabel in this;
        pathLabel.Init(0x40006000, 0.5, 0.92);
        groupLabel = new LRDebug_ScreenLabel in this;
        groupLabel.Init(0x40006001, 0.5, 0.98);
        groupLabel.SetText("<font size='40' color='#dd88ff'>&#8734;</font>");
        groupCountLabel = new LRDebug_ScreenLabel in this;
        groupCountLabel.Init(0x40006003, 0.5, 0.85);
        scaleLabel = new LRDebug_ScreenLabel in this;
        scaleLabel.Init(0x40006002, 0.6, 0.98);
        timeLabel = new LRDebug_ScreenLabel in this;
        timeLabel.Init(0x40006004, 0.65, 0.98);
        timeModeLabel = new LRDebug_ScreenLabel in this;
        timeModeLabel.Init(0x40006005, 0.65, 0.95);
        clockFace = new LRDebug_ClockFace in this;
        clockFace.Init();
        attrLabels = new LRDebug_AttributeLabels in this;
        attrLabels.Init();
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
        if (targetChanged) {
            UpdatePathLabel(targeting.GetTarget());
            RefreshGroupCount();
        }
    }

    public function HideScreenLabels() {
        pathLabel.Hide();
        groupLabel.Hide();
        groupCountLabel.Hide();
        scaleLabel.Hide();
        timeLabel.Hide();
        timeModeLabel.Hide();
        clockFace.Hide();
        attrLabels.Hide();
    }

    public function ShowClockFace(hours: float) {
        clockFace.Show(hours);
    }

    public function HideClockFace() {
        clockFace.Hide();
    }

    public function RefreshTimeLabels() {
        var clock: LRDebug_Clock = thePlayer.lrDebugClock;

        if (!clock) return;

        timeModeLabel.SetText(BuildTimeModeLabel(clock));
        timeModeLabel.Show();
        timeLabel.SetText(BuildTimeLabel(clock));
        timeLabel.Show();
    }

    private function BuildTimeModeLabel(clock: LRDebug_Clock): string {
        if (!clock.IsUsingRealTime()) return "";

        return "<font size='18' color='#ff6a1a'>Scrubbing Real Time</font>";
    }

    private function BuildTimeLabel(clock: LRDebug_Clock): string {
        var fakeEnvTime: SLightRewriteOptionalFloat = clock.GetFakeEnvTime();
        var hours, minutes: int;

        if (!fakeEnvTime.has) return "";

        hours = (int)fakeEnvTime.value;
        minutes = (int)((fakeEnvTime.value - hours) * 60.0);

        return "<font size='14' color='#dd88ff'>Env Time: "
            + Pad2(hours) + ":" + Pad2(minutes)
            + "</font>";
    }

    private function Pad2(value: int): string {
        if (value < 10) return "0" + value;
        return "" + value;
    }

    public function TogglePathLabels() {
        showPathLabels = !showPathLabels;
        UpdatePathLabel(thePlayer.lrDebugTargeting.GetTarget());
    }

    public function RefreshPathLabel() {
        UpdatePathLabel(thePlayer.lrDebugTargeting.GetTarget());
    }

    private function UpdatePathLabel(target: CGameplayEntity) {
        if (!showPathLabels || !target) {
            pathLabel.Hide();
            scaleLabel.Hide();
            attrLabels.Hide();
            return;
        }

        pathLabel.ShowPath(target);
        scaleLabel.SetText(BuildScaleLabel(target));
        scaleLabel.Show();
        attrLabels.Update(target);
    }

    /** Only while path labels are shown. */
    private function RefreshAttributeLabels() {
        if (!showPathLabels) return;

        attrLabels.Update(thePlayer.lrDebugTargeting.GetTarget());
    }

    private function BuildScaleLabel(target: CGameplayEntity): string {
        var s: Vector = target.GetLocalScale();

        return "<font size='14' color='#dd88ff'>Scale: ("
            + FloatToString(s.X) + ", "
            + FloatToString(s.Y) + ", "
            + FloatToString(s.Z) + ")</font>";
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

        RefreshAttributeLabels();
    }

    public function RefreshTargetOneliner() {
        var target: CGameplayEntity = thePlayer.lrDebugTargeting.GetTarget();

        if (!target || !target.lrdebugOneliner) return;

        target.lrdebugOneliner.RegenerateText();
        RefreshAttributeLabels();
    }

    public function ShowGroupLabel() {
        groupLabel.Show();
        RefreshGroupCount();
    }

    public function HideGroupLabel() {
        groupLabel.Hide();
        groupCountLabel.Hide();
    }

    /** Sets the group edit light-count label. */
    private function RefreshGroupCount() {
        var count: int;

        if (!thePlayer.lrDebugAttrEditor.IsGroupEditing()) {
            groupCountLabel.Hide();
            return;
        }

        count = thePlayer.lrDebugAttrEditor.GetGroupMemberCount(thePlayer.lrDebugTargeting.GetTarget());

        if (count > 0) {
            groupCountLabel.SetText("<font size='20' color='#dddddd'>" + count + "</font>");
            groupCountLabel.Show();
        }
        else {
            groupCountLabel.Hide();
        }
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

        RefreshAttributeLabels();
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
