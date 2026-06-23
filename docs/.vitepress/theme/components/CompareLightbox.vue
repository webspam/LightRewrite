<script setup lang="ts">
import { computed, nextTick, ref, watch } from "vue";
import { onKeyStroke, useWindowSize } from "@vueuse/core";
import CompareSlider from "./CompareSlider.vue";
import ShortcutsOverlay from "./ShortcutsOverlay.vue";
import { NATIVE_SIZE, type GalleryItem } from "../gallery-data";
import { useDividerSlide } from "../useDividerSlide";

const props = defineProps<{
  items: GalleryItem[];
  open: boolean;
  index: number;
}>();

const emit = defineEmits<{
  "update:open": [value: boolean];
  "update:index": [value: number];
}>();

const current = computed(() => props.items[props.index]);
const pos = ref(50);
const helpOpen = ref(false);
const hideLabels = ref(false);

const hasMod = (e: KeyboardEvent) => e.ctrlKey || e.altKey || e.metaKey;

watch(
  () => props.open,
  o => {
    if (o) nextTick(() => dialog.value?.querySelector<HTMLElement>("[data-autofocus]")?.focus());
    else {
      stopSlide();
      helpOpen.value = false;
    }
  },
);

const { width: vw, height: vh } = useWindowSize();
const nat = NATIVE_SIZE;

const box = computed(() => {
  const maxW = vw.value * 0.96;
  const maxH = vh.value * 0.9;
  let w = Math.min(nat.w, maxW);
  let h = (w * nat.h) / nat.w;
  if (h > maxH) {
    h = maxH;
    w = (h * nat.w) / nat.h;
  }
  return { width: Math.round(w) + "px", height: Math.round(h) + "px" };
});

function close() {
  emit("update:open", false);
}

function step(dir: number) {
  const len = props.items.length;
  emit("update:index", (props.index + dir + len) % len);
}

function toggleHelp() {
  helpOpen.value = !helpOpen.value;
}

onKeyStroke("Escape", () => {
  if (!props.open) return;
  if (helpOpen.value) helpOpen.value = false;
  else close();
});
onKeyStroke(["/", "?"], e => {
  if (!props.open) return;
  e.preventDefault();
  toggleHelp();
});

const { stop: stopSlide } = useDividerSlide(pos, () => props.open);
function onNav(e: KeyboardEvent, dir: number) {
  if (!props.open || hasMod(e)) return;
  e.preventDefault();
  step(dir);
}
onKeyStroke(["ArrowUp", "w", "W"], e => onNav(e, -1));
onKeyStroke(["ArrowDown", "s", "S"], e => onNav(e, 1));
onKeyStroke(["r", "R"], e => {
  if (!props.open || hasMod(e)) return;
  e.preventDefault();
  pos.value = 50;
});
onKeyStroke(["h", "H"], e => {
  if (!props.open || hasMod(e)) return;
  e.preventDefault();
  hideLabels.value = !hideLabels.value;
});

const shortcuts = [
  { keys: ["←", "→"], label: "Sweep the divider (or A / D)" },
  { keys: ["Shift", "←", "→"], label: "Snap the divider to a side" },
  { keys: ["T"], label: "Toggle the divider side" },
  { keys: ["↑", "↓"], label: "Previous / next image (or W / S)" },
  { keys: ["R"], label: "Recentre the divider" },
  { keys: ["H"], label: "Hide before / after labels" },
  { keys: ["Esc"], label: "Close viewer" },
  { keys: ["/", "?"], label: "Toggle this help" },
];

const dialog = ref<HTMLElement | null>(null);
function onKeydown(e: KeyboardEvent) {
  if (e.key !== "Tab" || !dialog.value) return;
  const f = Array.from(
    dialog.value.querySelectorAll<HTMLElement>(
      'button, [href], input, [tabindex]:not([tabindex="-1"])',
    ),
  ).filter(el => !el.hasAttribute("disabled"));
  if (!f.length) return;
  const first = f[0];
  const last = f[f.length - 1];
  if (e.shiftKey && document.activeElement === first) {
    last.focus();
    e.preventDefault();
  } else if (!e.shiftKey && document.activeElement === last) {
    first.focus();
    e.preventDefault();
  }
}
</script>

<template>
  <Teleport to="body">
    <Transition name="fade">
      <div
        v-if="open"
        ref="dialog"
        class="lightbox"
        role="dialog"
        aria-modal="true"
        :aria-label="current ? `${current.title} - before and after` : 'Comparison'"
        @keydown="onKeydown"
      >
        <div class="backdrop" @click="close" />
        <div class="stage">
          <header class="bar">
            <div class="title">
              {{ current?.title }}
              <span v-if="current?.tag" class="tag">{{ current.tag }}</span>
            </div>
            <div class="actions">
              <button
                data-autofocus
                class="btn"
                type="button"
                aria-label="Previous"
                @click="step(-1)"
              >
                <svg
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="1.7"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <path d="M18 15l-6-6-6 6" />
                </svg>
              </button>
              <button class="btn" type="button" aria-label="Next" @click="step(1)">
                <svg
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="1.7"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <path d="M6 9l6 6 6-6" />
                </svg>
              </button>
              <button
                class="btn"
                type="button"
                aria-label="Keyboard shortcuts"
                :aria-pressed="helpOpen"
                @click="toggleHelp"
              >
                <span class="glyph" aria-hidden="true">?</span>
              </button>
              <button class="btn" type="button" aria-label="Close" @click="close">
                <svg
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="1.7"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <path d="M6 6l12 12M18 6L6 18" />
                </svg>
              </button>
            </div>
          </header>

          <div class="media" :style="box">
            <CompareSlider
              v-if="current"
              v-model="pos"
              :before="current.before"
              :after="current.after"
              :aspect-ratio="nat.w / nat.h"
              :hide-labels
              :keyboard="false"
            />
          </div>

          <p class="native">Native {{ nat.w }} × {{ nat.h }}px · drag to compare</p>
        </div>

        <ShortcutsOverlay v-model:open="helpOpen" :shortcuts />
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.lightbox {
  position: fixed;
  inset: 0;
  z-index: 9000;
  display: grid;
  place-items: center;
}
.backdrop {
  position: absolute;
  inset: 0;
  background: rgba(6, 6, 10, 0.94);
}
.stage {
  position: relative;
  z-index: 2;
  display: flex;
  flex-direction: column;
  gap: 14px;
  align-items: center;
  max-width: 96vw;
}
.bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  gap: 16px;
  color: var(--cs-text);
}
.title {
  font-family: var(--cs-display);
  font-weight: 500;
  font-size: var(--cs-text-lg);
}
.tag {
  font-family: var(--cs-mono);
  font-size: var(--cs-text-xs);
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--cs-faint);
  margin-left: 12px;
}
.actions {
  display: flex;
  gap: 8px;
}
.btn {
  width: 42px;
  height: 42px;
  border-radius: var(--cs-radius-md);
  border: 1px solid var(--cs-line);
  background: rgba(255, 255, 255, 0.03);
  color: var(--cs-text);
  display: grid;
  place-items: center;
  cursor: pointer;
  transition:
    border-color 0.2s,
    background 0.2s;
}
.btn:hover {
  border-color: var(--cs-accent-pale);
  background: var(--cs-accent-soft);
}
.btn svg {
  width: 18px;
  height: 18px;
}
.glyph {
  font-family: var(--cs-mono);
  font-size: var(--cs-text-lg);
  font-weight: 600;
  line-height: 1;
}
.media {
  position: relative;
  border-radius: var(--cs-radius-lg);
  overflow: hidden;
  box-shadow: 0 50px 140px -40px rgba(0, 0, 0, 0.9);
  background: var(--cs-bg);
}
.media :deep(.slider) {
  width: 100%;
  height: 100%;
}
.native {
  font-family: var(--cs-mono);
  font-size: var(--cs-text-xs);
  letter-spacing: 0.08em;
  color: var(--cs-faint);
  margin: 0;
}
</style>
