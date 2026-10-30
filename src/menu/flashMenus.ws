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
 */
function LR_ReplaceFlashMenuOptions(
    optionId: name,
    optionLabel: string,
    optionTexts: array<string>,
    selectedIndex: int
) {
    var optionEntry, update: CScriptedFlashObject;
    var options, updates: CScriptedFlashArray;
    var flash: CScriptedFlashValueStorage;
    var i, count: int;

    var ingameMenu: CR4IngameMenu = theGame.GetGuiManager().GetIngameMenu();

    if (!ingameMenu) {
        LogLightRewrite("ReplaceFlashMenuOptions: no ingame menu");
        return;
    }

    if (!LR_FindOptionListEntry(LR_GetOptionListModule(ingameMenu), optionId, optionEntry)) {
        LogLightRewrite("ReplaceFlashMenuOptions: option " + optionId + " not found");
        return;
    }

    options = optionEntry.CreateFlashArray();
    count = optionTexts.Size();
    for (i = 0; i < count; i += 1) {
        options.PushBackFlashString(optionTexts[i]);
    }

    optionEntry.SetMemberFlashString("label", optionLabel);
    optionEntry.SetMemberFlashString("startingValue", selectedIndex);
    optionEntry.SetMemberFlashArray("subElements", options);

    flash = ingameMenu.GetMenuFlashValueStorage();
    update = flash.CreateTempFlashObject();
    update.SetMemberFlashUInt("tag", NameToFlashUInt(optionId));
    update.SetMemberFlashString("current", selectedIndex);
    updates = flash.CreateTempFlashArray();
    updates.PushBackFlashObject(update);

    flash.SetFlashArray("options.force_update_values", updates);
    theGame.GetGuiManager().ForceProcessFlashStorage();
}

/*
 * Manually sets the individual properties the SWF uses for "disabled".
 * Mutates the menu entries in-place.
 *
 * This method replaces the old `remove_entry`/`insert_entry` combo, which triggers a bug with
 * sliders "sticking" to the cursor on PC.
 */
function LR_SetMenuOptionDisabled(xmlVarId: name, disabled: bool) {
    var optionListModule: CScriptedFlashSprite;
    var optionEntry, optionListItem, listItemData: CScriptedFlashObject;
    var optionListItems: CScriptedFlashArray;
    var i, count: int;

    var ingameMenu: CR4IngameMenu = theGame.GetGuiManager().GetIngameMenu();
    var tag: int = NameToFlashUInt(xmlVarId);

    optionListModule = LR_GetOptionListModule(ingameMenu);
    if (!LR_FindOptionListEntry(optionListModule, xmlVarId, optionEntry)) {
        LogLightRewrite("SetMenuOptionDisabled: option " + xmlVarId + " not found");
        return;
    }

    optionEntry.SetMemberFlashBool("disabled", disabled);

    optionListItems = optionListModule.GetMemberFlashArray("optionListItems");
    count = optionListItems.GetLength();
    for (i = 0; i < count; i += 1) {
        optionListItem = optionListItems.GetElementFlashObject(i);
        listItemData = optionListItem.GetMemberFlashObject("data");
        if (!listItemData) continue;
        if (listItemData.GetMemberFlashUInt("tag") != tag) continue;

        optionListItem.SetMemberFlashNumber("alpha", disabled ? 0.35 : 1.0);
        optionListItem.SetMemberFlashBool("selectable", !disabled);
        optionListItem.SetMemberFlashBool("mouseChildren", !disabled);
        return;
    }
}

function LR_GetOptionListModule(ingameMenu: CR4IngameMenu): CScriptedFlashSprite {
    return ingameMenu.GetMenuFlash().GetChildFlashSprite("mcOptionListModule");
}

function LR_FindOptionListEntry(
    optionListModule: CScriptedFlashSprite,
    optionId: name,
    out optionEntry: CScriptedFlashObject
): bool {
    var optionListData: CScriptedFlashArray = optionListModule.GetMemberFlashArray(
        "optionListData"
    );
    var tag: int = NameToFlashUInt(optionId);
    var i, count: int;

    count = optionListData.GetLength();
    for (i = 0; i < count; i += 1) {
        optionEntry = optionListData.GetElementFlashObject(i);
        if (optionEntry.GetMemberFlashUInt("tag") == tag) return true;
    }

    return false;
}
