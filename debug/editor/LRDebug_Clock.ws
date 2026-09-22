/**
 * Forces the visual environment time without moving the game clock.
 */
class LRDebug_Clock {
    private var fakeEnvTime       : float;
    private var forcingFakeEnvTime: bool;
    private var scrubbing         : bool;
    private var hasFakeTime: bool;

    public function RegisterListeners() {
        theInput.RegisterListener(this, 'OnModifierKey', 'LRDebug_ModifierKey');
        theInput.RegisterListener(this, 'OnClock12', 'LRDebug_Clock12');
        theInput.RegisterListener(this, 'OnClock130', 'LRDebug_Clock130');
        theInput.RegisterListener(this, 'OnClock3', 'LRDebug_Clock3');
        theInput.RegisterListener(this, 'OnClock430', 'LRDebug_Clock430');
        theInput.RegisterListener(this, 'OnClock6', 'LRDebug_Clock6');
        theInput.RegisterListener(this, 'OnClock730', 'LRDebug_Clock730');
        theInput.RegisterListener(this, 'OnClock9', 'LRDebug_Clock9');
        theInput.RegisterListener(this, 'OnClock1030', 'LRDebug_Clock1030');
        theInput.RegisterListener(this, 'OnResetClock', 'LRDebug_ResetClock');
    }

    event OnClock12(action: SInputAction) {
        return SetClock(action, 0);
    }

    event OnClock130(action: SInputAction) {
        return SetClock(action, 1, 30);
    }

    event OnClock3(action: SInputAction) {
        return SetClock(action, 3);
    }

    event OnClock430(action: SInputAction) {
        return SetClock(action, 4, 30);
    }

    event OnClock6(action: SInputAction) {
        return SetClock(action, 6);
    }

    event OnClock730(action: SInputAction) {
        return SetClock(action, 7, 30);
    }

    event OnClock9(action: SInputAction) {
        return SetClock(action, 9);
    }

    event OnClock1030(action: SInputAction) {
        return SetClock(action, 10, 30);
    }

    event OnResetClock(action: SInputAction) {
        if (
            !thePlayer.lrDebugLabels ||
            !IsPressed(action) ||
            theInput.lr.IsNormalKeydown(action)
        ) {
            return false;
        }

        forcingFakeEnvTime = false;
        DisableFakeEnvTime();
        return true;
    }

    event OnModifierKey(action: SInputAction) {
        if (!thePlayer.lrDebugLabels) return false;

        if (IsPressed(action) && theInput.lr.IsAltHeld()) {
            theInput.lr.CaptureMouseMovement(this, 'OnMouseAxisX', 'OnMouseAxisY');
            SetEnvLightingTime(GameTimeHours(theGame.GetGameTime()));
            scrubbing = true;
        }
        else if (IsReleased(action) && scrubbing) {
            theInput.lr.ReleaseMouseMovement(this);
            scrubbing = false;
        }
    }

    event OnMouseAxisX(action: SInputAction) {
        if (action.value) ScrubClock(action.value);
    }

    event OnMouseAxisY(action: SInputAction) {
        if (action.value) ScrubClock(-action.value);
    }

    private function ScrubClock(value: float) {
        var modifier: float = 1.f;
        var hour: float;

        if (scrubbing) {
            if (theInput.lr.IsCtrlHeld()) modifier = 0.1f;

            hour = fakeEnvTime + value * modifier * theInput.lr.CLOCK_SCRUB_SENSITIVITY;
            SetEnvLightingTime(FloatOverflow24(hour));
        }
    }

    private function SetClock(action: SInputAction, baseHour: int, optional minute: int): bool {
        var ctrlHeld: bool = theInput.lr.IsCtrlHeld();
        var altHeld: bool = theInput.lr.IsAltHeld();
        var hour: int;

        if (!thePlayer.lrDebugLabels || !IsPressed(action) || ctrlHeld == altHeld) return false;

        hour = baseHour;
        if (altHeld) hour += 12;

        SetEnvLightingTime((float)hour + (float)minute / 60.0);
        return true;
    }

    public function Enable() {
        if (forcingFakeEnvTime) ForceFakeEnvTime(fakeEnvTime);
    }

    public function Disable() {
        if (scrubbing) {
            thePlayer.EnableManualCameraControl(true, theInput.lr.CAMERA_LOCK_SOURCE);
            scrubbing = false;
        }
        DisableFakeEnvTime();
    }

    private function SetEnvLightingTime(hour: float) {
        fakeEnvTime = hour;
        forcingFakeEnvTime = true;
        ForceFakeEnvTime(hour);
    }

    private function FloatOverflow24(hour: float): float {
        while (hour >= 24.0) {
            hour -= 24.0;
        }
        while (hour < 0.0) {
            hour += 24.0;
        }
        return hour;
    }
}
