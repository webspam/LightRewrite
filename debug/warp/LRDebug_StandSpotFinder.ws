class LRDebug_StandSpotFinder {
    private const var DIRECTION_COUNT         : int;    default DIRECTION_COUNT = 16;
    private const var OPENNESS_DIRECTION_COUNT: int;    default OPENNESS_DIRECTION_COUNT = 32;
    private const var IDEAL_RADIUS            : float;  default IDEAL_RADIUS = 2.0;
    private const var RING_LAYER_SPACING      : float;  default RING_LAYER_SPACING = 1.0;
    private const var LIGHT_CLEARANCE         : float;  default LIGHT_CLEARANCE = 0.3;
    private const var MAX_DROP                : float;  default MAX_DROP = 12.0;
    private const var MIN_FLOOR_NORMAL_Z      : float;  default MIN_FLOOR_NORMAL_Z = 0.7;
    private const var BODY_RADIUS             : float;  default BODY_RADIUS = 0.35;
    private const var HEADROOM                : float;  default HEADROOM = 2.0;
    private const var EYE_HEIGHT              : float;  default EYE_HEIGHT = 1.7;
    private const var OPENNESS_REACH          : float;  default OPENNESS_REACH = 2.0;
    private const var MIN_OPEN_FRACTION       : float;  default MIN_OPEN_FRACTION = 0.5;
    private const var OPENNESS_WEIGHT         : float;  default OPENNESS_WEIGHT = 4.0;
    private const var NAV_CLEARANCE_RADIUS    : float;  default NAV_CLEARANCE_RADIUS = 0.6;
    private const var SAFE_SPOT_RADIUS        : float;  default SAFE_SPOT_RADIUS = 10.0;

    private var world: CWorld;

    public function Find(light: Vector, out stand: Vector, out facing: EulerAngles): bool {
        world = theGame.GetWorld();

        if (
            !FindRingSpot(light, stand) &&
            !FindSpotBelow(light, stand) &&
            !FindNavigableSpot(light, stand)
        ) {
            return false;
        }

        facing = FacingFrom(stand, light);
        return true;
    }

    private function FacingFrom(stand: Vector, light: Vector): EulerAngles {
        var toLight: Vector = light - EyeOf(stand);
        var rotation: EulerAngles = VecToRotation(toLight);

        return EulerAngles(-rotation.Pitch, VecHeading(toLight), 0);
    }

    private function FindRingSpot(light: Vector, out stand: Vector): bool {
        var layers: array<float> = RingLayerOffsets();
        var radii: array<float> = ProbeRadii();
        var i, j, k, layerCount, radiusCount: int;
        var centre, candidate: Vector;
        var score, bestScore: float;
        var found: bool;

        layerCount = layers.Size();
        radiusCount = radii.Size();
        for (k = 0; k < layerCount; k += 1) {
            centre = light + Vector(0, 0, layers[k]);

            for (i = 0; i < radiusCount; i += 1) {
                for (j = 0; j < DIRECTION_COUNT; j += 1) {
                    if (!TryRingCandidate(
                        light,
                        centre,
                        Direction(j, DIRECTION_COUNT),
                        radii[i],
                        candidate,
                        score
                    )) {
                        continue;
                    }
                    if (found && score >= bestScore) continue;

                    found = true;
                    bestScore = score;
                    stand = candidate;
                }
            }
        }
        return found;
    }

    private function TryRingCandidate(
        light: Vector,
        centre: Vector,
        direction: Vector,
        radius: float,
        out stand: Vector,
        out score: float
    ): bool {
        var probe: Vector = centre + direction * radius;
        var hit, normal: Vector;
        var openFraction: float;

        if (world.StaticTrace(centre + direction * LIGHT_CLEARANCE, probe, hit, normal)) {
            return false;
        }
        if (!FindFloor(probe, stand)) return false;
        if (!HasStandingRoom(stand)) return false;
        if (!world.NavigationCircleTest(stand, NAV_CLEARANCE_RADIUS)) return false;
        if (!HasLineOfSight(stand, light)) return false;

        openFraction = OpenFraction(stand);
        if (openFraction < MIN_OPEN_FRACTION) return false;

        score = AbsF(radius - IDEAL_RADIUS)
            + AbsF(light.Z - stand.Z - EYE_HEIGHT) * 0.25
            - openFraction * OPENNESS_WEIGHT;
        return true;
    }

    private function FindSpotBelow(light: Vector, out stand: Vector): bool {
        return FindFloor(light - Vector(0, 0, LIGHT_CLEARANCE), stand) && HasStandingRoom(stand);
    }

    private function FindNavigableSpot(light: Vector, out stand: Vector): bool {
        var navZ: float;
        var nearFloor: Vector = light - Vector(0, 0, EYE_HEIGHT);

        if (!world.NavigationFindSafeSpot(nearFloor, BODY_RADIUS, SAFE_SPOT_RADIUS, stand)) {
            return false;
        }

        if (world.NavigationComputeZ(stand, stand.Z - MAX_DROP, stand.Z + MAX_DROP, navZ)) {
            stand.Z = navZ;
        }
        return true;
    }

    private function FindFloor(from: Vector, out floor: Vector): bool {
        var normal: Vector;

        if (!world.StaticTrace(from, from - Vector(0, 0, MAX_DROP), floor, normal)) return false;

        return normal.Z >= MIN_FLOOR_NORMAL_Z;
    }

    private function HasStandingRoom(floor: Vector): bool {
        var hit, normal: Vector;
        var sweepStart: Vector = floor + Vector(0, 0, BODY_RADIUS + 0.2);
        var sweepEnd: Vector = floor + Vector(0, 0, HEADROOM - BODY_RADIUS);

        if (world.StaticTrace(
            floor + Vector(0, 0, 0.1),
            floor + Vector(0, 0, HEADROOM),
            hit,
            normal
        )) {
            return false;
        }

        return !world.SweepTest(sweepStart, sweepEnd, BODY_RADIUS, hit, normal);
    }

    private function HasLineOfSight(floor: Vector, light: Vector): bool {
        var eye: Vector = EyeOf(floor);
        var hit, normal: Vector;

        return !world.StaticTrace(
            eye,
            light - VecNormalize(light - eye) * LIGHT_CLEARANCE,
            hit,
            normal
        );
    }

    private function OpenFraction(floor: Vector): float {
        var heights: array<float> = OpennessHeights();
        var i, clear: int;

        for (i = 0; i < OPENNESS_DIRECTION_COUNT; i += 1) {
            if (IsDirectionOpen(floor, Direction(i, OPENNESS_DIRECTION_COUNT), heights)) clear += 1;
        }
        return (float)clear / OPENNESS_DIRECTION_COUNT;
    }

    private function IsDirectionOpen(floor: Vector, direction: Vector, heights: array<float>): bool {
        var hit, normal, start: Vector;
        var i, count: int;

        count = heights.Size();
        for (i = 0; i < count; i += 1) {
            start = floor + Vector(0, 0, heights[i]);
            if (world.SweepTest(
                start,
                start + direction * OPENNESS_REACH,
                BODY_RADIUS,
                hit,
                normal
            )) {
                return false;
            }
        }
        return true;
    }

    private function OpennessHeights(): array<float> {
        var heights: array<float>;

        heights.PushBack(0.6);
        heights.PushBack(1.1);
        heights.PushBack(1.6);
        return heights;
    }

    private function EyeOf(floor: Vector): Vector {
        return floor + Vector(0, 0, EYE_HEIGHT);
    }

    private function Direction(index: int, count: int): Vector {
        return VecFromHeading(360.0 * index / count);
    }

    private function RingLayerOffsets(): array<float> {
        var offsets: array<float>;

        offsets.PushBack(-RING_LAYER_SPACING);
        offsets.PushBack(0);
        offsets.PushBack(RING_LAYER_SPACING);
        return offsets;
    }

    private function ProbeRadii(): array<float> {
        var radii: array<float>;

        radii.PushBack(1.25);
        radii.PushBack(1.75);
        radii.PushBack(2.5);
        radii.PushBack(3.5);
        radii.PushBack(5.0);
        radii.PushBack(7.0);
        return radii;
    }
}
