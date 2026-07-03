// Warns the player on menu exit when the selected preset has inheritance errors

@wrapMethod(CR4IngameMenu)
function OnClosingMenu() {
    if (theGame.GetLightRewriteSettings().ShouldWarnInvalidProfile()) {
        thePlayer.DisplayHudMessage(GetLocStringByKeyExt("LightRewrite_InvalidPresetMessage"));
    }

    wrappedMethod();
}
