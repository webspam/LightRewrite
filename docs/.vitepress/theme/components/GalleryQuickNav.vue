<script setup lang="ts">
import type { GalleryItem } from "../gallery-data";

defineProps<{
  items: GalleryItem[];
  active: number;
}>();
defineEmits<{ jump: [index: number] }>();

/** The fixed jump bar can't catch a vertical wheel, so steer it into horizontal travel. */
function onTrackWheel(e: WheelEvent) {
  const el = e.currentTarget as HTMLElement;
  if (el.scrollWidth <= el.clientWidth) return;
  const amount = (e.deltaY + e.deltaX) * (e.deltaMode === 1 ? 16 : 1);
  if (!amount) return;
  el.scrollLeft += amount;
  e.preventDefault();
}
</script>

<template>
  <!-- Reserves the space the fixed bar covers, so the last entry isn't hidden behind it. -->
  <div class="spacer" aria-hidden="true" />
  <nav class="quicknav" aria-label="Jump to comparison">
    <div class="quicknav-inner">
      <span class="quicknav-label">Jump to</span>
      <div class="quicknav-track" @wheel="onTrackWheel">
        <button
          v-for="(item, i) in items"
          :key="item.id"
          class="thumb"
          :class="{ active: active === i }"
          type="button"
          :aria-label="`Go to ${item.title}`"
          @click="$emit('jump', i)"
        >
          <img :src="item.after" alt="" loading="lazy" />
          <span class="thumb-num">{{ String(i + 1).padStart(2, "0") }}</span>
        </button>
      </div>
    </div>
  </nav>
</template>

<style scoped>
.spacer {
  height: 116px;
}
.quicknav {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 30;
  border-top: 1px solid var(--cs-line);
  background: linear-gradient(to top, rgba(8, 8, 12, 0.92), rgba(8, 8, 12, 0.7));
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
}
.quicknav-inner {
  max-width: var(--cs-content-width);
  margin: 0 auto;
  padding: 14px 24px;
  display: flex;
  align-items: center;
  gap: 16px;
}
.quicknav-label {
  font-family: var(--cs-mono);
  font-size: var(--cs-text-xs);
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--cs-faint);
  white-space: nowrap;
}
.quicknav-track {
  display: flex;
  gap: 10px;
  overflow-x: auto;
  padding-bottom: 2px;
  scrollbar-width: thin;
}
.thumb {
  flex: 0 0 auto;
  width: 104px;
  height: 64px;
  border-radius: var(--cs-radius-md);
  overflow: hidden;
  border: 1px solid var(--cs-line);
  cursor: pointer;
  position: relative;
  background: var(--cs-bg);
  transition:
    opacity 0.2s,
    border-color 0.2s,
    box-shadow 0.2s;
  opacity: 0.55;
  padding: 0;
}
.thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}
.thumb:hover {
  opacity: 0.85;
}
.thumb.active {
  opacity: 1;
  border-color: var(--cs-accent-pale);
  box-shadow: 0 0 0 2px var(--cs-accent-soft);
}
.thumb-num {
  position: absolute;
  left: 6px;
  bottom: 5px;
  font-family: var(--cs-mono);
  font-size: var(--cs-text-2xs);
  color: #fff;
  background: rgba(8, 8, 12, 0.65);
  padding: 2px 5px;
  border-radius: var(--cs-radius-sm);
}
</style>
