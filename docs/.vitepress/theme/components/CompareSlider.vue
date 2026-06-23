<script setup lang="ts">
import { computed, ref, watch } from "vue";

interface Props {
  before: string;
  after: string;
  beforeLabel?: string;
  afterLabel?: string;
  beforeAlt?: string;
  afterAlt?: string;
  start?: number;
  modelValue?: number;
  aspectRatio?: number | string;
  handleOnly?: boolean;
  step?: number;
  hideLabels?: boolean;
  keyboard?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  beforeLabel: "Before",
  afterLabel: "After",
  start: 50,
  handleOnly: false,
  step: 3,
  hideLabels: false,
  keyboard: true,
});

const emit = defineEmits<{
  "update:modelValue": [value: number];
  change: [value: number];
}>();

const clamp = (n: number) => Math.min(100, Math.max(0, n));

const root = ref<HTMLElement | null>(null);
const position = ref(clamp(props.modelValue ?? props.start));
const dragging = ref(false);

watch(
  () => props.modelValue,
  v => {
    if (v != null) position.value = clamp(v);
  },
);

function setPosition(p: number) {
  const c = clamp(p);
  if (c === position.value) return;
  position.value = c;
  emit("update:modelValue", c);
  emit("change", c);
}

// Cache the rect and batch pointer moves so dragging touches layout once per frame
let rect: DOMRect | null = null;
let frame = 0;
let queuedX = 0;

function flush() {
  frame = 0;
  if (!rect || !rect.width) return;
  setPosition(((queuedX - rect.left) / rect.width) * 100);
}
function schedule(clientX: number) {
  queuedX = clientX;
  if (!frame) frame = requestAnimationFrame(flush);
}

function onPointerDown(e: PointerEvent) {
  if (e.button !== 0) return;
  if (props.handleOnly && !(e.target as HTMLElement | null)?.closest("[data-handle]")) return;
  rect = root.value!.getBoundingClientRect();
  dragging.value = true;
  // Capture the pointer so moves keep arriving even if the cursor leaves the element
  try {
    root.value!.setPointerCapture(e.pointerId);
  } catch {}
  root.value?.focus();
  schedule(e.clientX);
}
function onPointerMove(e: PointerEvent) {
  if (dragging.value) schedule(e.clientX);
}
function endDrag() {
  if (!dragging.value) return;
  dragging.value = false;
  if (frame) {
    cancelAnimationFrame(frame);
    frame = 0;
    flush();
  }
  rect = null;
}

function onKeydown(e: KeyboardEvent) {
  if (!props.keyboard) return;
  const big = e.shiftKey ? props.step * 3 : props.step;
  switch (e.key) {
    case "ArrowLeft":
      setPosition(position.value - big);
      e.preventDefault();
      break;
    case "ArrowRight":
      setPosition(position.value + big);
      e.preventDefault();
      break;
    case "Home":
      setPosition(0);
      e.preventDefault();
      break;
    case "End":
      setPosition(100);
      e.preventDefault();
      break;
  }
}

const derivedRatio = ref<string | null>(null);
const aspect = computed(() => {
  if (props.aspectRatio != null)
    return typeof props.aspectRatio === "number" ? String(props.aspectRatio) : props.aspectRatio;
  return derivedRatio.value ?? "16 / 10";
});
function onBeforeLoad(e: Event) {
  const img = e.target as HTMLImageElement;
  if (props.aspectRatio == null && img.naturalWidth && img.naturalHeight) {
    derivedRatio.value = `${img.naturalWidth} / ${img.naturalHeight}`;
  }
}
</script>

<template>
  <div
    ref="root"
    class="slider"
    :class="{ 'is-dragging': dragging }"
    role="slider"
    :aria-label="`Image comparison: ${beforeLabel} versus ${afterLabel}`"
    :aria-valuemin="0"
    :aria-valuemax="100"
    :aria-valuenow="Math.round(position)"
    tabindex="0"
    :style="{ aspectRatio: aspect, '--pos': position + '%' }"
    @pointerdown="onPointerDown"
    @pointermove="onPointerMove"
    @pointerup="endDrag"
    @pointercancel="endDrag"
    @lostpointercapture="endDrag"
    @keydown="onKeydown"
  >
    <img
      class="image"
      :src="before"
      :alt="beforeAlt ?? beforeLabel"
      draggable="false"
      @load="onBeforeLoad"
    />
    <img class="image after" :src="after" :alt="afterAlt ?? afterLabel" draggable="false" />

    <template v-if="!hideLabels">
      <span class="label label-before" aria-hidden="true">{{ beforeLabel }}</span>
      <span class="label label-after" aria-hidden="true">{{ afterLabel }}</span>
    </template>

    <div class="divider" aria-hidden="true">
      <span class="handle" data-handle>
        <svg viewBox="0 0 20 14" width="20" height="14" fill="none">
          <path
            d="M7 2 2 7l5 5M13 2l5 5-5 5"
            stroke="currentColor"
            stroke-width="1.6"
            stroke-linecap="round"
            stroke-linejoin="round"
          />
        </svg>
      </span>
    </div>
  </div>
</template>

<style scoped>
.slider {
  position: relative;
  display: block;
  width: 100%;
  overflow: hidden;
  user-select: none;
  -webkit-user-select: none;
  touch-action: pan-y;
  background: var(--cs-bg);
  cursor: ew-resize;
  outline: none;
  border-radius: inherit;
}
.slider:focus-visible {
  box-shadow: 0 0 0 3px var(--cs-glow);
}
.image {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
  pointer-events: none;
  -webkit-user-drag: none;
}
.after {
  clip-path: inset(0 0 0 var(--pos, 50%));
}
/* Set will-change only while dragging, since leaving it on permanently wastes memory */
.slider.is-dragging .after {
  will-change: clip-path;
}
.label {
  position: absolute;
  top: 14px;
  font-family: var(--cs-mono);
  font-size: var(--cs-text-xs);
  font-weight: 500;
  line-height: 1;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: rgba(255, 255, 255, 0.92);
  background: rgba(12, 12, 18, 0.74);
  padding: 6px 10px;
  border-radius: 999px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  pointer-events: none;
}
.label-before {
  left: 14px;
}
.label-after {
  right: 14px;
}
.divider {
  position: absolute;
  top: 0;
  bottom: 0;
  left: var(--pos, 50%);
  width: 1px;
  transform: translateX(-0.5px);
  background: var(--cs-divider);
  box-shadow: 0 0 2px rgba(0, 0, 0, 0.75);
  pointer-events: none;
}
.handle {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 28px;
  height: 28px;
  border-radius: 999px;
  display: grid;
  place-items: center;
  color: rgba(255, 255, 255, 0.55);
  background: rgba(16, 16, 24, 0.3);
  border: 1px solid rgba(255, 255, 255, 0.2);
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.3);
  pointer-events: auto;
  cursor: ew-resize;
}
.handle svg {
  width: 15px;
  height: auto;
}
.slider:focus-visible .handle {
  border-color: color-mix(in srgb, var(--cs-accent-pale) 20%, transparent);
}
</style>
