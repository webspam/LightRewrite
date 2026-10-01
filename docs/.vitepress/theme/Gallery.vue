<script setup lang="ts">
import { computed } from "vue";
import { useData } from "vitepress";
import CompareGallery from "./components/CompareGallery.vue";
import { NEXTGEN_GALLERY, REMASTERED_GALLERY, type GalleryItem } from "./gallery-data";

interface GalleryConfig {
  items: GalleryItem[];
  kicker: string;
  title: string;
  intro: string;
}

const GALLERIES = {
  remastered: {
    items: REMASTERED_GALLERY,
    kicker: "Witcher 3 lighting mod - Remastered",
    title: "Before and after",
    intro:
      "Comparison images using the mod with The Witcher 3 Remastered. Drag the sliders or use the full screen viewer to see the difference.",
  },
  nextgen: {
    items: NEXTGEN_GALLERY,
    kicker: "Witcher 3 lighting mod",
    title: "Before and after",
    intro:
      "Comparison images using the mod with DirectX 12, Ray Tracing, and artificial lighting disabled. Drag the sliders or use the full screen viewer to see the difference.",
  },
} satisfies Record<string, GalleryConfig>;

type GalleryKey = keyof typeof GALLERIES;

const { frontmatter } = useData();
const galleryKey = computed<GalleryKey>(() => frontmatter.value.gallery ?? "remastered");
const config = computed<GalleryConfig>(() => GALLERIES[galleryKey.value]);
</script>

<template>
  <CompareGallery
    :key="galleryKey"
    :items="config.items"
    :kicker="config.kicker"
    :title="config.title"
    :intro="config.intro"
  />
</template>
