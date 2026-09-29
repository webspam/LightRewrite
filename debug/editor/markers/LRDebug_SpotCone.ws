class LRDebug_SpotCone extends LRDebug_MarkerPool {
    private const var meridianCount      : int;     default meridianCount = 8;
    private const var segmentsPerMeridian: int;     default segmentsPerMeridian = 24;
    private const var segmentsPerRim     : int;     default segmentsPerRim = 32;
    private const var spokesPerCone      : int;     default spokesPerCone = 8;
    private const var outerColor         : string;  default outerColor = "#ffe628";
    private const var innerColor         : string;  default innerColor = "#ff6a00";
    private const var axisColor          : string;  default axisColor = "#ff00ff";

    private var apex, forward, right, up: Vector;

    public function Init(baseId: int) {
        var i, j: int;

        SetBaseId(baseId);

        for (i = 0; i < meridianCount; i += 1) {
            for (j = 0; j < segmentsPerMeridian; j += 1) {
                AddSegmentMarker(DirectionColor(LatitudePoint(MeridianStep(j), MeridianAround(i))));
            }
        }

        AddSegments(segmentsPerRim + spokesPerCone, outerColor);
        AddSegments(segmentsPerRim + spokesPerCone, innerColor);
        AddSegments(1, axisColor);
    }

    public function Update(light: CSpotLightComponent) {
        var localToWorld: Matrix;
        var halfAngle: float;
        var index: int;

        localToWorld = light.GetLocalToWorld();
        apex = light.GetWorldPosition();
        forward = WorldAxis(localToWorld, Vector(0.0, 1.0, 0.0), light.radius);
        right = WorldAxis(localToWorld, Vector(1.0, 0.0, 0.0), light.radius);
        up = WorldAxis(localToWorld, Vector(0.0, 0.0, 1.0), light.radius);

        halfAngle = light.outerAngle * 0.5;

        index = PlaceMeridians(0, halfAngle);
        index = PlaceCone(index, halfAngle);
        index = PlaceCone(index, light.innerAngle * 0.5);
        PlaceSegment(index, apex, apex + forward);
    }

    private function PlaceMeridians(index: int, halfAngle: float): int {
        var i, j: int;
        var around, from: float;

        for (i = 0; i < meridianCount; i += 1) {
            around = MeridianAround(i);

            for (j = 0; j < segmentsPerMeridian; j += 1) {
                from = MeridianStep(j);

                if (from < halfAngle) {
                    PlaceSegment(
                        index,
                        ToWorld(LatitudePoint(from, around)),
                        ToWorld(LatitudePoint(MinF(MeridianStep(j + 1), halfAngle), around))
                    );
                }
                else {
                    markers[index].Hide();
                }

                index += 1;
            }
        }

        return index;
    }

    private function PlaceCone(index: int, halfAngle: float): int {
        var i: int;
        var around: float;

        for (i = 0; i < segmentsPerRim; i += 1) {
            around = 360.0 * (float)i / (float)segmentsPerRim;
            PlaceSegment(
                index,
                ToWorld(LatitudePoint(halfAngle, around)),
                ToWorld(LatitudePoint(halfAngle, around + 360.0 / (float)segmentsPerRim))
            );
            index += 1;
        }

        for (i = 0; i < spokesPerCone; i += 1) {
            around = 360.0 * (float)i / (float)spokesPerCone;
            PlaceSegment(index, apex, ToWorld(LatitudePoint(halfAngle, around)));
            index += 1;
        }

        return index;
    }

    private function LatitudePoint(polar: float, around: float): Vector {
        var tilt: Vector = VecFromHeading(polar);
        var turn: Vector = VecFromHeading(around);

        return Vector(turn.Y * -tilt.X, tilt.Y, -turn.X * -tilt.X);
    }

    private function MeridianStep(step: int): float {
        return 180.0 * (float)step / (float)segmentsPerMeridian;
    }

    private function MeridianAround(meridian: int): float {
        return 360.0 * (float)meridian / (float)meridianCount;
    }

    private function ToWorld(localPos: Vector): Vector {
        return apex + right * localPos.X + forward * localPos.Y + up * localPos.Z;
    }

    private function WorldAxis(localToWorld: Matrix, localAxis: Vector, length: float): Vector {
        return VecNormalize(VecTransformDir(localToWorld, localAxis)) * length;
    }

    private function PlaceSegment(index: int, start: Vector, end: Vector) {
        start.W = 1.0;
        end.W = 1.0;
        markers[index].SetWorldSegment(start, end);
    }

    private function AddSegments(count: int, color: string) {
        var i: int;

        for (i = 0; i < count; i += 1) {
            AddSegmentMarker(color);
        }
    }
}
