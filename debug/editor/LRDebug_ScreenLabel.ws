class LRDebug_ScreenLabel extends LRDebug_HudLabel {
    private var ratioX: float;
    private var ratioY: float;

    public function Init(
        id: int,
        ratioX: float,
        ratioY: float,
        optional hAlign: ELRHorizontalAlign,
        optional vAlign: ELRVerticalAlign
    ) {
        this.id = id;
        this.ratioX = ratioX;
        this.ratioY = ratioY;
        this.horizontalAlign = hAlign;
        this.verticalAlign = vAlign;

        AcquireFlash();
    }

    public function SetText(newText: string) {
        if (newText == "") Remove();
        super.SetText(newText);
    }

    public function Show() {
        if (text == "") return;

        if (!created) Rebuild();
        SetVisible(true);
    }

    private function Rebuild() {
        Remove();
        Create();
        Reposition();
    }

    private function Reposition() {
        var point: Vector = this.hud.GetScaleformPoint(ratioX, ratioY);

        SetScreenPosition(point.X, point.Y);
    }
}
