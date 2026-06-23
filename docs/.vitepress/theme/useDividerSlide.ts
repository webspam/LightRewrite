import { onScopeDispose, type Ref } from "vue";
import { onKeyStroke } from "@vueuse/core";

const RAMP_MS = 400;
// percent of width per second at full speed
const MAX_SPEED = 65;

const clamp = (n: number) => Math.min(100, Math.max(0, n));

const LEFT_KEYS = new Set(["arrowleft", "a"]);
const RIGHT_KEYS = new Set(["arrowright", "d"]);
const isSlideKey = (e: KeyboardEvent) => {
  const k = e.key.toLowerCase();
  return LEFT_KEYS.has(k) || RIGHT_KEYS.has(k);
};
const dirOf = (key: string) => (LEFT_KEYS.has(key) ? -1 : 1);

export function useDividerSlide(target: Ref<number>, enabled: () => boolean) {
  const held = new Set<string>();
  let raf = 0;
  let dir = 0;
  let start = 0;
  let prev = 0;

  function tick(now: number) {
    if (!start) start = now;
    const dt = prev ? (now - prev) / 1000 : 0;
    prev = now;
    const ramp = Math.min((now - start) / RAMP_MS, 1);
    target.value = clamp(target.value + dir * MAX_SPEED * ramp * ramp * dt);
    raf = requestAnimationFrame(tick);
  }

  function setDir(next: number) {
    if (next === dir) return;
    const wasIdle = dir === 0;
    dir = next;
    if (next === 0) {
      if (raf) cancelAnimationFrame(raf);
      raf = start = prev = 0;
      return;
    }
    // Restart the ramp only when starting from idle; reversing direction mid-glide keeps full speed
    if (wasIdle) start = prev = 0;
    if (!raf) raf = requestAnimationFrame(tick);
  }

  function heldDir() {
    let d = 0;
    for (const key of held) d = dirOf(key);
    return d;
  }

  function stop() {
    held.clear();
    setDir(0);
  }

  onKeyStroke(isSlideKey, e => {
    if (!enabled() || e.ctrlKey || e.altKey || e.metaKey) return;
    e.preventDefault();
    const key = e.key.toLowerCase();
    if (e.shiftKey) {
      stop();
      target.value = dirOf(key) < 0 ? 0 : 100;
      return;
    }
    held.delete(key);
    held.add(key);
    setDir(heldDir());
  });
  onKeyStroke(
    isSlideKey,
    e => {
      if (!held.delete(e.key.toLowerCase())) return;
      setDir(heldDir());
    },
    { eventName: "keyup" },
  );
  onKeyStroke(["t", "T"], e => {
    if (!enabled() || e.ctrlKey || e.altKey || e.metaKey) return;
    e.preventDefault();
    stop();
    target.value = target.value >= 50 ? 0 : 100;
  });

  onScopeDispose(stop);
  return { stop };
}
