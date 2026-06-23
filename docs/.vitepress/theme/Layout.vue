<script setup lang="ts">
import DefaultTheme from "vitepress/theme";
import { useData } from "vitepress";
import Gallery from "./Gallery.vue";

const { Layout: DefaultLayout } = DefaultTheme;
const { frontmatter } = useData();
</script>

<template>
  <Gallery v-if="frontmatter.layout === 'gallery'" />
  <DefaultLayout v-else />
</template>
