class LRDebug_WarpLabel extends LRDebug_HudLabel {
    public function Init(id: int, glyph: string) {
        this.id = id;
        this.text = glyph;

        AcquireFlash();
    }

    public function SetGlyph(glyph: string) {
        if (glyph == this.text) return;

        this.text = glyph;

        if (!created) return;

        Remove();
        Create();
    }

    public function Place(x: float, y: float) {
        EnsureCreated();

        this.sprite.SetPosition(x, y);
        SetVisible(true);
    }

    public function Warp(x: float, y: float, rotationDeg: float, scaleX: float, scaleY: float) {
        EnsureCreated();

        this.sprite.SetPosition(x, y);
        this.sprite.SetRotation(rotationDeg);
        this.sprite.SetXScale(scaleX);
        this.sprite.SetYScale(scaleY);
        SetVisible(true);
    }

    private function EnsureCreated() {
        if (!created) Create();
    }
}
