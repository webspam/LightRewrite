/**
 * Can use either fake env time to temporarily change the time of day,
 * or fast-forward/rewind the real game clock.
 */
class LRDebug_Clock {
    private var fakeEnvTime: SLightRewriteOptionalFloat;
    private var scrubbing  : bool;
    private var useRealTime: bool;

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

        theInput.RegisterListener(this, 'OnToggleUseRealTime', 'LRDebug_ToggleUseRealTime');
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

        fakeEnvTime.has = false;
        DisableFakeEnvTime();
        RefreshTimeLabels();
        return true;
    }

    event OnToggleUseRealTime(action: SInputAction) {
        if (!thePlayer.lrDebugLabels || !IsPressed(action)) return false;

        useRealTime = !useRealTime;

        if (useRealTime) DisableFakeEnvTime();
        else if (fakeEnvTime.has) ForceFakeEnvTime(fakeEnvTime.value);

        RefreshTimeLabels();
        return true;
    }

    event OnModifierKey(action: SInputAction) {
        if (!thePlayer.lrDebugLabels) return false;

        if (IsPressed(action) && theInput.lr.IsAltHeld()) {
            theInput.lr.CaptureMouseMovement(this, 'OnMouseAxisX', 'OnMouseAxisY');
            SetEnvLightingTime(CurrentTimeAsHours());
            scrubbing = true;
            ShowClockFace();
        }
        else if (IsReleased(action) && scrubbing) {
            theInput.lr.ReleaseMouseMovement(this);
            scrubbing = false;
            HideClockFace();
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

            hour = CurrentTimeAsHours() + value * modifier * theInput.lr.CLOCK_SCRUB_SENSITIVITY;
            SetEnvLightingTime(hour);
            ShowClockFace();
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
        if (!useRealTime && fakeEnvTime.has) ForceFakeEnvTime(fakeEnvTime.value);
        RefreshTimeLabels();
    }

    public function Disable() {
        if (scrubbing) {
            thePlayer.EnableManualCameraControl(true, theInput.lr.CAMERA_LOCK_SOURCE);
            scrubbing = false;
        }
        HideClockFace();
        DisableFakeEnvTime();
    }

    private function ShowClockFace() {
        if (thePlayer.lrDebugLabelManager) {
            thePlayer.lrDebugLabelManager.ShowClockFace(CurrentTimeAsHours());
        }
    }

    private function HideClockFace() {
        if (thePlayer.lrDebugLabelManager) {
            thePlayer.lrDebugLabelManager.HideClockFace();
        }
    }

    private function SetEnvLightingTime(hour: float) {
        if (useRealTime) {
            WindGameClock(hour);
            return;
        }

        fakeEnvTime.value = LRDebug_FloatOverflow(hour, 24.0);
        fakeEnvTime.has = true;
        ForceFakeEnvTime(fakeEnvTime.value);
        RefreshTimeLabels();
    }

    private function WindGameClock(hour: float) {
        var day: int;
        var hours: int;
        var minutes: int;
        var seconds: int;

        day = GameTimeDays(theGame.GetGameTime());

        while (hour >= 24.0) {
            hour -= 24.0;
            day += 1;
        }
        while (hour < 0.0) {
            hour += 24.0;
            day -= 1;
        }
        day = Clamp(day, 0, 99999);

        hours = (int)hour;
        minutes = (int)((hour - (float)hours) * 60.0);
        seconds = (int)((hour - (float)hours - (float)minutes / 60.0) * 3600.0);

        theGame.SetGameTime(GameTimeCreate(day, hours, minutes, seconds), true);
    }

    private function CurrentTimeAsHours(): float {
        var time: GameTime;

        if (!useRealTime && fakeEnvTime.has) return fakeEnvTime.value;

        time = theGame.GetGameTime();

        return (float)GameTimeHours(time)
            + (float)GameTimeMinutes(time) / 60.0
            + (float)GameTimeSeconds(time) / 3600.0;
    }

    public function IsUsingRealTime(): bool {
        return useRealTime;
    }

    public function GetFakeEnvTime(): SLightRewriteOptionalFloat {
        return fakeEnvTime;
    }

    private function RefreshTimeLabels() {
        if (thePlayer.lrDebugLabelManager) thePlayer.lrDebugLabelManager.RefreshTimeLabels();
    }
}

/** Simulates float overflow in a range of 0.0 to `maximum`. */
function LRDebug_FloatOverflow(value: float, maximum: float): float {
    while (value >= maximum) {
        value -= maximum;
    }
    while (value < 0.0) {
        value += maximum;
    }
    return value;
}
