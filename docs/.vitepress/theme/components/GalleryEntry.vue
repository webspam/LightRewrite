<script setup lang="ts">
import CompareSlider from "./CompareSlider.vue";
import { NATIVE_SIZE, type GalleryItem } from "../gallery-data";

defineProps<{
  item: GalleryItem;
  active: boolean;
  position: number;
  hideLabels: boolean;
}>();
defineEmits<{
  "update:position": [value: number];
  expand: [];
}>();
</script>

<template>
  <article class="entry" :class="{ active }">
    <div class="media-col">
      <div class="media">
        <CompareSlider
          :model-value="position"
          :before="item.before"
          :after="item.after"
          :aspect-ratio="NATIVE_SIZE.w / NATIVE_SIZE.h"
          :hide-labels
          :keyboard="false"
          @update:model-value="$emit('update:position', $event)"
        />
        <button
          class="expand"
          type="button"
          :aria-label="`Expand ${item.title} to full screen`"
          @click="$emit('expand')"
        >
          <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="1.8"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path d="M14 3h7v7" />
            <path d="M10 21H3v-7" />
          </svg>
        </button>
      </div>
    </div>
    <div class="info">
      <h2 class="heading">{{ item.title }}</h2>
    </div>
  </article>
</template>

<style scoped>
.entry {
  display: grid;
  grid-template-columns: 2.85fr 1fr;
  border-bottom: 1px solid var(--cs-line);
  align-items: stretch;
  scroll-margin-top: 24px;
}
.media-col {
  padding: 26px 28px 30px 24px;
  border-right: 1px solid var(--cs-line-faint);
}
.media {
  position: relative;
  border-radius: var(--cs-radius-lg);
  overflow: hidden;
  box-shadow: 0 30px 80px -40px rgba(0, 0, 0, 0.85);
}
.expand {
  position: absolute;
  right: 12px;
  bottom: 12px;
  z-index: 6;
  width: 40px;
  height: 40px;
  border-radius: var(--cs-radius-md);
  display: grid;
  place-items: center;
  cursor: pointer;
  color: #fff;
  border: 1px solid var(--cs-line-strong);
  background: rgba(10, 10, 16, 0.5);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  transition:
    border-color 0.2s,
    background 0.2s,
    transform 0.2s;
}
.expand:hover {
  border-color: var(--cs-accent-pale);
  background: var(--cs-accent-soft);
  transform: translateY(-1px);
}
.expand svg {
  width: 18px;
  height: 18px;
}

.info {
  position: relative;
  padding: 30px 8px 30px 28px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}
.info::before {
  content: "";
  position: absolute;
  left: 0.25rem;
  top: 40%;
  bottom: 40%;
  width: 2px;
  background: color-mix(in srgb, var(--cs-accent-pale) 30%, transparent);
  opacity: 0;
  transition: opacity 0.25s;
}
.entry.active .info::before {
  opacity: 1;
}
.heading {
  font-family: var(--cs-display);
  font-weight: 300;
  font-size: var(--cs-text-h2);
  letter-spacing: -0.02em;
  margin: 0;
  color: var(--cs-text-dim);
  text-wrap: balance;
}
@media (max-width: 860px) {
  .entry {
    grid-template-columns: 1fr;
  }
  .media-col {
    border-right: none;
    padding: 22px 24px 2px;
  }
  .info {
    padding: 2px 24px 30px;
  }
  .info::before {
    display: none;
  }
}
</style>
