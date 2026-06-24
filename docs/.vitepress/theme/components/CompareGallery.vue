<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from "vue";
import type { ComponentPublicInstance } from "vue";
import { onKeyStroke } from "@vueuse/core";
import CompareLightbox from "./CompareLightbox.vue";
import ShortcutsOverlay from "./ShortcutsOverlay.vue";
import GalleryMasthead from "./GalleryMasthead.vue";
import GalleryCover from "./GalleryCover.vue";
import GalleryEntry from "./GalleryEntry.vue";
import GalleryQuickNav from "./GalleryQuickNav.vue";
import type { GalleryItem } from "../gallery-data";
import { useDividerSlide } from "../useDividerSlide";

const props = withDefaults(
  defineProps<{
    items: GalleryItem[];
    title?: string;
    intro?: string;
    /** small mono label shown above the title */
    kicker?: string;
    quickNav?: boolean;
  }>(),
  {
    title: "The before, kept on the record.",
    intro:
      "An indexed catalog of every comparison. Drag each plate to audit the difference - or expand any one to fill the screen at full resolution.",
    kicker: "Restoration index",
    quickNav: true,
  },
);

const lbOpen = ref(false);
const lbIndex = ref(0);
const helpOpen = ref(false);
const hideLabels = ref(false);

const hasMod = (e: KeyboardEvent) => e.ctrlKey || e.altKey || e.metaKey;
function expand(i: number) {
  stopSlide();
  helpOpen.value = false;
  lbIndex.value = i;
  lbOpen.value = true;
}

// Skip Ctrl/Cmd+F so the browser's own find shortcut still works
onKeyStroke(["f", "F"], e => {
  if (hasMod(e)) return;
  e.preventDefault();
  if (lbOpen.value) lbOpen.value = false;
  else expand(active.value);
});
function stepImage(e: KeyboardEvent, dir: number) {
  if (lbOpen.value || hasMod(e)) return;
  e.preventDefault();
  jumpTo(Math.min(props.items.length - 1, Math.max(0, active.value + dir)));
}
onKeyStroke(["ArrowUp", "w", "W"], e => stepImage(e, -1));
onKeyStroke(["ArrowDown", "s", "S"], e => stepImage(e, 1));
onKeyStroke(["r", "R"], e => {
  if (lbOpen.value || hasMod(e)) return;
  e.preventDefault();
  activePos.value = 50;
});
onKeyStroke(["h", "H"], e => {
  if (lbOpen.value || hasMod(e)) return;
  e.preventDefault();
  hideLabels.value = !hideLabels.value;
});
onKeyStroke(["/", "?"], e => {
  if (lbOpen.value) return;
  e.preventDefault();
  helpOpen.value = !helpOpen.value;
});
onKeyStroke("Escape", () => {
  if (helpOpen.value) helpOpen.value = false;
});

const shortcuts = [
  { keys: ["F"], label: "Toggle full screen" },
  { keys: ["←", "→"], label: "Sweep the divider (or A / D)" },
  { keys: ["Shift", "←", "→"], label: "Snap the divider to a side" },
  { keys: ["T"], label: "Toggle the divider side" },
  { keys: ["↑", "↓"], label: "Previous / next image (or W / S)" },
  { keys: ["R"], label: "Recentre the divider" },
  { keys: ["H"], label: "Hide before / after labels" },
  { keys: ["/", "?"], label: "Toggle this help" },
];

const rows = ref<HTMLElement[]>([]);
const setRow = (el: Element | ComponentPublicInstance | null, i: number) => {
  const node = (el as ComponentPublicInstance | null)?.$el ?? el;
  if (node) rows.value[i] = node as HTMLElement;
};
const active = ref(0);

// Offset alternate dividers so neighbouring sliders don't start at the same position
const positions = ref(props.items.map((_, i) => 50 + (i % 2 ? -6 : 6)));
const activePos = computed({
  get: () => positions.value[active.value] ?? 50,
  set: v => (positions.value[active.value] = v),
});
const { stop: stopSlide } = useDividerSlide(activePos, () => !lbOpen.value);

function jumpTo(i: number) {
  const el = rows.value[i];
  if (!el) return;
  const r = el.getBoundingClientRect();
  const top = r.top + window.scrollY - (window.innerHeight - r.height) / 2;
  window.scrollTo({ top, behavior: "smooth" });
}

function hoverActivate(i: number) {
  if (active.value !== i) active.value = i;
}

function syncActive() {
  const rs = rows.value;
  if (!rs.length) return;
  if (window.scrollY <= 2) {
    active.value = 0;
    return;
  }
  if (window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 2) {
    active.value = rs.length - 1;
    return;
  }
  const mid = window.innerHeight / 2;
  let best = 0;
  let bestDist = Infinity;
  for (let i = 0; i < rs.length; i++) {
    const el = rs[i];
    if (!el) continue;
    const r = el.getBoundingClientRect();
    const dist = Math.abs(r.top + r.height / 2 - mid);
    if (dist < bestDist) {
      bestDist = dist;
      best = i;
    }
  }
  active.value = best;
}

let ticking = false;
function onScroll() {
  if (ticking) return;
  ticking = true;
  requestAnimationFrame(() => {
    ticking = false;
    syncActive();
  });
}

onMounted(() => {
  syncActive();
  window.addEventListener("scroll", onScroll, { passive: true });
  window.addEventListener("resize", onScroll, { passive: true });
});
onBeforeUnmount(() => {
  window.removeEventListener("scroll", onScroll);
  window.removeEventListener("resize", onScroll);
});
</script>

<template>
  <section class="gallery">
    <GalleryMasthead :help-open @toggle-help="helpOpen = !helpOpen" />

    <GalleryCover :kicker :title :intro />

    <div class="entries">
      <GalleryEntry
        v-for="(item, i) in items"
        :key="item.id"
        :ref="el => setRow(el, i)"
        :item
        :active="active === i"
        v-model:position="positions[i]"
        :hide-labels
        @mousemove="hoverActivate(i)"
        @expand="expand(i)"
      />
    </div>

    <GalleryQuickNav v-if="quickNav" :items :active @jump="jumpTo" />

    <CompareLightbox v-model:open="lbOpen" v-model:index="lbIndex" :items />

    <ShortcutsOverlay v-model:open="helpOpen" :shortcuts />
  </section>
</template>

<style scoped>
.gallery {
  color: var(--cs-text);
  font-family: var(--cs-body);
  background:
    radial-gradient(75% 55% at 50% -5%, rgba(99, 89, 190, 0.2), transparent 60%),
    radial-gradient(60% 50% at 100% 12%, rgba(99, 89, 190, 0.07), transparent 55%), var(--cs-page);
}

.entries {
  max-width: var(--cs-content-width);
  margin: 0 auto;
  padding: 0 32px;
  border-top: 1px solid var(--cs-line);
}
@media (max-width: 1340px) {
  .entries {
    padding: 0;
  }
}
</style>
