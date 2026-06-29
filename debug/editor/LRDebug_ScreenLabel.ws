class LRDebug_ScreenLabel {
    private var id    : int;
    private var ratioX: float;
    private var ratioY: float;
    private var text  : string;

    private var hud   : CR4ScriptedHud;
    private var flash : CScriptedFlashSprite;
    private var sprite: CScriptedFlashSprite;

    private var created  : bool;
    private var isVisible: bool;

    public function Init(id: int, ratioX: float, ratioY: float) {
        var module: CR4HudModuleOneliners;

        this.id = id;
        this.ratioX = ratioX;
        this.ratioY = ratioY;

        this.hud = (CR4ScriptedHud)theGame.GetHud();
        module = (CR4HudModuleOneliners)this.hud.GetHudModule("OnelinersModule");
        this.flash = module.GetModuleFlash();
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
        if (text == "") {
            Hide();
            return;
        }

        if (!created) Rebuild();
        SetVisible(true);
    }

    public function Hide() {
        SetVisible(false);
    }

    public function Destroy() {
        if (!created) return;

        Remove();
    }

    private function Rebuild() {
        var fxCreate: CScriptedFlashFunction;

        if (created) Remove();

        fxCreate = this.flash.GetMemberFlashFunction("CreateOneliner");
        fxCreate.InvokeSelfTwoArgs(FlashArgInt(this.id), FlashArgString(this.text));

        this.sprite = this.flash.GetChildFlashSprite("mcOneliner" + this.id);
        this.created = true;

        Reposition();
        this.sprite.SetVisible(this.isVisible);
    }

    private function Remove() {
        var fxRemove: CScriptedFlashFunction = this.flash.GetMemberFlashFunction("RemoveOneliner");

        fxRemove.InvokeSelfOneArg(FlashArgInt(this.id));
        this.created = false;
    }

    private function SetVisible(visible: bool) {
        if (visible == this.isVisible) return;

        this.isVisible = visible;
        if (created) this.sprite.SetVisible(visible);
    }

    private function Reposition() {
        var point: Vector = this.hud.GetScaleformPoint(ratioX, ratioY);

        this.sprite.SetPosition(point.X, point.Y);
    }
}
