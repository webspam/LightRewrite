/**
 * Brief floating text notification that follows the player for a fixed duration.
 * Used to confirm toggle actions (e.g. "LightRewrite: ON").
 */
statemachine class LRDebug_ToastOneLiner extends LRDebug_WorldMarker {
    public var seconds: float;

    public function Show(html: string, seconds: float) {
        this.seconds = seconds;
        SetText(html);

        if (this.IsInState('FollowPlayer')) {
            this.GotoState('Idle');
        }
        this.GotoState('FollowPlayer');
    }
}

state Idle in LRDebug_ToastOneLiner {}

state FollowPlayer in LRDebug_ToastOneLiner {
    event OnEnterState(previous_state_name: name) {
        super.OnEnterState(previous_state_name);
        Follow();
    }

    event OnLeaveState(next_state_name: name) {
        parent.Hide();
        super.OnLeaveState(next_state_name);
    }

    entry function Follow(): void {
        var startTime, now: float;

        startTime = theGame.GetEngineTimeAsSeconds();
        now = startTime;

        while ((now - startTime) < parent.seconds && thePlayer) {
            parent.SetWorldPosition(thePlayer.GetWorldPosition() + Vector(0, 0, 1.7));
            SleepOneFrame();
            now = theGame.GetEngineTimeAsSeconds();
        }

        parent.GotoState('Idle');
    }
}
