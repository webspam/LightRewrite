@addField(CR4Player) public var lrLightToggler: LRDebug_LightToggler;

@wrapMethod(CR4Player)
function OnSpawned(spawnData: SEntitySpawnData) {
    wrappedMethod(spawnData);

    lrLightToggler = new LRDebug_LightToggler in this;
    lrLightToggler.Init();
}

/**
 * Toggles every light entity near the player on/off. Bind example:
 * ```ini
 * IK_NumMinus=(Action=LRDebug_ToggleNearbyLights)
 * ```
 */
class LRDebug_LightToggler {
    private const var RANGE: float;  default RANGE = 30.0;

    private var lightsOn: bool;

    public function Init() {
        theInput.RegisterListener(this, 'OnToggleNearbyLights', 'LRDebug_ToggleNearbyLights');
    }

    public function OnToggleNearbyLights(action: SInputAction): bool {
        var changed: int;
        var stateText: string = "OFF";

        if (!IsPressed(action)) return false;

        lightsOn = !lightsOn;
        changed = SetLightsInRange(lightsOn);

        if (lightsOn) stateText = "ON";
        theGame.GetGuiManager().ShowNotification(
            "Nearby lights: " + stateText + " (" + IntToString(changed) + ")",
            1000
        );
        LogChannel('LRDebug', "LRDebug nearby lights " + stateText + ": " + changed);
        return true;
    }

    private function SetLightsInRange(on: bool): int {
        var entities: array<CGameplayEntity>;
        var i, count, changed: int;

        FindGameplayEntitiesInRange(entities, thePlayer, RANGE, 1024, , FLAG_ExcludePlayer);

        count = entities.Size();
        for (i = 0; i < count; i += 1) {
            if (entities[i] && SetLight(entities[i], on)) changed += 1;
        }
        return changed;
    }

    private function SetLight(entity: CGameplayEntity, on: bool): bool {
        var gameplayLight: CGameplayLightComponent;
        var pointChanged, spotChanged: bool;

        gameplayLight = (CGameplayLightComponent)entity.GetComponentByClassName('CGameplayLightComponent');
        if (gameplayLight) {
            if (gameplayLight.IsLightOn() == on) return false;

            gameplayLight.SetLight(on);
            return true;
        }

        if (!entity.HasRewritableLight()) return false;

        pointChanged = SetComponents(entity.GetComponentsByClassName('CPointLightComponent'), on);
        spotChanged = SetComponents(entity.GetComponentsByClassName('CSpotLightComponent'), on);
        return pointChanged || spotChanged;
    }

    private function SetComponents(components: array<CComponent>, on: bool): bool {
        var i, count: int;
        var changed: bool;

        count = components.Size();
        for (i = 0; i < count; i += 1) {
            if (!components[i] || components[i].IsEnabled() == on) continue;

            components[i].SetEnabled(on);
            changed = true;
        }
        return changed;
    }
}
