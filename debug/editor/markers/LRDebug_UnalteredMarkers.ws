/** Marks every light logged as "Unknown light source entity" */
statemachine class LRDebug_UnalteredMarkers extends LRDebug_MarkerPool {
    private const var FONT_SIZE      : int;     default FONT_SIZE = 20;
    private const var GLYPH          : string;  default GLYPH = "&#8226;";
    private const var COLOUR         : string;  default COLOUR = "#e4461a";
    private const var SCREEN_OFFSET_Y: float;   default SCREEN_OFFSET_Y = 40.0;

    private var entities       : array<CGameplayEntity>;
    private var registeredGuids: map<CGUID, bool>;
    private var visible: bool;  default visible = true;
    private var tracking: bool;

    public function Init() {
        SetBaseId(0x4000C000);
        GotoState('Idle');
    }

    public function Start() {
        if (!visible || tracking) return;

        tracking = true;
        GotoState('Tracking');
    }

    public function Stop() {
        tracking = false;
        GotoState('Idle');
    }

    public function Toggle() {
        visible = !visible;

        if (visible) {
            Start();
            thePlayer.lrDebugLabelManager.ShowToast("Unaltered light markers: ON");
        }
        else {
            Stop();
            thePlayer.lrDebugLabelManager.ShowToast("Unaltered light markers: OFF");
        }
    }

    public function Scan(nearbyLights: array<CGameplayEntity>) {
        var entity: CGameplayEntity;
        var i, count: int;

        if (!tracking) return;

        count = nearbyLights.Size();
        for (i = 0; i < count; i += 1) {
            entity = nearbyLights[i];
            if (entity && entity.bypassLightRewrite) {
                Register(entity);
            }
        }
    }

    public function Update() {
        var playerPos: Vector = thePlayer.GetWorldPosition();
        var entityPos: Vector;
        var maxRange: float = thePlayer.lrDebugTargeting.GetMaxRange();
        var maxRangeSquared: float = maxRange * maxRange;
        var i, count: int;

        count = markers.Size();
        for (i = 0; i < count; i += 1) {
            entityPos = entities[i].GetWorldPosition();

            if (
                entities[i].bypassLightRewrite &&
                VecDistanceSquared(playerPos, entityPos) <= maxRangeSquared
            ) {
                markers[i].SetWorldPosition(entityPos, SCREEN_OFFSET_Y);
            }
            else {
                markers[i].Hide();
            }
        }
    }

    private function Register(entity: CGameplayEntity) {
        var guid: CGUID = entity.guid;

        if (registeredGuids.Contains(guid)) return;

        registeredGuids[guid] = true;
        AddMarker(GLYPH, FONT_SIZE, COLOUR);
        entities.PushBack(entity);
    }
}

state Idle in LRDebug_UnalteredMarkers {
    event OnEnterState(previous_state_name: name) {
        super.OnEnterState(previous_state_name);
        parent.Hide();
    }
}

state Tracking in LRDebug_UnalteredMarkers {
    event OnEnterState(previous_state_name: name) {
        super.OnEnterState(previous_state_name);
        Track();
    }

    entry function Track(): void {
        while (true) {
            parent.Update();
            SleepOneFrame();
        }
    }
}
