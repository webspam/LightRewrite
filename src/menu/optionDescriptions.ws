@wrapMethod
function SetDescriptionText(
    optionObject: CScriptedFlashObject,
    optionName: name,
    optionValue: string
) {
    var groupId: int;
    var description, descriptionOn, descriptionOff: string;

    wrappedMethod(optionObject, optionName, optionValue);

    groupId = optionObject.GetMemberFlashInt("groupID");
    if (!theGame.GetLightRewriteSettings().IsMyModSettingsGroup(groupId)) return;

    description = GetLocStringByKeyExt("LightRewrite_MenuDesc_" + optionName);
    descriptionOn = GetLocStringByKeyExt("LightRewrite_MenuDescOn_" + optionName);
    descriptionOff = GetLocStringByKeyExt("LightRewrite_MenuDescOff_" + optionName);

    if (descriptionOn == "" && descriptionOff == "") {
        if (description != "") optionObject.SetMemberFlashString("description", description);
        return;
    }

    if (descriptionOn == "") descriptionOn = description;
    if (descriptionOff == "") descriptionOff = description;

    optionObject.SetMemberFlashString("descriptionTrue", descriptionOn);
    optionObject.SetMemberFlashString("descriptionFalse", descriptionOff);
}
