@addField(CR4Player) public var lrRenderToggler: LRDebug_RenderToggler;

@wrapMethod(CR4Player)
function OnSpawned(spawnData: SEntitySpawnData) {
    wrappedMethod(spawnData);

    lrRenderToggler = new LRDebug_RenderToggler in this;
    lrRenderToggler.Init();
}

/**
 * Adds two hotkeys to toggle ray tracing and path tracing. Bind example:
 * ```ini
 * IK_LeftBracket=(Action=LightRewrite_ToggleRayTracing)
 * IK_RightBracket=(Action=LightRewrite_TogglePathTracing)
 * ```
 */
class LRDebug_RenderToggler {
    private const var GRAPHICS_GROUP: name;  default GRAPHICS_GROUP = 'Graphics';
    private const var RAY_TRACING   : name;  default RAY_TRACING = 'EnableRT';
    private const var PATH_TRACING  : name;  default PATH_TRACING = 'PTEnable';
    private const var DLSS_RR       : name;  default DLSS_RR = 'EnableDLSSRR';

    public function Init() {
        theInput.RegisterListener(this, 'OnToggleRayTracing', 'LightRewrite_ToggleRayTracing');
        theInput.RegisterListener(this, 'OnTogglePathTracing', 'LightRewrite_TogglePathTracing');
    }

    public function OnToggleRayTracing(action: SInputAction): bool {
        var enabled: bool;

        if (!IsPressed(action)) return false;

        enabled = Toggle(RAY_TRACING);
        UpdateAO2CorrespondRT(enabled, false);
        Commit("Ray Tracing", enabled);

        return true;
    }

    public function OnTogglePathTracing(action: SInputAction): bool {
        var enabled: bool;

        if (!IsPressed(action)) return false;

        enabled = Toggle(PATH_TRACING);
        Commit("Path Tracing", enabled);

        return true;
    }

    private function Toggle(varName: name): bool {
        var setEnabled: bool = theGame.GetInGameConfigWrapper().GetVarValue(GRAPHICS_GROUP, varName) != "true";

        SetAndRaiseGraphicsVar(varName, setEnabled);
        if (setEnabled && theGame.GetDLSSEnabled() && theGame.GetDLSSRRSupported()) {
            SetAndRaiseGraphicsVar(DLSS_RR, true);
        }

        return setEnabled;
    }

    private function Commit(label: string, enabled: bool) {
        var stateText: string = enabled ? "ON" : "OFF";

        theGame.SaveUserSettings();
        theGame.GetGuiManager().ShowNotification(label + ": " + stateText, 1000);
    }

    private function SetAndRaiseGraphicsVar(varName: name, value: bool) {
        theGame.GetInGameConfigWrapper().SetVarValue(GRAPHICS_GROUP, varName, value);
        theGame.OnConfigValueChanged(varName, value);
    }
}
