class LRDebug_WorldMarker extends LRDebug_HudLabel {
    // Off-screen markers sit on this inset box (ndc half-extent), leaving a glyph margin
    private const var edgeBox: float;  default edgeBox = 0.9;

    public function Init(text: string, fontSize: int, color: string, id: int) {
        this.text = BuildText(text, fontSize, color);
        this.id = id;

        AcquireFlash();
        Create();
    }

    public function SetWorldPosition(worldPosition: Vector) {
        var ndc, screen: Vector;
        var visible: bool;

        visible = theCamera.WorldVectorToViewRatio(worldPosition, ndc.X, ndc.Y);

        if (visible) {
            screen = NdcToScreen(ndc);
            SetScreenPosition(screen.X, screen.Y);
        }

        SetVisible(visible);
    }

    /** Marks the entity in-world when on-screen, else pins to the screen edge in its direction */
    public function SetWorldPositionClamped(
        worldPosition: Vector,
        camPos: Vector,
        right: Vector,
        up: Vector
    ) {
        var ndc, screen: Vector;

        if (!WorldToNdc(worldPosition, ndc)) {
            EdgeNdc(worldPosition, camPos, right, up, ndc);
        }

        screen = NdcToScreen(ndc);
        SetScreenPosition(screen.X, screen.Y);
        SetVisible(true);
    }

    /** True only when the point projects inside the viewport; ndc is normalised [-1, 1] */
    private function WorldToNdc(worldPosition: Vector, out ndc: Vector): bool {
        if (!theCamera.WorldVectorToViewRatio(worldPosition, ndc.X, ndc.Y)) return false;

        return AbsF(ndc.X) <= 1.0 && AbsF(ndc.Y) <= 1.0;
    }

    /** Direction from the camera to the point, projected onto the inset edge box */
    private function EdgeNdc(
        worldPosition: Vector,
        camPos: Vector,
        right: Vector,
        up: Vector,
        out ndc: Vector
    ) {
        var to: Vector = worldPosition - camPos;
        var dx: float = VecDot(to, right);
        var dy: float = -VecDot(to, up); // screen Y grows downward
        var len: float = SqrtF(dx * dx + dy * dy);
        var t: float;

        if (len < 0.0001) {
            ndc.X = 0.0;
            ndc.Y = edgeBox;
            return;
        }

        dx /= len;
        dy /= len;
        t = edgeBox / MaxF(AbsF(dx), AbsF(dy));
        ndc.X = dx * t;
        ndc.Y = dy * t;
    }

    private function NdcToScreen(ndc: Vector): Vector {
        return this.hud.GetScaleformPoint((ndc.X + 1.0) * 0.5, (ndc.Y + 1.0) * 0.5);
    }

    private function BuildText(text: string, fontSize: int, color: string): string {
        return "<font size='" + fontSize + "' color='" + color + "'>" + text + "</font>";
    }
}
