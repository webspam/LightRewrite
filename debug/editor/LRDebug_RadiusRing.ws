/** Three great-circle rings of dots around a point light - an XYZ sphere sized to its radius */
class LRDebug_RadiusRing {
    private const var dotCount: int;     default dotCount = 48;
    private const var pastel  : float;   default pastel = 0.5;
    private const var magenta : string;  default magenta = "#ff00ff";

    private var dots   : array<LRDebug_WorldMarker>;
    private var offsets: array<Vector>;

    public function Init(idBase: int) {
        var id: int;

        id = BuildCircle(idBase, 0);
        id = BuildCircle(id, 1);
        id = BuildCircle(id, 2);

        AddDot(id, Vector(1.0, 0.0, 0.0), magenta);
        AddDot(id + 1, Vector(0.0, 1.0, 0.0), magenta);
        AddDot(id + 2, Vector(0.0, 0.0, 1.0), magenta);
    }

    public function Update(center: Vector, radius: float) {
        var i: int;
        var position: Vector;

        for (i = 0; i < dots.Size(); i += 1) {
            position = center + offsets[i] * radius;
            // Reset W to 1 - Vector operators are basic and operate on all props
            position.W = 1.0;
            dots[i].SetWorldPosition(position);
        }
    }

    public function Hide() {
        var i: int;

        for (i = 0; i < dots.Size(); i += 1) {
            dots[i].Hide();
        }
    }

    /** One circle of dots; plane 0=XY, 1=XZ, 2=YZ. Returns the next free marker id */
    private function BuildCircle(idStart: int, plane: int): int {
        var i, id: int;
        var v, dir: Vector;

        id = idStart;
        for (i = 0; i < dotCount; i += 1) {
            v = VecFromHeading((360.0 / (float)dotCount) * (float)i);

            if (plane == 0) {
                dir = Vector(v.X, v.Y, 0.0);
            }
            else if (plane == 1) {
                dir = Vector(v.X, 0.0, v.Y);
            }
            else {
                dir = Vector(0.0, v.X, v.Y);
            }

            AddDot(id, dir, DirectionColor(dir));
            id += 1;
        }
        return id;
    }

    private function AddDot(id: int, offset: Vector, color: string) {
        var dot: LRDebug_WorldMarker;

        dot = new LRDebug_WorldMarker in this;
        dot.Init("&#8226;", 16, color, id);
        dots.PushBack(dot);
        offsets.PushBack(offset);
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
