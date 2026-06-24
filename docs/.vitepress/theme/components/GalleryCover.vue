<script setup lang="ts">
defineProps<{
  kicker: string;
  title: string;
  intro: string;
}>();
</script>

<template>
  <div class="cover">
    <span class="kicker">{{ kicker }}</span>
    <h1 class="title">{{ title }}</h1>
    <p class="intro">{{ intro }}</p>
  </div>
</template>

<style scoped>
.cover {
  max-width: var(--cs-content-width);
  margin: 0 auto;
  padding: 64px 32px 52px;
}
.kicker {
  font-family: var(--cs-mono);
  font-size: var(--cs-text-sm);
  letter-spacing: 0.2em;
  text-transform: uppercase;
  color: var(--cs-accent-pale);
  display: inline-flex;
  align-items: center;
  gap: 10px;
}
.kicker::before {
  content: "";
  width: 26px;
  height: 1px;
  background: var(--cs-accent-pale);
  opacity: 0.6;
}
.title {
  font-family: var(--cs-display);
  font-weight: 300;
  font-size: var(--cs-text-display);
  line-height: 0.99;
  margin: 18px 0 0;
  text-wrap: balance;
}
.intro {
  margin: 22px 0 0;
  max-width: 52ch;
  color: var(--cs-text-muted);
  font-size: var(--cs-text-lg);
  text-wrap: pretty;
}
</style>
