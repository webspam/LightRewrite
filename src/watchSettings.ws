// Wires CLightRewriteSettings into the game as a singleton on CR4Game,
// forwards option-change events from CR4IngameMenu, and performs the
// initial config read when the player spawns.

@addField(CR4Game)
private var lightRewriteSettings : CLightRewriteSettings;

// Gets the LightRewrite settings singleton - lazy initialised
@addMethod(CR4Game)
public function GetLightRewriteSettings() : CLightRewriteSettings {
    if (!lightRewriteSettings) {
        lightRewriteSettings = new CLightRewriteSettings in this;
        lightRewriteSettings.Init();
    }
    return lightRewriteSettings;
}

// Ensure the LightRewrite settings are read before the game starts.
@wrapMethod(CR4Game)
function OnGameStarting(restored : bool) {
    wrappedMethod(restored);

    GetLightRewriteSettings().ReadGameConfig();
}

@addField(CR4IngameMenu)
private var lightRewriteSettings : CLightRewriteSettings;

@wrapMethod(CR4IngameMenu)
function OnConfigUI() {
    wrappedMethod();

    lightRewriteSettings = theGame.GetLightRewriteSettings();
    lightRewriteSettings.EnsureGameConfigIsInitialised();
}

// Configure the LightRewrite settings menu when it is opened.
@wrapMethod(CR4IngameMenu)
function OnShowOptionSubmenu(actionType : int, menuTag : int, id : string) {
    wrappedMethod(actionType, menuTag, id);

    if (id == "LightRewrite") {
        lightRewriteSettings.ReadGameConfig();
        lightRewriteSettings.ConfigureModMenu();
    }
}

// Forward every option-change event to the settings object for filtering.
@wrapMethod(CR4IngameMenu)
function OnOptionValueChanged(groupId : int, optionName : name, optionValue : string) {
    var wrappedReturnValue : bool;

    wrappedReturnValue = wrappedMethod(groupId, optionName, optionValue);

    lightRewriteSettings.OptionValueChanged(groupId, optionName, optionValue);

    return wrappedReturnValue;
}
