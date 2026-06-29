class LRDebug_ScreenLabel {
    private var id    : int;
    private var ratioX: float;
    private var ratioY: float;

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

    public function ShowPath(entity: CGameplayEntity) {
        SetText(BuildPathLabel(entity));
    }

    public function Hide() {
        if (!created) return;

        Remove();
    }

    private function SetText(text: string) {
        if (text == "") {
            Hide();
            return;
        }

        Create(text);
        Reposition();
    }

    private function Create(text: string) {
        var fxCreate: CScriptedFlashFunction;

        if (created) Remove();

        fxCreate = this.flash.GetMemberFlashFunction("CreateOneliner");
        fxCreate.InvokeSelfTwoArgs(FlashArgInt(this.id), FlashArgString(text));

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

    /**
     * Example entity.ToString():
     * ```
     * CLayer "full\editor\level\path.somext"::full\path\to\entity.w2ent
     * ```
     */
    private function BuildPathLabel(entity: CGameplayEntity): string {
        var descriptor, layerPart, entityPath, levelPath, fileName, filePath, html: string;
        var fontSize: int;

        if (!entity) return "";

        fontSize = 13;
        descriptor = entity.ToString();

        if (StrFindFirst(descriptor, "::") != -1) {
            layerPart = StrBeforeFirst(descriptor, "::");
            entityPath = StrAfterFirst(descriptor, "::");
            levelPath = layerPart;

            if (StrFindFirst(layerPart, "\"") != -1) {
                levelPath = StrBeforeFirst(StrAfterFirst(layerPart, "\""), "\"");
            }

            fileName = StrAfterLast(entityPath, StrChar(92));
            filePath = StrBeforeLast(entityPath, StrChar(92));
        }
        else {
            // Fallback: the raw descriptor when it has no layer/entity split
            filePath = descriptor;
        }

        html = AppendPathLine(html, fileName, fontSize + 3);
        html = AppendPathLine(html, filePath, fontSize - 1);
        html = AppendPathLine(html, levelPath, fontSize + 2);
        return html;
    }

    private function AppendPathLine(html: string, text: string, size: int): string {
        if (text == "") return html;
        if (html != "") html += "<br/>";
        return html + "<font size='" + size + "'>" + EscapeHtml(text) + "</font>";
    }

    private function EscapeHtml(str: string): string {
        var r: string;

        r = StrReplaceAll(str, "&", "&amp;");
        r = StrReplaceAll(r, "<", "&lt;");
        r = StrReplaceAll(r, ">", "&gt;");
        return r;
    }
}
