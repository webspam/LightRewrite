<script setup lang="ts">
import CompareGallery from "./components/CompareGallery.vue";
import { GALLERY } from "./gallery-data";
</script>

<template>
  <CompareGallery
    :items="GALLERY"
    kicker="Witcher 3 lighting mod"
    title="Before and after"
    intro="Comparison images using the mod with DirectX 12, Ray Tracing, and artificial lighting disabled. Drag the sliders or use the full screen viewer to see the difference."
  />
</template>
