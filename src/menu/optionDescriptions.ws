@wrapMethod(CR4IngameMenu)
function OnOptionSelectionChanged(optionName: name, value: bool) {
    var wrappedReturnValue: bool;

    wrappedReturnValue = wrappedMethod(optionName, value);

    if (value) LR_ShowOptionDescription(optionName);

    return wrappedReturnValue;
}

@addMethod(CR4IngameMenu)
function LR_ShowOptionDescription(optionName: name) {
    var description: string;

    if (!lightRewriteSettings.IsLightRewriteSubmenu(lightRewriteLastSubmenuId)) {
        return;
    }

    description = lightRewriteSettings.GetOptionDescription(lightRewriteLastSubmenuId, optionName);
    m_fxUpdateBardsBalladText.InvokeSelfOneArg(FlashArgString(description));
    lightRewriteShowTooltip.InvokeSelfOneArg(FlashArgBool(true));
}
