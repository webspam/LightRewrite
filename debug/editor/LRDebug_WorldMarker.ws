class LRDebug_WorldMarker {
    private var id: int;
    private var text: string;
    private var sprite: CScriptedFlashSprite;

    private var hud: CR4ScriptedHud;
    private var flash: CScriptedFlashSprite;

    private var isVisible: bool;

    private var node: CNode;

    public function Init(text: string, fontSize: int, color: string, id: int) {
        var module: CR4HudModuleOneliners;
        var fxCreate: CScriptedFlashFunction;

        this.text = BuildText(text, fontSize, color);
        this.id = id;

        this.hud = (CR4ScriptedHud)theGame.GetHud();
        module = (CR4HudModuleOneliners)this.hud.GetHudModule("OnelinersModule");
        this.flash = module.GetModuleFlash();

        fxCreate = this.flash.GetMemberFlashFunction("CreateOneliner");

        fxCreate.InvokeSelfTwoArgs(
            FlashArgInt(this.id),
            FlashArgString(this.text)
        );

        this.sprite = this.flash.GetChildFlashSprite("mcOneliner" + this.id);
        this.sprite.SetVisible(false);
        this.isVisible = false;
    }

    public function SetWorldPosition(worldPosition: Vector) {
        var screenPosition: Vector;
        var visible: bool;

        visible = this.WorldToScreen(worldPosition, screenPosition);

        if (visible) {
            this.sprite.SetPosition(screenPosition.X, screenPosition.Y);
        }

        this.SetVisible(visible);
    }

    public function Hide() {
        this.SetVisible(false);
    }

    public function Destroy() {
        var fxRemove: CScriptedFlashFunction = this.flash.GetMemberFlashFunction("RemoveOneliner");

        fxRemove.InvokeSelfOneArg(FlashArgInt(this.id));
    }

    private function SetVisible(isVisible: bool) {
        if (isVisible == this.isVisible) return;

        this.sprite.SetVisible(isVisible);
        this.isVisible = isVisible;
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
