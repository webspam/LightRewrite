@addField(CR4Game) public var lrDebugWarp: LRDebug_Warp;

@addMethod(CR4Game)
public function GetLRDebugWarp(): LRDebug_Warp {
    if (!lrDebugWarp) lrDebugWarp = new LRDebug_Warp in this;
    return lrDebugWarp;
}

exec function go(x: float, y: float, z: float, optional world: string) {
    theGame.GetLRDebugWarp().Begin(Vector(x, y, z), world);
}

@wrapMethod(CR4Player)
function OnSpawned(spawnData: SEntitySpawnData) {
    wrappedMethod(spawnData);

    theGame.GetLRDebugWarp().OnPlayerSpawned();
}

@addField(CR4Player) public var lrWarpCameraRotation: EulerAngles;
@addField(CR4Player) public var lrWarpHasPendingCameraRotation: bool;

@addMethod(CR4Player)
public function LRDebugSetCameraRotation(rotation: EulerAngles) {
    lrWarpCameraRotation = rotation;
    lrWarpHasPendingCameraRotation = true;
}

@wrapMethod(CR4Player)
function OnGameCameraPostTick(out moveData: SCameraMovementData, dt: float) {
    var handled: bool;

    handled = wrappedMethod(moveData, dt);

    if (lrWarpHasPendingCameraRotation) {
        moveData.pivotRotationValue = lrWarpCameraRotation;
        lrWarpHasPendingCameraRotation = false;
    }

    return handled;
}
