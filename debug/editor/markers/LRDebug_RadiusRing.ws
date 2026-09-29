/** A radius sphere, rendered as a low-ish-poly of oneliner line segments. */
class LRDebug_RadiusRing extends LRDebug_MarkerPool {
    private const var segmentsPerCircle: int;    default segmentsPerCircle = 48;
    private const var cos45            : float;  default cos45 = 0.7071068;

    private var starts      : array<Vector>;
    private var ends        : array<Vector>;
    private var segmentCount: int;

    public function Init(baseId: int) {
        var x, y, z, diagA, diagB, origin: Vector;

        x = Vector(1.0, 0.0, 0.0);
        y = Vector(0.0, 1.0, 0.0);
        z = Vector(0.0, 0.0, 1.0);
        diagA = Vector(cos45, cos45, 0.0);
        diagB = Vector(cos45, -cos45, 0.0);
        origin = Vector(0.0, 0.0, 0.0);

        SetBaseId(baseId);

        BuildRing(x, y, origin);
        BuildRing(x, z, origin);
        BuildRing(y, z, origin);

        BuildRing(x * cos45, y * cos45, z * cos45);
        BuildRing(x * cos45, y * cos45, z * -cos45);

        BuildRing(diagA, z, origin);
        BuildRing(diagB, z, origin);

        segmentCount = markers.Size();

        AddDot(x, "#ff0000");
        AddDot(y, "#00ff00");
        AddDot(z, "#0000ff");
    }

    public function Update(center: Vector, radius: float) {
        var i, count: int;
        var start, end: Vector;

        count = markers.Size();
        for (i = 0; i < count; i += 1) {
            // Reset W to 1 - Vector operators are basic and operate on all props
            start = center + starts[i] * radius;
            start.W = 1.0;

            if (i < segmentCount) {
                end = center + ends[i] * radius;
                end.W = 1.0;
                markers[i].SetWorldSegment(start, end);
            }
            else {
                markers[i].SetWorldPosition(start);
            }
        }
    }

    /** One circle of line segments */
    private function BuildRing(u: Vector, v: Vector, center: Vector) {
        var i: int;
        var from, to: Vector;

        for (i = 0; i < segmentsPerCircle; i += 1) {
            from = RingPoint(u, v, center, i);
            to = RingPoint(u, v, center, (i + 1) % segmentsPerCircle);

            AddSegment(from, to, DirectionColor(from));
        }
    }

    private function RingPoint(u: Vector, v: Vector, center: Vector, step: int): Vector {
        var h: Vector = VecFromHeading((360.0 / (float)segmentsPerCircle) * (float)step);

        return center + u * h.Y + v * -h.X;
    }

    private function AddSegment(from: Vector, to: Vector, color: string) {
        AddSegmentMarker(color);
        starts.PushBack(from);
        ends.PushBack(to);
    }

    private function AddDot(offset: Vector, color: string) {
        AddDotMarker(color);
        starts.PushBack(offset);
        ends.PushBack(offset);
    }
}
