/** Activates a .env at a given strength, replacing any previous activation. */
class CLightRewritePrecisionEnv {
    private var path      : string;
    private var priority  : int;
    private var definition: CEnvironmentDefinition;
    private var strength  : float;

    private var envId: int;  default envId = -1;

    public function Init(envPath: string, envPriority: int) {
        path = envPath;
        priority = envPriority;
    }

    public function SetStrength(newStrength: float, blendTime: float) {
        var previousId: int = envId;
        var clampedStrength: float = ClampF(newStrength, 0.0, 1.0);

        if (clampedStrength == strength) return;

        if (clampedStrength > 0.0) {
            if (!LoadDefinition()) return;

            envId = ActivateEnvironmentDefinition(definition, priority, clampedStrength, blendTime);
        }
        else {
            envId = -1;
        }

        if (previousId != -1) DeactivateEnvironment(previousId, blendTime);
        strength = clampedStrength;
    }

    private function LoadDefinition(): bool {
        if (definition) return true;

        definition = (CEnvironmentDefinition)LoadResource(path, true);
        if (definition) return true;

        LogLightRewrite("Failed to load " + path);
        return false;
    }
}
