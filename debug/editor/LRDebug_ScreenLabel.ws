class LRDebug_ScreenLabel extends LRDebug_HudLabel {
    private var ratioX: float;
    private var ratioY: float;

    public function Init(id: int, ratioX: float, ratioY: float) {
        this.id = id;
        this.ratioX = ratioX;
        this.ratioY = ratioY;

        AcquireFlash();
    }

    /** The flash oneliner has no text setter, so changed text means rebuilding the sprite. */
    public function SetText(newText: string) {
        if (newText == this.text) return;

        this.text = newText;

        if (!created) return;

        // Nothing to show; defer the rebuild until Show() has text again.
        if (newText == "") Remove();
        else Rebuild();
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
