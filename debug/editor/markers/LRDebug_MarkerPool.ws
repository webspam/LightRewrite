/**
 * Base for the overlay's world-marker managers.
 *
 * Each pool draws its markers onto the shared oneliner HUD module, so every marker needs a
 * flash id unique across all pools.
 */
class LRDebug_MarkerPool {
    private const var pastel: float;  default pastel = 0.5;

    protected var markers: array<LRDebug_WorldMarker>;
    private var lastId   : int;

    protected function SetBaseId(baseId: int) {
        lastId = baseId;
    }

    protected function AddMarker(text: string, fontSize: int, colour: string) {
        AddHtmlMarker("<font size='" + fontSize + "' color='" + colour + "'>" + text + "</font>");
    }

    protected function AddSegmentMarker(colour: string) {
        AddImageMarker(colour, 64, 2);
    }

    protected function AddDotMarker(colour: string) {
        AddImageMarker(colour, 8, 8);
    }

    private function AddImageMarker(colour: string, width: int, height: int) {
        var marker: LRDebug_WorldMarker;

        marker = AddHtmlMarker("<img src='img://icons/"
            + StrReplace(colour, "#", "")
            + ".png'"
            + " width='" + width + "' height='" + height + "'>");
        marker.SetImageSize(width, height);
    }

    private function AddHtmlMarker(html: string): LRDebug_WorldMarker {
        var marker: LRDebug_WorldMarker;

        lastId += 1;
        marker = new LRDebug_WorldMarker in this;
        marker.Init(html, lastId);

        markers.PushBack(marker);
        return marker;
    }

    public function Hide() {
        var i, count: int;

        count = markers.Size();
        for (i = 0; i < count; i += 1) {
            markers[i].Hide();
        }
    }

    /** Blend the axis colours by direction - saturated toward +axis, pastel toward -axis */
    protected function DirectionColor(dir: Vector): string {
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
