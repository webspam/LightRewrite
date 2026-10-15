// Applies the users' brightness boost preference to dimmer lights
class CLightRewriteBrightnessBooster {
    // Brightness values at or below this will receive the full boost
    private const var MIN_BRIGHTNESS: float;  default MIN_BRIGHTNESS = 1.0;
    // Brightness values above this will not be boosted
    private const var MAX_BRIGHTNESS: float;  default MAX_BRIGHTNESS = 40.0;

    public var isActive: bool;
    private var fullBoostMultiplier: float;  default fullBoostMultiplier = 1.0;
    private var brightnessBoostMultiplier: float;

    // Call on settings read / change to update boost values
    public function SetBoostPercent(boostPercent: float) {
        var boostFactor: float = boostPercent / 100.0;
        var rampWidth: float = MAX_BRIGHTNESS - MIN_BRIGHTNESS;

        isActive = boostFactor > 0.0;
        fullBoostMultiplier = 1.0 + boostFactor;
        brightnessBoostMultiplier = boostFactor / rampWidth;
    }

    // If appropriate, apply Apply the boost to the brightness
    public function Apply(brightness: float): float {
        var rampBoost: float;

        if (brightness >= MAX_BRIGHTNESS) return brightness;
        if (brightness <= MIN_BRIGHTNESS) return brightness * fullBoostMultiplier;

        rampBoost = (MAX_BRIGHTNESS - brightness) * brightnessBoostMultiplier;
        return brightness * (1.0 + rampBoost);
    }
}
