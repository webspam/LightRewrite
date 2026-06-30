/**
 * Owns the current edit target: the light entity the player is aiming at.
 *
 * Select() is handed the nearby light entities each scan tick and picks the most
 * camera-forward one within range. Other modules read the choice via GetTarget()
 * rather than having it threaded through the label manager.
 *
 * Lives on CR4Player as lrDebugTargeting.
 */
class LRDebug_Targeting {
    private var target: CGameplayEntity;
    private var locked: bool;

    public function GetTarget(): CGameplayEntity {
        return target;
    }

    public function ToggleLock() {
        locked = !locked;
    }

    public function IsLocked(): bool {
        return locked;
    }

    public function Select(entities: array<CGameplayEntity>) {
        var entity, bestEntity: CGameplayEntity;
        var i, count: int;
        var camPos, camDir, entPos, toEnt: Vector;
        var score, bestScore, dot, visibilityRange: float;

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

        ApplyTargetChange(bestEntity);
    }

    private function ApplyTargetChange(bestEntity: CGameplayEntity) {
        if (bestEntity == target) return;

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

        if (thePlayer.lrDebugLabelManager) {
            thePlayer.lrDebugLabelManager.UpdatePathLabel(target);
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
}
