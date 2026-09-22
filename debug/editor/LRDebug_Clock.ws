/**
 * Instantly adjusts game time to the specified time, keeping the current day.
 */
class LRDebug_Clock {
    private var usePmTime: bool;  default usePmTime = true;

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
        var time: GameTime;
        var hour: int;

        if (!ShouldHandleKeyPress(action)) return false;

        usePmTime = !usePmTime;

        time = theGame.GetGameTime();
        hour = GameTimeHours(time);

        ApplyTime(hour % 12, GameTimeMinutes(time), GameTimeSeconds(time));
        return true;
    }

    private function SetClock(action: SInputAction, baseHour: int, optional baseMinute: int): bool {
        if (!ShouldHandleKeyPress(action)) return false;

        ApplyTime(baseHour, baseMinute);
        return true;
    }

    private function ApplyTime(baseHour: int, minute: int, optional second: int) {
        var currentDay: int;
        var time: GameTime;

        var hour: int = baseHour;
        if (usePmTime) hour += 12;

        currentDay = GameTimeDays(theGame.GetGameTime());
        time = GameTimeCreate(currentDay, hour, minute, second);
        theGame.SetGameTime(time, true);
    }

    private function ShouldHandleKeyPress(action: SInputAction): bool {
        return thePlayer.lrDebugLabels
            && IsPressed(action)
            && LRDebug_IsCtrlAltPressed();
    }
}
