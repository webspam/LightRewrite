// Wires CLightRewriteSettings into the game as a singleton on CR4Game,
// forwards option-change events from CR4IngameMenu, and performs the
// initial config read when the player spawns.

@addField(CR4Game)
private var lightRewriteSettings : CLightRewriteSettings;

// Lazy-initialise and return the settings singleton.
@addMethod(CR4Game)
public function GetLightRewriteSettings() : CLightRewriteSettings {
    if (!lightRewriteSettings) {
        lightRewriteSettings = new CLightRewriteSettings in this;
        lightRewriteSettings.Init();
    }
    return lightRewriteSettings;
}

@addField(CR4IngameMenu)
private var lightRewriteSettings : CLightRewriteSettings;

// Capture the singleton reference when the in-game menu UI is built.
@wrapMethod(CR4IngameMenu)
function OnConfigUI() {
    wrappedMethod();
    lightRewriteSettings = theGame.GetLightRewriteSettings();
}

// Forward every option-change event to the settings object for filtering.
@wrapMethod(CR4IngameMenu)
function OnOptionValueChanged(groupId : int, optionName : name, optionValue : string) {
    var wrappedReturnValue : bool;
    wrappedReturnValue = wrappedMethod(groupId, optionName, optionValue);
    if (lightRewriteSettings) {
        lightRewriteSettings.OptionValueChanged(groupId, optionName, optionValue);
    }
    return wrappedReturnValue;
}

// Perform the initial settings read each time the player loads into the world.
@wrapMethod(CR4Player)
function OnSpawned(spawnData : SEntitySpawnData) {
    wrappedMethod(spawnData);
    theGame.GetLightRewriteSettings().ReadGameConfig();
}
