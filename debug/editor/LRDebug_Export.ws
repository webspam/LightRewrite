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
function LRDebug_FloatEdited(
    cur: SLightRewriteOptionalFloat,
    base: SLightRewriteOptionalFloat
): bool {
    return cur.has && (!base.has || cur.value != base.value);
}

function LRDebug_ColourEdited(cur: ILightRewriteParams, base: ILightRewriteParams): bool {
    if (!cur.color.has) return false;
    if (!base.color.has) return true;
    return cur.color.value.Red != base.color.value.Red ||
        cur.color.value.Green != base.color.value.Green ||
        cur.color.value.Blue != base.color.value.Blue;
}

/** Changed-field segment shared by point and spot lights (prefix "" or "spot_") */
function LRDebug_BuildLightFieldSegment(
    cur: ILightRewriteParams,
    base: ILightRewriteParams,
    prefix: string
): string {
    var line: string = "";

    if (LRDebug_FloatEdited(cur.brightness, base.brightness)) {
        line += " " + prefix + "brightness=" + FloatToString(cur.brightness.value);
    }
    if (LRDebug_FloatEdited(cur.radius, base.radius)) {
        line += " " + prefix + "radius=" + FloatToString(cur.radius.value);
    }
    if (LRDebug_FloatEdited(cur.attenuation, base.attenuation)) {
        line += " " + prefix + "attenuation=" + FloatToString(cur.attenuation.value);
    }
    if (LRDebug_FloatEdited(cur.shadowFadeDistance, base.shadowFadeDistance)) {
        line += " " + prefix + "shadowFadeDistance=" + FloatToString(cur.shadowFadeDistance.value);
    }
    if (LRDebug_FloatEdited(cur.shadowFadeRange, base.shadowFadeRange)) {
        line += " " + prefix + "shadowFadeRange=" + FloatToString(cur.shadowFadeRange.value);
    }
    if (LRDebug_FloatEdited(cur.shadowBlendFactor, base.shadowBlendFactor)) {
        line += " " + prefix + "shadowBlendFactor=" + FloatToString(cur.shadowBlendFactor.value);
    }

    if (LRDebug_ColourEdited(cur, base)) {
        line += " " + prefix + "colorR=" + IntToString((int)cur.color.value.Red);
        line += " " + prefix + "colorG=" + IntToString((int)cur.color.value.Green);
        line += " " + prefix + "colorB=" + IntToString((int)cur.color.value.Blue);
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

    if (LRDebug_FloatEdited(cur.innerAngle, base.innerAngle)) {
        line += " spot_innerAngle=" + FloatToString(cur.innerAngle.value);
    }
    if (LRDebug_FloatEdited(cur.outerAngle, base.outerAngle)) {
        line += " spot_outerAngle=" + FloatToString(cur.outerAngle.value);
    }
    if (LRDebug_FloatEdited(cur.softness, base.softness)) {
        line += " spot_softness=" + FloatToString(cur.softness.value);
    }

    if (
        cur.offset.has &&
        (!base.offset.has || cur.offset.value.X != base.offset.value.X || cur.offset.value.Y != base.offset.value.Y || cur.offset.value.Z != base.offset.value.Z)
    ) {
        line += " spot_offsetX=" + FloatToString(cur.offset.value.X);
        line += " spot_offsetY=" + FloatToString(cur.offset.value.Y);
        line += " spot_offsetZ=" + FloatToString(cur.offset.value.Z);
    }

    return line;
}

// -> levels\skellige\spikeroog\village_buildings.w2w
function LRDebug_ParseLayerDir(descriptor: string): string {
    if (StrFindFirst(descriptor, "::") == -1) return "";
    if (StrFindFirst(descriptor, "\"") == -1) return "";

    return StrBeforeFirst(StrAfterFirst(StrBeforeFirst(descriptor, "::"), "\""), "\"");
}

// -> braziers_floor_square_bounce.w2ent
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

    if (
        params.alignPointLights.has &&
        (!baseline.alignPointLights.has || params.alignPointLights.value != baseline.alignPointLights.value || params.pointLightOffset.Z != baseline.pointLightOffset.Z)
    ) {
        if (params.alignPointLights.value) line += " alignPointLights=1";
        else line += " alignPointLights=0";
        line += " alignOffsetZ=" + FloatToString(params.pointLightOffset.Z);
    }

    if (
        params.pointLightOffsetPos.has &&
        (!baseline.pointLightOffsetPos.has || params.pointLightOffsetPos.value.X != baseline.pointLightOffsetPos.value.X || params.pointLightOffsetPos.value.Y != baseline.pointLightOffsetPos.value.Y || params.pointLightOffsetPos.value.Z != baseline.pointLightOffsetPos.value.Z)
    ) {
        line += " pointLightOffset=1";
        line += " pointLightOffsetX=" + FloatToString(params.pointLightOffsetPos.value.X);
        line += " pointLightOffsetY=" + FloatToString(params.pointLightOffsetPos.value.Y);
        line += " pointLightOffsetZ=" + FloatToString(params.pointLightOffsetPos.value.Z);
    }

    if (
        params.useSpotlightColor.has &&
        (!baseline.useSpotlightColor.has || params.useSpotlightColor.value != baseline.useSpotlightColor.value)
    ) {
        if (params.useSpotlightColor.value) line += " useSpotlightColor=1";
        else line += " useSpotlightColor=0";
    }

    if (params.spotlight) {
        line += LRDebug_BuildSpotlightSegment(params.spotlight, baseline.spotlight);
    }

    return line;
}

// Scans all tagged light entities globally and logs any that carry session edits.
function LRDebug_ExportEditedLights() {
    var entities: array<CEntity>;
    var entity: CGameplayEntity;
    var params, baseline: CLightRewriteSourceParams;
    var descriptor, entityFile, layerPath, fields, line: string;
    var loggedLines: array<string>;
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

        line = "entityFile=" + entityFile + " layerPath=" + layerPath + fields;
        if (loggedLines.Contains(line)) continue;
        loggedLines.PushBack(line);

        LogChannel('LRDebug_Export', line);
        exported += 1;
    }

    LogChannel('LRDebug_Export', "done exported=" + IntToString(exported));

    toast = new LRDebug_ToastOneLiner in thePlayer;
    toast.Init("<font size='14'>Exported " + IntToString(exported) + " light(s)</font>", 2.0);
    toast.Start();
}
