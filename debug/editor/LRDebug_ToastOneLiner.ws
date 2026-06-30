/**
 * Brief floating text notification that follows the player for a fixed duration.
 * Used to confirm toggle actions (e.g. "LightRewrite: ON").
 *
 * Requires: mod_sharedutils_oneliners (SU_Oneliner)
 */
statemachine class LRDebug_ToastOneLiner extends SU_Oneliner {
    public var seconds: float;

    public function Init(text: string, seconds: float) {
        this.text = text;
        this.seconds = seconds;
    }

    public function Start() {
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
        parent.register();
        Follow();
    }

    event OnLeaveState(next_state_name: name) {
        parent.unregister();
        super.OnLeaveState(next_state_name);
    }

    entry function Follow(): void {
        var startTime, now: float;

        startTime = theGame.GetEngineTimeAsSeconds();
        now = startTime;

        while ((now - startTime) < parent.seconds && thePlayer) {
            parent.position = thePlayer.GetWorldPosition() + Vector(0, 0, 1.7);
            SleepOneFrame();
            now = theGame.GetEngineTimeAsSeconds();
        }

        parent.GotoState('Idle');
    }
}
