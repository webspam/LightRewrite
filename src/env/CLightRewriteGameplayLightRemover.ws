@addField(CR4Game) public var lrGameplayLightRemover: CLightRewriteGameplayLightRemover;

@wrapMethod(CR4Game)
function OnGameStarting(restored: bool) {
    wrappedMethod(restored);

    lrGameplayLightRemover = new CLightRewriteGameplayLightRemover in this;
    lrGameplayLightRemover.Init();
}

@wrapMethod(CR4Game)
function OnGameStarted(restored: bool) {
    wrappedMethod(restored);

    if (thePlayer) thePlayer.AddTimer('StartLightRewriteGameplayLightRemover', 0.f, false);
}

@addMethod(CR4Player)
timer function StartLightRewriteGameplayLightRemover(dt: float, id: int) {
    theGame.lrGameplayLightRemover.Start(theGame.GetLightRewriteSettings());
}

/** Applies a gameplay light removing .env at varying strength. */
class CLightRewriteGameplayLightRemover {
    private const var ENV_PATH: string;  default ENV_PATH = "dlc\lightrewrite\env\no_gameplay_light.env";
    private const var PRIORITY: int;     default PRIORITY = 10000;

    private var env      : CLightRewritePrecisionEnv;
    private var isStarted: bool;

    public function Init() {
        env = new CLightRewritePrecisionEnv in this;
        env.Init(ENV_PATH, PRIORITY);
    }

    public function Start(settings: CLightRewriteSettings) {
        isStarted = true;
        ApplySettings(settings);
    }

    public function ApplySettings(settings: CLightRewriteSettings) {
        if (!isStarted) return;

        env.SetStrength(settings.isEnabled ? settings.gameplayLightRemoval / 100.0 : 0.0, 0.0);
    }
}
