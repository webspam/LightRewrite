/**
 * Tracks scroll-wheel acceleration state for the LRDebug attribute editor.
 *
 * Acceleration activates after a tight burst of events (>=2 within 75 ms each)
 * and ramps the step multiplier up to 8x. A direction reversal cuts the streak
 * in half immediately. A pause longer than 500 ms resets everything.
 */
class LRDebug_AdjustAccelerator {
    /** The number of events required to activate acceleration */
    private const var ACCELERATE_THRESHOLD : int;      default ACCELERATE_THRESHOLD = 2;
    /** Maximum time between events to classify as a burst */
    private const var BURST_INTERVAL : float;          default BURST_INTERVAL = 0.075;
    /** Time in seconds after receiving a reverse input, before the streak is reset */
    private const var REVERSE_TIME : float;            default REVERSE_TIME = 0.150;
    /** Time in seconds until the accelerator is reset, after receiving no input */
    private const var RESET_TIME : float;              default RESET_TIME = 0.500;

    /** Maximum multiplier */
    private const var MAX_MULTIPLIER : float;          default MAX_MULTIPLIER = 8.0;
    /** Minimum multiplier */
    private const var MIN_MULTIPLIER : float;          default MIN_MULTIPLIER = 1.0;
    /** Weight factor applied to the streak value */
    private const var STREAK_WEIGHT : float;           default STREAK_WEIGHT = 0.5;
    /** Amount to decrement the streak when decelerating */
    private const var STREAK_DECREMENT : int;          default STREAK_DECREMENT = 1;
    
    /** Last time the accelerator was updated */
    private var lastTime : float;
    /** Current streak */
    private var streak : int;
    /** Fast streak */
    private var fastStreak : int;
    /** Whether the accelerator is accelerating */
    private var accelerating : bool;
    /** Last value */
    private var lastValue : float;
    /** Whether a cut is pending */
    private var cutPending : bool;

    public function Reset() {
        streak = 0;
        fastStreak = 0;
        accelerating = false;
        cutPending = false;
    }

    /**
     * Call once per adjustment event with the value to adjust.
     * Returns the multiplier to apply to the base step (1.0 when not accelerating).
     */
    public function GetMultiplier(value : float) : float {
        var now : float = theGame.GetEngineTimeAsSeconds();
        var dt : float = now - lastTime;

        // Hard reset after a longer pause to support "finger reposition" on scroll wheels.
        if (dt > RESET_TIME) {
            Reset();
        }
        else {
            // A small pause after a direction cut should drop accel entirely.
            if (cutPending && dt > REVERSE_TIME) {
                Reset();
            }

            // Acceleration only starts after a tight burst (<=75 ms between events).
            if (!accelerating) {
                if (dt <= BURST_INTERVAL) fastStreak += 1;
                else fastStreak = 0;

                if (fastStreak >= ACCELERATE_THRESHOLD) {
                    accelerating = true;
                    streak = 0;
                }
            }
            else {
                // One event opposite to the current direction cuts accel in half.
                if ((value * lastValue) < 0) {
                    streak = streak / 2;
                    cutPending = true;
                }
                else {
                    cutPending = false;
                }

                // Keep acceleration sticky; gently decelerate if events slow down.
                if (dt <= BURST_INTERVAL) {
                    streak += 1;
                }
                else {
                    streak = Max(0, streak - STREAK_DECREMENT);
                }
            }
        }

        lastTime = now;
        lastValue = value;

        if (!accelerating) return 1.0;

        // Ramp quickly but cap to avoid wild jumps.
        return ClampF(1.0 + (streak * STREAK_WEIGHT), MIN_MULTIPLIER, MAX_MULTIPLIER);
    }
}
