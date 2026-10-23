statemachine class LRDebug_Warp {
    private const var STREAMED_RADIUS         : float;  default STREAMED_RADIUS = 40.0;
    private const var NOTIFY_DURATION_MS      : float;  default NOTIFY_DURATION_MS = 5000;
    private const var BRIEF_NOTIFY_DURATION_MS: float;  default BRIEF_NOTIFY_DURATION_MS = 3000;

    private var lookPointResolver: LRDebug_LookPointResolver;
    private var finder           : LRDebug_StandSpotFinder;
    private var entityPosition   : Vector;
    private var worldPath        : string;

    public function Begin(entityPosition: Vector, world: string) {
        worldPath = ResolveWorldPath(world);
        if (worldPath == "") {
            Notify("Unknown world '" + world + "'. Known: " + KnownWorlds(), NOTIFY_DURATION_MS);
            return;
        }

        this.entityPosition = entityPosition;

        if (IsInTargetWorld()) {
            GotoState('Arriving');
            return;
        }

        GotoState('AwaitingWorld');
        Notify("Changing world: " + worldPath, BRIEF_NOTIFY_DURATION_MS);
        theGame.ScheduleWorldChangeToPosition(worldPath, entityPosition, EulerAngles(0, 0, 0));
    }

    public function OnPlayerSpawned() {
        if (IsInState('AwaitingWorld')) {
            GotoState(IsInTargetWorld() ? 'Arriving' : 'Idle');
        }
    }

    public function MoveNearTarget() {
        var playerPosition: Vector = thePlayer.GetWorldPosition();
        var distanceSquared: float = VecDistanceSquared(playerPosition, entityPosition);

        if (distanceSquared > STREAMED_RADIUS * STREAMED_RADIUS) thePlayer.Teleport(entityPosition);
    }

    public function NotifyNoStandSpot() {
        var formattedPosition: string = VecToStringPrec(entityPosition, 2);

        Notify("No stand spot found near " + formattedPosition, BRIEF_NOTIFY_DURATION_MS);
    }

    public function TryArrive(): bool {
        var lookPoint, stand: Vector;
        var facing: EulerAngles;

        if (!lookPointResolver) lookPointResolver = new LRDebug_LookPointResolver in this;
        if (!finder) finder = new LRDebug_StandSpotFinder in this;

        lookPoint = lookPointResolver.Resolve(entityPosition);
        if (!finder.Find(lookPoint, stand, facing)) {
            return false;
        }

        thePlayer.TeleportWithRotation(stand, EulerAngles(0, facing.Yaw, 0));
        thePlayer.LRDebugSetCameraRotation(facing);
        return true;
    }

    private function IsInTargetWorld(): bool {
        return StrCmp(theGame.GetWorld().GetPath(), worldPath, , true) == 0;
    }

    private function ResolveWorldPath(world: string): string {
        var pins: array<SAreaMapPinInfo>;
        var i, count: int;

        if (world == "") return theGame.GetWorld().GetPath();
        if (StrEndsWith(world, ".w2w")) return world;

        pins = theGame.GetCommonMapManager().GetAreaMapPins();
        count = pins.Size();
        for (i = 0; i < count; i += 1) {
            if (MatchesWorld(world, pins[i])) return pins[i].worldPath;
        }
        return "";
    }

    private function MatchesWorld(world: string, pin: SAreaMapPinInfo): bool {
        return StrCmp(world, NameToString(pin.areaName), , true) == 0
            || StrCmp(world, FileStem(pin.worldPath), , true) == 0
            || StrCmp(world, DirectoryStem(pin.worldPath), , true) == 0;
    }

    private function KnownWorlds(): string {
        var pins: array<SAreaMapPinInfo> = theGame.GetCommonMapManager().GetAreaMapPins();
        var names: array<string>;
        var known: string;
        var i, count: int;

        count = pins.Size();
        for (i = 0; i < count; i += 1) {
            if (!names.Contains(DirectoryStem(pins[i].worldPath))) {
                names.PushBack(DirectoryStem(pins[i].worldPath));
            }
        }

        count = names.Size();
        for (i = 0; i < count; i += 1) {
            if (i > 0) known += ", ";
            known += names[i];
        }
        return known;
    }

    private function FileStem(path: string): string {
        return StrReplace(StrAfterLast(path, StrChar(92)), ".w2w", "");
    }

    private function DirectoryStem(path: string): string {
        return StrAfterLast(StrBeforeLast(path, StrChar(92)), StrChar(92));
    }

    private function Notify(message: string, durationMs: float) {
        theGame.GetGuiManager().ShowNotification(message, durationMs);
        LogChannel('LRWarp', message);
    }
}

state Idle in LRDebug_Warp {}

state AwaitingWorld in LRDebug_Warp {}

state Arriving in LRDebug_Warp {
    private const var TIMEOUT_SECONDS: float;  default TIMEOUT_SECONDS = 2.0;

    event OnEnterState(previous_state_name: name) {
        super.OnEnterState(previous_state_name);
        ArriveAfterStreaming();
    }

    entry function ArriveAfterStreaming(): void {
        var deadline: float;

        parent.MoveNearTarget();
        deadline = theGame.GetEngineTimeAsSeconds() + TIMEOUT_SECONDS;

        SleepOneFrame();
        while (!parent.TryArrive()) {
            if (theGame.GetEngineTimeAsSeconds() >= deadline) {
                parent.NotifyNoStandSpot();
                break;
            }

            SleepOneFrame();
        }

        parent.GotoState('Idle');
    }
}
