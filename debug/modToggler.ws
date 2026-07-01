/**
 * Quick mod toggle key. Bind example:
 * ```ini
 * IK_NumPad0=(Action=LightRewrite_ToggleMod)
 * ```
 */

@wrapMethod(CR4Player)
function OnSpawned(spawnData: SEntitySpawnData) {
    wrappedMethod(spawnData);

    theInput.RegisterListener(
        theGame.GetLightRewriteSettings(),
        'OnToggleMod',
        'LightRewrite_ToggleMod'
    );
}

@addMethod(CLightRewriteSettings)
public function OnToggleMod(action: SInputAction): bool {
    if (!IsPressed(action)) return false;

    LogLightRewrite("Toggling Light Rewrite: " + !isEnabled);

    gameConfig.SetVarValue(GENERAL_GROUP, ENABLED, !isEnabled);
    theGame.SaveUserSettings();
    OptionValueChanged(generalGroupId, ENABLED, !isEnabled);

    return true;
}
