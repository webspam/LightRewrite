class LRDebug_WorldMarker extends LRDebug_HudLabel {
    public function Init(text: string, fontSize: int, color: string, id: int) {
        this.text = BuildText(text, fontSize, color);
        this.id = id;

        AcquireFlash();
        Create();
    }

    public function SetWorldPosition(worldPosition: Vector) {
        var screenPosition: Vector;
        var visible: bool;

        visible = WorldToScreen(worldPosition, screenPosition);

        if (visible) SetScreenPosition(screenPosition.X, screenPosition.Y);

        SetVisible(visible);
    }

    private function BuildText(text: string, fontSize: int, color: string): string {
        return "<font size='" + fontSize + "' color='" + color + "'>" + text + "</font>";
    }

    private function WorldToScreen(worldPosition: Vector, out screenPosition: Vector): bool {
        if (!theCamera.WorldVectorToViewRatio(worldPosition, screenPosition.X, screenPosition.Y)) {
            return false;
        }

        screenPosition.X = (screenPosition.X + 1) * 0.5;
        screenPosition.Y = (screenPosition.Y + 1) * 0.5;

        screenPosition = this.hud.GetScaleformPoint(screenPosition.X, screenPosition.Y);

        return true;
    }
}
