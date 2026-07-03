// Warns the player on menu exit when the selected preset has inheritance errors

@wrapMethod(CR4IngameMenu)
function OnClosingMenu() {
    LR_NotifyInvalidConfiguration();
    wrappedMethod();
}

function LR_NotifyInvalidConfiguration() {
    if (!theGame.GetLightRewriteSettings().IsCurrentProfileDirty()) return;

    thePlayer.DisplayHudMessage(GetLocStringByKeyExt("LightRewrite_InvalidPresetMessage"));
}
