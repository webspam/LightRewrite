class LRDebug_WorldMarker extends LRDebug_HudLabel {
    // Off-screen markers sit on this inset box (ndc half-extent), leaving a glyph margin
    private const var edgeBox: float;  default edgeBox = 0.9;

    private const var radToDeg       : float;  default radToDeg = 57.29578;
    private const var edgeSearchSteps: int;    default edgeSearchSteps = 12;

    private var imageWidth : float;
    private var imageHeight: float;

    public function Init(html: string, id: int) {
        this.text = html;
        this.id = id;

        AcquireFlash();
        Create();
    }

    public function SetImageSize(width: float, height: float) {
        imageWidth = width;
        imageHeight = height;
    }

    public function SetWorldPosition(worldPosition: Vector, optional screenOffsetY: float) {
        var ndc, screen: Vector;
        var visible: bool;

        visible = theCamera.WorldVectorToViewRatio(worldPosition, ndc.X, ndc.Y);

        if (visible) {
            screen = NdcToScreen(ndc);
            SetScreenPosition(screen.X, screen.Y + imageHeight * 0.5 + screenOffsetY);
        }

        SetVisible(visible);
    }

    /** Rotates and stretches a glyph to span between two world points. */
    public function SetWorldSegment(startWorld: Vector, endWorld: Vector) {
        var startNdc, endNdc: Vector;
        var startVisible, endVisible: bool;

        startVisible = theCamera.WorldVectorToViewRatio(startWorld, startNdc.X, startNdc.Y);
        endVisible = theCamera.WorldVectorToViewRatio(endWorld, endNdc.X, endNdc.Y);

        if (startVisible && !endVisible) {
            endNdc = FindViewportEdge(startWorld, endWorld, startNdc);
        }
        else if (endVisible && !startVisible) {
            startNdc = FindViewportEdge(endWorld, startWorld, endNdc);
        }

        if ((startVisible || endVisible) && ClipToViewport(startNdc, endNdc)) {
            SetScreenSegment(NdcToScreen(startNdc), NdcToScreen(endNdc));
        }
        else {
            SetVisible(false);
        }
    }

    private function FindViewportEdge(
        insideWorld: Vector,
        outsideWorld: Vector,
        insideNdc: Vector
    ): Vector {
        var probeWorld, probeNdc: Vector;
        var i: int;

        for (i = 0; i < edgeSearchSteps; i += 1) {
            probeWorld = (insideWorld + outsideWorld) * 0.5;

            if (theCamera.WorldVectorToViewRatio(probeWorld, probeNdc.X, probeNdc.Y)) {
                insideWorld = probeWorld;
                insideNdc = probeNdc;
            }
            else {
                outsideWorld = probeWorld;
            }
        }

        return insideNdc;
    }

    private function ClipToViewport(out start: Vector, out end: Vector): bool {
        var dx, dy: float;
        var clipStart: float = 0.0;
        var clipEnd: float = 1.0;

        dx = end.X - start.X;
        dy = end.Y - start.Y;

        if (!ClipToEdge(-dx, start.X + 1.0, clipStart, clipEnd)) return false;
        if (!ClipToEdge(dx, 1.0 - start.X, clipStart, clipEnd)) return false;
        if (!ClipToEdge(-dy, start.Y + 1.0, clipStart, clipEnd)) return false;
        if (!ClipToEdge(dy, 1.0 - start.Y, clipStart, clipEnd)) return false;

        end.X = start.X + dx * clipEnd;
        end.Y = start.Y + dy * clipEnd;
        start.X += dx * clipStart;
        start.Y += dy * clipStart;
        return true;
    }

    private function ClipToEdge(
        towardEdge: float,
        distanceToEdge: float,
        out clipStart: float,
        out clipEnd: float
    ): bool {
        var t: float;

        if (towardEdge == 0.0) return distanceToEdge >= 0.0;

        t = distanceToEdge / towardEdge;
        if (towardEdge < 0.0) {
            if (t > clipEnd) return false;
            clipStart = MaxF(clipStart, t);
        }
        else {
            if (t < clipStart) return false;
            clipEnd = MinF(clipEnd, t);
        }
        return true;
    }

    public function SetScreenSegment(startScreen: Vector, endScreen: Vector) {
        var dx, dy, length: float;

        dx = endScreen.X - startScreen.X;
        dy = endScreen.Y - startScreen.Y;
        length = MaxF(SqrtF(dx * dx + dy * dy), 0.001);

        SetScreenPosition(
            (startScreen.X + endScreen.X) * 0.5 + dy / length * imageHeight * 0.5,
            (startScreen.Y + endScreen.Y) * 0.5 - dx / length * imageHeight * 0.5
        );
        this.sprite.SetRotation(AtanF(dy, dx) * radToDeg);
        this.sprite.SetXScale(length / imageWidth * 100.0);
        SetVisible(true);
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
}
