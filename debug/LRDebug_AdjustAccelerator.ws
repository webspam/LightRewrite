/**
 * Tracks scroll-wheel acceleration state for the LRDebug attribute editor.
 *
 * Acceleration activates after a tight burst of events (>=2 within 75 ms each)
 * and ramps the step multiplier up to 8x. A direction reversal cuts the streak
 * in half immediately. A pause longer than 500 ms resets everything.
 */
class LRDebug_AdjustAccelerator {
    private var lastTime : float;
    private var streak : int;
    private var fastStreak : int;
    private var accelerating : bool;
    private var lastSign : int;
    private var cutPending : bool;

    public function Reset() {
        streak = 0;
        fastStreak = 0;
        accelerating = false;
        cutPending = false;
    }

    /**
     * Call once per adjustment event with the direction sign (+1 or -1).
     * Returns the multiplier to apply to the base step (1.0 when not accelerating).
     */
    public function GetMultiplier(sign : int) : float {
        var now : float = theGame.GetEngineTimeAsSeconds();
        var dt : float = now - lastTime;

        // Hard reset after a longer pause to support "finger reposition" on scroll wheels.
        if (dt > 0.5) {
            Reset();
        }
        else {
            // A small pause after a direction cut should drop accel entirely.
            if (cutPending && dt > 0.075) {
                Reset();
            }

            // Acceleration only starts after a tight burst (<=75 ms between events).
            if (!accelerating) {
                if (dt <= 0.075) fastStreak += 1;
                else fastStreak = 0;

                if (fastStreak >= 2) {
                    accelerating = true;
                    streak = 0;
                }
            }
            else {
                // One event opposite to the current direction cuts accel in half.
                if (lastSign != 0 && sign != 0 && sign != lastSign) {
                    streak = streak / 2;
                    cutPending = true;
                }
                else {
                    cutPending = false;
                }

                // Keep acceleration sticky; gently decelerate if events slow down.
                if (dt <= 0.075) {
                    streak += 1;
                }
                else {
                    streak = Max(0, streak - 1);
                }
            }
        }

        lastTime = now;
        lastSign = sign;

        if (!accelerating) return 1.0;

        // Ramp quickly but cap to avoid wild jumps.
        return ClampF(1.0 + (streak * 0.5), 1.0, 8.0);
    }
}
