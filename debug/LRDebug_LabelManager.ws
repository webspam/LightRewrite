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
    private var tagSeq : int;
    public var showPathLabels : bool;
    private var target : CGameplayEntity;

    public function GetTarget() : CGameplayEntity {
        return target;
    }

    public function Scan() {
        var entities : array<CGameplayEntity>;
        var entity : CGameplayEntity;
        var i, count, pointLights, spotLights : int;
        var camPos, camDir, entPos, toEnt : Vector;
        var score, bestScore, dot, visibilityRange : float;
        var bestEntity : CGameplayEntity;

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

                CreateOnelinerForEntity(entity, pointLights, spotLights);
            }

            entPos = entity.GetWorldPosition();
            if (VecDistanceSquared(thePlayer.GetWorldPosition(), entPos) > (visibilityRange * visibilityRange)) continue;

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
                target.lrdebugOneliner.LRDebug_SetHighlighted(false);
            }

            target = bestEntity;

            if (target && target.lrdebugOneliner) {
                target.lrdebugOneliner.LRDebug_SetHighlighted(true);
            }
        }
    }

    /**
     * Toggles path-label visibility and regenerates markup on all nearby oneliners.
     */
    public function TogglePathLabels() {
        var entities : array<CGameplayEntity>;
        var i, count : int;

        showPathLabels = !showPathLabels;

        LRDebug_FindNearbyLights(entities);

        count = entities.Size();
        for (i = 0; i < count; i += 1) {
            if (!entities[i].lrdebugOneliner) continue;

            entities[i].lrdebugOneliner.LRDebug_RegenerateText();
        }
    }

    public function RefreshTargetOneliner() {
        if (!target || !target.lrdebugOneliner) return;

        target.lrdebugOneliner.LRDebug_RegenerateText();
    }

    /**
     * Applies a signed attribute adjustment to the target entity and refreshes its
     * oneliner if the adjustment took effect. Combines the editor, accelerator, and
     * oneliner refresh into one coordinated call so the player handler stays minimal.
     */
    public function ApplyAttributeAdjustment(
        sign : int,
        editor : LRDebug_AttributeEditor,
        accel : LRDebug_AdjustAccelerator
    ) {
        if (!editor.AdjustAttribute(sign, target, accel)) return;

        RefreshTargetOneliner();
    }

    /**
     * Toggles the rewriter on the targeted entity between its original and rewritten
     * state. Returns the new state as a short string ("ON" / "OFF") for the caller
     * to display as a toast, or an empty string if there was no valid target.
     */
    public function ToggleRewriterOnTarget() : string {
        var rewriter : ILightSourceRewriter;

        if (!target) return "";

        rewriter = LRDebug_EnsureEntityHasRewriter(target);
        if (!rewriter) return "";

        if (rewriter.inOriginalState) {
            rewriter.RewriteLight();
            return "ON";
        }

        rewriter.RestoreOriginalState();
        return "OFF";
    }

    private function CreateOnelinerForEntity(
        entity : CGameplayEntity,
        pointLights : int,
        spotLights : int
    ) {
        var label : LRDebug_LightOneLiner = new LRDebug_LightOneLiner in entity;

        label.Init(entity, pointLights, spotLights);

        tagSeq += 1;
        label.setTag("lrdebug-" + tagSeq);

        entity.lrdebugOneliner = label;
        label.LRDebug_Start();
    }
}
