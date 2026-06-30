/** Owns the flash oneliner sprite; subclasses supply position and text */
class LRDebug_HudLabel {
    protected var id  : int;
    protected var text: string;

    protected var hud   : CR4ScriptedHud;
    protected var flash : CScriptedFlashSprite;
    protected var sprite: CScriptedFlashSprite;

    protected var created  : bool;
    protected var isVisible: bool;

    protected function AcquireFlash() {
        var module: CR4HudModuleOneliners;

        this.hud = (CR4ScriptedHud)theGame.GetHud();
        module = (CR4HudModuleOneliners)this.hud.GetHudModule("OnelinersModule");
        this.flash = module.GetModuleFlash();
    }

    protected function Create() {
        var fxCreate: CScriptedFlashFunction;

        if (created) return;

        fxCreate = this.flash.GetMemberFlashFunction("CreateOneliner");
        fxCreate.InvokeSelfTwoArgs(FlashArgInt(this.id), FlashArgString(this.text));

        this.sprite = this.flash.GetChildFlashSprite("mcOneliner" + this.id);
        this.created = true;

        // A fresh oneliner shows itself; honour our tracked state instead.
        this.sprite.SetVisible(this.isVisible);
    }

    protected function Remove() {
        var fxRemove: CScriptedFlashFunction;

        if (!created) return;

        fxRemove = this.flash.GetMemberFlashFunction("RemoveOneliner");
        fxRemove.InvokeSelfOneArg(FlashArgInt(this.id));
        this.created = false;
    }

    protected function SetScreenPosition(x: float, y: float) {
        this.sprite.SetPosition(x, y);
    }

    protected function SetVisible(visible: bool) {
        if (visible == this.isVisible) return;

        this.isVisible = visible;
        if (created) this.sprite.SetVisible(visible);
    }

    public function Hide() {
        SetVisible(false);
    }

    public function Destroy() {
        Remove();
    }
}
