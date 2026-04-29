// Debug logging for the LightRewrite mod.
function LogLightRewrite(msg : string) {
    LogChannel('LightRewrite', msg);
}

// Sets the "disabled" state of a flash menu option, via a "disabled" tag in the dataArray.
function LR_SetMenuOptionDisabled(
    flashValueStorage : CScriptedFlashValueStorage,
    out dataArray : CScriptedFlashArray,
    xmlVarId : name,
    disabled : bool
) {
    var dataObject : CScriptedFlashObject = flashValueStorage.CreateTempFlashObject();

    dataObject.SetMemberFlashUInt("tag", NameToFlashUInt(xmlVarId));
    dataObject.SetMemberFlashBool("disabled", disabled);
    dataArray.PushBackFlashObject(dataObject);
}
