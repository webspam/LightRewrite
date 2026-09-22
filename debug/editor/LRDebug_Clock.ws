/**
 * Forces the visual environment time without moving the game clock.
 */
class LRDebug_Clock {
    private var usePmTime: bool;  default usePmTime = true;
    private var baseHour: int;
    private var minute: int;
    private var hasFakeTime: bool;

    public function RegisterListeners() {
        theInput.RegisterListener(this, 'OnClock12', 'LRDebug_Clock12');
        theInput.RegisterListener(this, 'OnClock130', 'LRDebug_Clock130');
        theInput.RegisterListener(this, 'OnClock3', 'LRDebug_Clock3');
        theInput.RegisterListener(this, 'OnClock430', 'LRDebug_Clock430');
        theInput.RegisterListener(this, 'OnClock6', 'LRDebug_Clock6');
        theInput.RegisterListener(this, 'OnClock730', 'LRDebug_Clock730');
        theInput.RegisterListener(this, 'OnClock9', 'LRDebug_Clock9');
        theInput.RegisterListener(this, 'OnClock1030', 'LRDebug_Clock1030');
        theInput.RegisterListener(this, 'OnToggleMeridiem', 'LRDebug_ToggleMeridiem');
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

    private function OnToggleMeridiem(action: SInputAction): bool {
        if (!ShouldHandleKeyPress(action)) return false;

        usePmTime = !usePmTime;
        ApplyTime();
        return true;
    }

    private function SetClock(action: SInputAction, newBaseHour: int, optional newMinute: int): bool {
        if (!ShouldHandleKeyPress(action)) return false;

        baseHour = newBaseHour;
        minute = newMinute;
        ApplyTime();
        return true;
    }

    public function Enable() {
        if (hasFakeTime) ApplyTime();
    }

    public function Disable() {
        DisableFakeEnvTime();
    }

    private function ApplyTime() {
        var hour: int = baseHour;
        if (usePmTime) hour += 12;

        hasFakeTime = true;
        ForceFakeEnvTime((float)hour + (float)minute / 60.0);
    }

    private function ShouldHandleKeyPress(action: SInputAction): bool {
        return thePlayer.lrDebugLabels
            && IsPressed(action)
            && LRDebug_IsCtrlAltPressed();
    }
}
