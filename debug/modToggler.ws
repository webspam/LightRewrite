/**
 * Quick mod toggle key. Bind example:
 * ```ini
 * IK_NumPad0=(Action=LightRewrite_ToggleMod)
 * IK_PageUp=(Action=LightRewrite_ToggleTestingProfile)
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

    theInput.RegisterListener(
        theGame.GetLightRewriteSettings(),
        'OnToggleTestingProfile',
        'LightRewrite_ToggleTestingProfile'
    );
}

@addField(CLightRewriteSettings) private var profileBeforeTesting: name;

@addMethod(CLightRewriteSettings)
public function OnToggleTestingProfile(action: SInputAction): bool {
    var testingProfile: name = 'Testing';
    var targetIndex: int;

    if (!IsPressed(action)) return false;

    if (currentProfile == testingProfile) {
        targetIndex = profileOptions.FindFirst(profileBeforeTesting);
        if (targetIndex == -1) targetIndex = FIRST_PROFILE_INDEX;
    }
    else {
        targetIndex = profileOptions.FindFirst(testingProfile);
        if (targetIndex == -1) {
            LogLightRewrite("Profile '" + testingProfile + "' not found");
            return true;
        }
        profileBeforeTesting = currentProfile;
    }

    LogLightRewrite("Switching profile: " + currentProfile + " -> " + profileOptions[targetIndex]);

    gameConfig.SetVarValue(GENERAL_GROUP, CURRENT_PROFILE, targetIndex);
    theGame.SaveUserSettings();
    ReadGameConfig();
    theGame.lightRewrite.ChangeProfile();

    return true;
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
