/** A radius sphere, rendered as a low-ish-poly of oneliner line segments. */
class LRDebug_RadiusRing extends LRDebug_MarkerPool {
    private const var segmentsPerCircle: int;     default segmentsPerCircle = 48;
    private const var glyphWidth       : float;   default glyphWidth = 13.0;
    private const var pastel           : float;   default pastel = 0.5;
    private const var magenta          : string;  default magenta = "#ff00ff";
    private const var cos45            : float;   default cos45 = 0.7071068;

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

        AddDot(x, magenta);
        AddDot(y, magenta);
        AddDot(z, magenta);
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
                markers[i].SetWorldSegment(start, end, glyphWidth);
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
        AddMarker("&#8213;", 16, color);
        starts.PushBack(from);
        ends.PushBack(to);
    }

    private function AddDot(offset: Vector, color: string) {
        AddMarker("&#8226;", 16, color);
        starts.PushBack(offset);
        ends.PushBack(offset);
    }

    /** Blend the axis colours by direction - saturated toward +axis, pastel toward -axis */
    private function DirectionColor(dir: Vector): string {
        var r, g, b, total: float;

        total = AbsF(dir.X) + AbsF(dir.Y) + AbsF(dir.Z);
        if (total <= 0.0) return "#ffffff";

        AddAxis(dir.X, 40.0, 100.0, 255.0, r, g, b);
        AddAxis(dir.Y, 255.0, 230.0, 40.0, r, g, b);
        AddAxis(dir.Z, 204.0, 85.0, 0.0, r, g, b);

        return RgbToHex(r / total, g / total, b / total);
    }

    private function AddAxis(
        comp: float,
        cr: float,
        cg: float,
        cb: float,
        out r: float,
        out g: float,
        out b: float
    ) {
        if (comp >= 0.0) {
            r += comp * cr;
            g += comp * cg;
            b += comp * cb;
        }
        else {
            r += -comp * (cr + (255.0 - cr) * pastel);
            g += -comp * (cg + (255.0 - cg) * pastel);
            b += -comp * (cb + (255.0 - cb) * pastel);
        }
    }

    private function RgbToHex(r: float, g: float, b: float): string {
        return "#" + HexByte(r) + HexByte(g) + HexByte(b);
    }

    private function HexByte(v: float): string {
        var n: int;

        n = Clamp((int)(v + 0.5), 0, 255);
        return HexDigit(n / 16) + HexDigit(n % 16);
    }

    private function HexDigit(d: int): string {
        switch (d) {
            case 10:  return "a";
            case 11:  return "b";
            case 12:  return "c";
            case 13:  return "d";
            case 14:  return "e";
            case 15:  return "f";
            default:  return "" + d;
        }
    }
}
