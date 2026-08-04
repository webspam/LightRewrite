class LRDebug_PathLabel extends LRDebug_ScreenLabel {
    public function ShowPath(entity: CGameplayEntity) {
        super.SetText(BuildPathLabel(entity));
        super.Show();
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
        html = AppendPathLine(html, BuildActiveLightLine(entity), fontSize + 1);
        return html;
    }

    /** The component being edited */
    private function BuildActiveLightLine(entity: CGameplayEntity): string {
        var light: CLightComponent;
        var type: name;
        var count, index: int;
        var prefix: string;

        if (!thePlayer.lrDebugAttrEditor) return "";

        type = thePlayer.lrDebugAttrEditor.GetSelectedLightType(entity);
        index = thePlayer.lrDebugAttrEditor.GetActiveLightIndex(entity, type);

        if (type == 'spot') {
            count = LRDebug_SpotLightCount(entity);
            light = LRDebug_SpotLightAt(entity, index);
            prefix = "S";
        }
        else {
            count = LRDebug_PointLightCount(entity);
            light = LRDebug_PointLightAt(entity, index);
            prefix = "P";
        }

        if (!light) return "";

        return light.GetName() + " " + prefix + (index + 1) + "/" + count;
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
