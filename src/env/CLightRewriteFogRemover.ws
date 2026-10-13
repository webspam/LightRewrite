@addField(CR4Game) public var lrFogRemover: CLightRewriteFogRemover;

@wrapMethod(CR4Game)
function OnGameStarting(restored: bool) {
    wrappedMethod(restored);

    lrFogRemover = new CLightRewriteFogRemover in this;
    lrFogRemover.Init();
}

@wrapMethod(CR4Game)
function OnGameStarted(restored: bool) {
    wrappedMethod(restored);

    if (thePlayer) thePlayer.AddTimer('StartLightRewriteFogRemover', 0.f, false);
}

@addMethod(CR4Player)
timer function StartLightRewriteFogRemover(dt: float, id: int) {
    theGame.lrFogRemover.Start(IsInInterior(), theGame.GetLightRewriteSettings());
}

@wrapMethod(CR4Player)
function OnInteriorStateChanged(inInterior: bool) {
    wrappedMethod(inInterior);

    if (theGame.lrFogRemover) theGame.lrFogRemover.SetInterior(inInterior);
}

/** Applies a fog removing .env at varying strength. */
class CLightRewriteFogRemover {
    private const var ENV_PATH: string;  default ENV_PATH = "dlc\lightrewrite\env\no_fog.env";
    private const var PRIORITY: int;     default PRIORITY = 10000;

    private var env              : CLightRewritePrecisionEnv;
    private var fogRemoveStrength: float;
    private var isInterior       : bool;
    private var fadeTime         : float;
    private var isStarted        : bool;

    public function Init() {
        env = new CLightRewritePrecisionEnv in this;
        env.Init(ENV_PATH, PRIORITY);
    }

    public function Start(inInterior: bool, settings: CLightRewriteSettings) {
        isStarted = true;
        isInterior = inInterior;
        ApplySettings(settings);
    }

    public function ApplySettings(settings: CLightRewriteSettings) {
        fogRemoveStrength = settings.isEnabled ? settings.fogRemoval / 100.0 : 0.0;
        fadeTime = settings.fogFadeTime;

        if (isStarted) Refresh(0.0);
    }

    public function SetInterior(inInterior: bool) {
        isInterior = inInterior;
        if (isStarted) Refresh(fadeTime);
    }

    private function Refresh(blendTime: float) {
        env.SetStrength(isInterior ? fogRemoveStrength : 0.0, blendTime);
    }
}
