/**
 * Exports in-session light edits to the LRDebug log channel so they can be
 * distilled into XML config files by tools/Export-Lights.ps1.
 *
 * Called from lightLabels.ws via LRDebug_OnInputExportEdited.
 *
 * Only fields that differ from the pre-edit baseline (entity.lrDebugBaseline) are
 * emitted, so profile-inherited values aren't re-exported and can't clobber the profile.
 *
 * entity.ToString() format:
 *   CLayer "levels\skellige\spikeroog\village_buildings.w2w"::levels\skellige\spikeroog\village_buildings\braziers_floor_square_bounce.w2ent
 */

/** Set this session and not matching the baseline (absent there, or a different value) */
function LRDebug_FloatEdited(curHas: bool, baseHas: bool, cur: float, base: float): bool {
    return curHas && (!baseHas || cur != base);
}

function LRDebug_ColourEdited(cur: ILightRewriteParams, base: ILightRewriteParams): bool {
    if (!cur.hasColour) return false;
    if (!base.hasColour) return true;
    return cur.color.Red != base.color.Red ||
        cur.color.Green != base.color.Green ||
        cur.color.Blue != base.color.Blue;
}

/** Changed-field segment shared by point and spot lights (prefix "" or "spot_") */
function LRDebug_BuildLightFieldSegment(
    cur: ILightRewriteParams,
    base: ILightRewriteParams,
    prefix: string
): string {
    var line: string = "";

    if (LRDebug_FloatEdited(cur.hasBrightness, base.hasBrightness, cur.brightness, base.brightness)) {
        line += " " + prefix + "brightness=" + FloatToString(cur.brightness);
    }
    if (LRDebug_FloatEdited(cur.hasRadius, base.hasRadius, cur.radius, base.radius)) {
        line += " " + prefix + "radius=" + FloatToString(cur.radius);
    }
    if (LRDebug_FloatEdited(cur.hasAttenuation, base.hasAttenuation, cur.attenuation, base.attenuation)) {
        line += " " + prefix + "attenuation=" + FloatToString(cur.attenuation);
    }
    if (LRDebug_FloatEdited(cur.hasShadowFadeDistance, base.hasShadowFadeDistance, cur.shadowFadeDistance, base.shadowFadeDistance)) {
        line += " " + prefix + "shadowFadeDistance=" + FloatToString(cur.shadowFadeDistance);
    }
    if (LRDebug_FloatEdited(cur.hasShadowFadeRange, base.hasShadowFadeRange, cur.shadowFadeRange, base.shadowFadeRange)) {
        line += " " + prefix + "shadowFadeRange=" + FloatToString(cur.shadowFadeRange);
    }
    if (LRDebug_FloatEdited(cur.hasShadowBlendFactor, base.hasShadowBlendFactor, cur.shadowBlendFactor, base.shadowBlendFactor)) {
        line += " " + prefix + "shadowBlendFactor=" + FloatToString(cur.shadowBlendFactor);
    }

    if (LRDebug_ColourEdited(cur, base)) {
        line += " " + prefix + "colorR=" + IntToString((int)cur.color.Red);
        line += " " + prefix + "colorG=" + IntToString((int)cur.color.Green);
        line += " " + prefix + "colorB=" + IntToString((int)cur.color.Blue);
    }

    return line;
}

/** Changed spotlight fields, spot_-prefixed */
function LRDebug_BuildSpotlightSegment(
    cur: CLightRewriteSpotlightParams,
    base: CLightRewriteSpotlightParams
): string {
    var line: string;

    line = LRDebug_BuildLightFieldSegment(cur, base, "spot_");

    if (LRDebug_FloatEdited(cur.hasInnerAngle, base.hasInnerAngle, cur.innerAngle, base.innerAngle)) {
        line += " spot_innerAngle=" + FloatToString(cur.innerAngle);
    }
    if (LRDebug_FloatEdited(cur.hasOuterAngle, base.hasOuterAngle, cur.outerAngle, base.outerAngle)) {
        line += " spot_outerAngle=" + FloatToString(cur.outerAngle);
    }
    if (LRDebug_FloatEdited(cur.hasSoftness, base.hasSoftness, cur.softness, base.softness)) {
        line += " spot_softness=" + FloatToString(cur.softness);
    }

    if (cur.hasOffset && (!base.hasOffset ||
        cur.offset.X != base.offset.X ||
        cur.offset.Y != base.offset.Y ||
        cur.offset.Z != base.offset.Z)) {
        line += " spot_offsetX=" + FloatToString(cur.offset.X);
        line += " spot_offsetY=" + FloatToString(cur.offset.Y);
        line += " spot_offsetZ=" + FloatToString(cur.offset.Z);
    }

    return line;
}

/** -> levels\skellige\spikeroog\village_buildings.w2w */
function LRDebug_ParseLayerDir(descriptor: string): string {
    if (StrFindFirst(descriptor, "::") == -1) return "";
    if (StrFindFirst(descriptor, "\"") == -1) return "";

    return StrBeforeFirst(StrAfterFirst(StrBeforeFirst(descriptor, "::"), "\""), "\"");
}

/** -> braziers_floor_square_bounce.w2ent */
function LRDebug_ParseEntityFileName(descriptor: string): string {
    if (StrFindFirst(descriptor, "::") == -1) return "";
    return StrAfterLast(StrAfterFirst(descriptor, "::"), StrChar(92));
}

/** Changed-field portion of the export line; empty when nothing changed vs baseline */
function LRDebug_BuildEditedFields(
    params: CLightRewriteSourceParams,
    baseline: CLightRewriteSourceParams
): string {
    var line: string;

    line = LRDebug_BuildLightFieldSegment(params, baseline, "");

    if (params.hasAlignPointLights && (!baseline.hasAlignPointLights ||
        params.alignPointLights != baseline.alignPointLights ||
        params.pointLightOffset.Z != baseline.pointLightOffset.Z)) {
        if (params.alignPointLights) line += " alignPointLights=1";
        else line += " alignPointLights=0";
        line += " alignOffsetZ=" + FloatToString(params.pointLightOffset.Z);
    }

    if (params.hasUseSpotlightColor && (!baseline.hasUseSpotlightColor ||
        params.useSpotlightColor != baseline.useSpotlightColor)) {
        if (params.useSpotlightColor) line += " useSpotlightColor=1";
        else line += " useSpotlightColor=0";
    }

    if (params.spotlight) {
        line += LRDebug_BuildSpotlightSegment(params.spotlight, baseline.spotlight);
    }

    return line;
}

/** Scans all tagged light entities globally and logs any that carry session edits */
function LRDebug_ExportEditedLights() {
    var entities: array<CEntity>;
    var entity: CGameplayEntity;
    var params, baseline: CLightRewriteSourceParams;
    var descriptor, entityFile, layerPath, fields: string;
    var i, count, exported: int;
    var toast: LRDebug_ToastOneLiner;

    theGame.GetEntitiesByTag(theGame.lightRewrite.TAG_HAS_LIGHT, entities);
    count = entities.Size();

    for (i = 0; i < count; i += 1) {
        entity = (CGameplayEntity)entities[i];
        if (!entity) continue;

        params = entity.lrDebugParams;
        baseline = entity.lrDebugBaseline;
        if (!params || !baseline) continue;

        fields = LRDebug_BuildEditedFields(params, baseline);
        if (fields == "") continue;

        descriptor = entity.ToString();
        entityFile = LRDebug_ParseEntityFileName(descriptor);
        layerPath = LRDebug_ParseLayerDir(descriptor);
        if (entityFile == "") continue;

        LogChannel('LRDebug_Export', "entityFile=" + entityFile + " layerPath=" + layerPath + fields);
        exported += 1;
    }

    LogChannel('LRDebug_Export', "done exported=" + IntToString(exported));

    toast = new LRDebug_ToastOneLiner in thePlayer;
    toast.Init("<font size='14'>Exported " + IntToString(exported) + " light(s)</font>", 2.0);
    toast.Start();
}
