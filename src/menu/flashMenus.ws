/**
 * Replaces the list of options in a flash menu OPTIONS dropdown (slider, really).
 *
 * The option must already be defined in XML, and must have a list of options
 * of same or greater size.  **Extra** entries are removed by this function.
 *
 * If you do not have enough, you will still be able to move the slider, but the game
 * will not save the change.
 *
 * The options may be placeholders:
 * ```xml
 * <Option id="0"><Entry varId="ID" value="0" /></Option>
 * <Option id="1"><Entry varId="ID" value="1" /></Option>
 * // ... 2, 3, 4, etc.
 * ```
 *
 * Reference code: IngameMenu_AdditionalOptionValueChangeHandling (dropDown) and ShowDeveloperMode
 */
function LR_ReplaceFlashMenuOptions(
    optionId : name,
    optionLabelKey : string,
    groupId : name,
    optionKeys : array<name>
) {
    var groupIndex : int;
    var newObject, existingObject, parentObject : CScriptedFlashObject;
    var flashArray, options : CScriptedFlashArray;
    var currentValue : string;
    var i, count : int;
    var optionText : string;

    var gameConfig : CInGameConfigWrapper = theGame.GetInGameConfigWrapper();
    var ingameMenu : CR4IngameMenu = theGame.GetGuiManager().GetIngameMenu();
    var flash : CScriptedFlashValueStorage = ingameMenu.GetMenuFlashValueStorage();

    if (!ingameMenu) {
        LogLightRewrite("ReplaceFlashMenuOptions: no ingame menu");
        return;
    }

    groupIndex = gameConfig.GetGroupIdx(groupId);
    if (groupIndex < 0) {
        LogLightRewrite("ReplaceFlashMenuOptions: group " + groupId + " not found");
        return;
    }

    currentValue = gameConfig.GetVarValue(groupId, optionId);

    // Remove the existing menu entry
    existingObject = flash.CreateTempFlashObject();
    existingObject.SetMemberFlashUInt("tag", NameToFlashUInt(optionId));
    flashArray = flash.CreateTempFlashArray();
    flashArray.PushBackFlashObject(existingObject);
    parentObject = flash.CreateTempFlashObject();
    parentObject.SetMemberFlashArray("list", flashArray);
    flash.SetFlashObject("options.remove_entry", parentObject);

    // Add all options to the list
    options = flash.CreateTempFlashArray();
    count = optionKeys.Size();
    for (i = 0; i < count; i += 1) {
        optionText = GetLocStringByKeyExt(optionKeys[i]);
        if (optionText == "") optionText = optionKeys[i];

        options.PushBackFlashString(optionText);
    }

    // Create new menu entry
    newObject = flash.CreateTempFlashObject();
    newObject.SetMemberFlashString("id", "1");
    newObject.SetMemberFlashString("label", GetLocStringByKeyExt(optionLabelKey));
    newObject.SetMemberFlashUInt("type", IGMActionType_List);
    newObject.SetMemberFlashUInt("tag", NameToFlashUInt(optionId));
    newObject.SetMemberFlashString("current", currentValue);
    newObject.SetMemberFlashString("startingValue", currentValue);
    newObject.SetMemberFlashInt("groupID", groupIndex);
    newObject.SetMemberFlashBool("checkHardwareCursor", false);
    newObject.SetMemberFlashBool("streamable", false);
    newObject.SetMemberFlashBool("isDropdownContent", false);
    newObject.SetMemberFlashBool("isDeveloper", false);
    newObject.SetMemberFlashArray("subElements", options);

    // Insert new menu entry
    flashArray = flash.CreateTempFlashArray();
    flashArray.PushBackFlashObject(newObject);
    parentObject = flash.CreateTempFlashObject();
    parentObject.SetMemberFlashArray("list", flashArray);

    // Insert under the "Enabled" option
    i = NameToFlashUInt(theGame.GetLightRewriteSettings().GetEnabledOptionId());
    parentObject.SetMemberFlashUInt("masterTag", i);
    flash.SetFlashObject("options.insert_entry", parentObject);

    theGame.GetGuiManager().ForceProcessFlashStorage();
}
