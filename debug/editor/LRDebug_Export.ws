/**
 * Exports all in-session light edits to the LRDebug log channel so they can
 * be distilled into XML config files by tools/Export-Lights.ps1.
 *
 * Called from lightLabels.ws via LRDebug_OnInputExportEdited.
 *
 * entity.ToString() format:
 *   CLayer "levels\skellige\spikeroog\village_buildings.w2w"::levels\skellige\spikeroog\village_buildings\braziers_floor_square_bounce.w2ent
 */

// Returns true if the entity has at least one real edit beyond the lazy-getter default.
function LRDebug_HasEdits(params : CLightRewriteSourceParams) : bool {
    if (!params) return false;
    return params.hasBrightness || params.hasRadius || params.hasAttenuation
        || params.hasShadowFadeDistance || params.hasShadowFadeRange
        || params.hasShadowBlendFactor || params.hasColour
        || params.hasAlignPointLights || params.hasUseSpotlightColor;
}

// -> levels\skellige\spikeroog\village_buildings.w2w
function LRDebug_ParseLayerDir(descriptor : string) : string {
    if (StrFindFirst(descriptor, "::") == -1) return "";
    if (StrFindFirst(descriptor, "\"") == -1) return "";

    return StrBeforeFirst(StrAfterFirst(StrBeforeFirst(descriptor, "::"), "\""), "\"");
}

// -> braziers_floor_square_bounce.w2ent
function LRDebug_ParseEntityFileName(descriptor : string) : string {
    if (StrFindFirst(descriptor, "::") == -1) return "";
    return StrAfterLast(StrAfterFirst(descriptor, "::"), StrChar(92));
}

// Assembles the [LREXPORT] log line; only includes fields whose has* guard is true.
function LRDebug_BuildExportLine(
    params     : CLightRewriteSourceParams,
    entityFile : string,
    layerPath  : string
) : string {
    var line: string;

    line = "entityFile=" + entityFile + " layerPath=" + layerPath;

    if (params.hasBrightness)         line += " brightness="         + FloatToString(params.brightness);
    if (params.hasRadius)             line += " radius="             + FloatToString(params.radius);
    if (params.hasAttenuation)        line += " attenuation="        + FloatToString(params.attenuation);
    if (params.hasShadowFadeDistance) line += " shadowFadeDistance=" + FloatToString(params.shadowFadeDistance);
    if (params.hasShadowFadeRange)    line += " shadowFadeRange="    + FloatToString(params.shadowFadeRange);
    if (params.hasShadowBlendFactor)  line += " shadowBlendFactor="  + FloatToString(params.shadowBlendFactor);

    if (params.hasColour) {
        line += " colorR=" + IntToString((int)params.color.Red);
        line += " colorG=" + IntToString((int)params.color.Green);
        line += " colorB=" + IntToString((int)params.color.Blue);
    }

    if (params.hasAlignPointLights) {
        if (params.alignPointLights) line += " alignPointLights=1";
        else line += " alignPointLights=0";
        line += " alignOffsetZ=" + FloatToString(params.pointLightOffset.Z);
    }

    if (params.hasUseSpotlightColor) {
        if (params.useSpotlightColor) line += " useSpotlightColor=1";
        else line += " useSpotlightColor=0";
    }

    return line;
}

// Scans all tagged light entities globally and logs any that carry session edits.
function LRDebug_ExportEditedLights() {
    var entities: array<CEntity>;
    var entity: CGameplayEntity;
    var params: CLightRewriteSourceParams;
    var descriptor, entityFile, layerPath : string;
    var i, count, exported : int;
    var toast: LRDebug_ToastOneLiner;

    theGame.GetEntitiesByTag(theGame.lightRewrite.TAG_HAS_LIGHT, entities);
    count = entities.Size();

    for (i = 0; i < count; i += 1) {
        entity = (CGameplayEntity)entities[i];
        if (!entity) continue;

        params = entity.lrDebugParams;
        if (!LRDebug_HasEdits(params)) continue;

        descriptor = entity.ToString();
        entityFile = LRDebug_ParseEntityFileName(descriptor);
        layerPath  = LRDebug_ParseLayerDir(descriptor);
        if (entityFile == "") continue;

        LogChannel('LRDebug_Export', LRDebug_BuildExportLine(params, entityFile, layerPath));
        exported += 1;
    }

    LogChannel('LRDebug_Export', "done exported=" + IntToString(exported));

    toast = new LRDebug_ToastOneLiner in thePlayer;
    toast.Init("<font size='14'>Exported " + IntToString(exported) + " light(s)</font>", 2.0);
    toast.Start();
}
