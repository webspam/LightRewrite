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

    public function GetMaxRange(): float {
        var maxRange: float = 10.0;

        if (theInput.IsActionPressed('LRDebug_ModifierKey')) maxRange *= 3.0;
        if (theGame.IsFocusModeActive()) maxRange *= 3.0;

        return maxRange;
    }

    public function ToggleLock() {
        locked = !locked;
    }

    public function IsLocked(): bool {
        return locked;
    }

    /**
     * Updates the current target: the closest in-range target to the centre of the viewport.
     * Returns: `true` if target changed
     */
    public function Scan(entities: array<CGameplayEntity>): bool {
        var entity, bestEntity: CGameplayEntity;
        var i, count: int;
        var camPos, camDir, entPos, toEnt: Vector;
        var bestScore, dot: float;

        var visibilityRange: float = GetMaxRange();

        bestScore = -1.0;
        bestEntity = NULL;
        GetCameraPositionAndDirection(camPos, camDir);
        camDir = VecNormalize(camDir);

        count = entities.Size();
        for (i = 0; i < count; i += 1) {
            entity = entities[i];
            if (!entity) continue;

            if (
                !entity.GetComponentByClassName('CPointLightComponent') &&
                !entity.GetComponentByClassName('CSpotLightComponent')
            ) {
                continue;
            }

            // TODO: In-game markers for: !entity.HasTag(theGame.lightRewrite.TAG_HAS_LIGHT)
            entPos = entity.GetWorldPosition();
            if (VecDistanceSquared(thePlayer.GetWorldPosition(), entPos) > (visibilityRange * visibilityRange)) {
                continue;
            }

            toEnt = entPos - camPos;
            if (VecLengthSquared(toEnt) < 0.001) continue;

            toEnt = VecNormalize(toEnt);
            dot = VecDot(toEnt, camDir);

            // Rough in-front filter to reduce "behind camera" picks.
            if (dot < 0.6) continue;

            if (dot > bestScore) {
                bestScore = dot;
                bestEntity = entity;
            }
        }

        if (bestEntity == target) return false;
        ApplyTargetChange(bestEntity);
        return true;
    }

    private function ApplyTargetChange(bestEntity: CGameplayEntity) {
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

    private function GetCameraPositionAndDirection(
        out cameraPosition: Vector,
        out cameraDirection: Vector
    ) {
        var director: CCameraDirector = theGame.GetWorld().GetCameraDirector();

        cameraPosition = director.GetCameraPosition();
        cameraDirection = director.GetCameraDirection();
    }
}
