/**
 * A flat ring of dot markers around a point light, sized to the light's radius so
 * its reach is visible on the ground in game space.
 *
 * Owned by LRDebug_TargetMarkers, which drives Update() each oneliner-HUD tick with
 * the light's current world position and radius.
 */
class LRDebug_RadiusRing {
    private const var dotCount: int;  default dotCount = 24;

    private var dots: array<LRDebug_WorldMarker>;

    public function Init(color: string, idBase: int) {
        var i: int;
        var dot: LRDebug_WorldMarker;

        for (i = 0; i < dotCount; i += 1) {
            dot = new LRDebug_WorldMarker in this;
            // &#8226; is a centred bullet dot rather than a baseline full stop
            dot.Init("&#8226;", 16, color, idBase + i);
            dots.PushBack(dot);
        }
    }

    /** Lay the dots evenly around the XY-plane circle of `radius` centred on `center`. */
    public function Update(center: Vector, radius: float) {
        var i: int;
        var heading: float;
        var position: Vector;

        for (i = 0; i < dotCount; i += 1) {
            heading = (360.0 / (float)dotCount) * (float)i;
            position = center + VecFromHeading(heading) * radius;
            dots[i].SetWorldPosition(position);
        }
    }

    public function Hide() {
        var i: int;

        for (i = 0; i < dots.Size(); i += 1) {
            dots[i].Hide();
        }
    }
}
