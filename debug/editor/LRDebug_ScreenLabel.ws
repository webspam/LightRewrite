class LRDebug_ScreenLabel {
    private var id    : int;
    private var ratioX: float;
    private var ratioY: float;
    private var text  : string;

    private var hud    : CR4ScriptedHud;
    private var flash  : CScriptedFlashSprite;
    private var sprite : CScriptedFlashSprite;
    private var created: bool;

    public function Init(id: int, ratioX: float, ratioY: float) {
        var module: CR4HudModuleOneliners;

        this.id = id;
        this.ratioX = ratioX;
        this.ratioY = ratioY;

        this.hud = (CR4ScriptedHud)theGame.GetHud();
        module = (CR4HudModuleOneliners)this.hud.GetHudModule("OnelinersModule");
        this.flash = module.GetModuleFlash();
    }

    public function SetText(text: string) {
        this.text = text;
        Show();
    }

    public function Show() {
        if (text == "") {
            Hide();
            return;
        }

        Create();
        Reposition();
    }

    public function Hide() {
        if (!created) return;

        Remove();
    }

    private function Create() {
        var fxCreate: CScriptedFlashFunction;

        if (created) Remove();

        fxCreate = this.flash.GetMemberFlashFunction("CreateOneliner");
        fxCreate.InvokeSelfTwoArgs(FlashArgInt(this.id), FlashArgString(this.text));

        this.sprite = this.flash.GetChildFlashSprite("mcOneliner" + this.id);
        this.sprite.SetVisible(true);
        created = true;
    }

    private function Remove() {
        var fxRemove: CScriptedFlashFunction = this.flash.GetMemberFlashFunction("RemoveOneliner");

        fxRemove.InvokeSelfOneArg(FlashArgInt(this.id));
        created = false;
    }

    private function Reposition() {
        var point: Vector = this.hud.GetScaleformPoint(ratioX, ratioY);

        this.sprite.SetPosition(point.X, point.Y);
    }
}
