@wrapMethod(CR4HudModuleOneliners)
function OnTick(timeDelta: float) {
    wrappedMethod(timeDelta);

    if (thePlayer.lrDebugLabels && thePlayer.lrDebugUnknownMarkers) {
        thePlayer.lrDebugUnknownMarkers.Update();
    }
}

/**
 * Permanent HUD flags for light entities the mod isn't tagging.
 *
 * Walking near a point or spot light that lacks TAG_HAS_LIGHT registers it here; the
 * marker then stays put so untracked light sources can be spotted and folded into a profile.
 */
class LRDebug_UnknownLightMarkers extends LRDebug_MarkerPool {
    private const var FONT_SIZE : int;     default FONT_SIZE = 32;
    private const var COLOUR    : string;  default COLOUR = "#ff0000";
    private const var SCAN_RANGE: float;   default SCAN_RANGE = 10.0;

    private var entities       : array<CGameplayEntity>;
    private var registeredGuids: map<CGUID, bool>;
    private var pathLabel      : LRDebug_PathLabel;

    public function Init() {
        SetBaseId(0x40007001);

        pathLabel = new LRDebug_PathLabel in this;
        pathLabel.Init(0x40007000, 0.13, 0.9);
    }

    /** Sweep nearby entities for light sources the mod never tagged and flag each one */
    public function Scan() {
        var found: array<CGameplayEntity>;
        var entity: CGameplayEntity;
        var i, count: int;

        FindGameplayEntitiesInRange(found, thePlayer, SCAN_RANGE, 1024, , FLAG_ExcludePlayer);

        count = found.Size();
        for (i = 0; i < count; i += 1) {
            entity = found[i];
            if (
                !entity ||
                entity.HasTag(theGame.lightRewrite.TAG_HAS_LIGHT) ||
                !entity.HasRewritableLight()
            ) {
                continue;
            }

            Register(entity);
        }
    }

    public function Hide() {
        super.Hide();
        pathLabel.Hide();
    }

    private function Register(entity: CGameplayEntity) {
        var guid: CGUID = entity.guid;

        if (registeredGuids.Contains(guid)) return;

        LogChannel('LRDebugUnknown', "Marking: " + entity.ToString());
        registeredGuids[guid] = true;
        AddMarker("?", FONT_SIZE, COLOUR);
        entities.PushBack(entity);
    }

    public function Update() {
        var i, count: int;

        count = markers.Size();
        for (i = 0; i < count; i += 1) {
            markers[i].SetWorldPosition(entities[i].GetWorldPosition());
        }

        UpdatePathLabel();
    }

    /** Name the nearest untagged light so its layer/entity can be folded into a profile */
    private function UpdatePathLabel() {
        var nearest: CGameplayEntity = NearestEntity();

        if (!nearest) {
            pathLabel.Hide();
            return;
        }

        pathLabel.ShowPath(nearest);
    }

    private function NearestEntity(): CGameplayEntity {
        var playerPos: Vector = thePlayer.GetWorldPosition();
        var nearest: CGameplayEntity;
        var bestDist, dist: float;
        var i, count: int;

        count = entities.Size();
        for (i = 0; i < count; i += 1) {
            dist = VecDistanceSquared(playerPos, entities[i].GetWorldPosition());
            if (!nearest || dist < bestDist) {
                nearest = entities[i];
                bestDist = dist;
            }
        }
        return nearest;
    }
}
