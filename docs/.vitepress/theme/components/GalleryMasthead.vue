<script setup lang="ts">
import { withBase } from "vitepress";
import { siGithub } from "simple-icons";

defineProps<{ helpOpen: boolean }>();
defineEmits<{ "toggle-help": [] }>();
</script>

<template>
  <header class="masthead">
    <a class="brand" :href="withBase('/')"><span class="mark" />Light Rewrite</a>
    <div class="masthead-right">
      <a
        class="github"
        href="https://github.com/webspam/LightRewrite"
        target="_blank"
        rel="noreferrer"
      >
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path :d="siGithub.path" />
        </svg>
        GitHub
      </a>
      <button
        class="help"
        type="button"
        aria-label="Keyboard shortcuts"
        :aria-pressed="helpOpen"
        @click="$emit('toggle-help')"
      >
        ?
      </button>
    </div>
  </header>
</template>

<style scoped>
.masthead {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  max-width: var(--cs-content-width);
  margin: 0 auto;
  padding: 26px 32px;
  border-bottom: 1px solid var(--cs-line);
}
.brand {
  display: flex;
  align-items: center;
  gap: 11px;
  font-family: var(--cs-display);
  font-weight: 300;
  font-size: var(--cs-text-lg);
  color: inherit;
  text-decoration: none;
  transition: color 0.2s;
}
.brand:hover {
  color: var(--cs-text);
}
.mark {
  width: 18px;
  height: 18px;
  border-radius: var(--cs-radius-sm);
  background: linear-gradient(140deg, var(--cs-accent), var(--cs-accent-bright));
  box-shadow: 0 0 16px var(--cs-glow);
  transform: rotate(45deg);
}
.masthead-right {
  display: flex;
  align-items: center;
  gap: 18px;
}
.github {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-family: var(--cs-mono);
  font-size: var(--cs-text-md);
  letter-spacing: 0.06em;
  color: var(--cs-faint);
  text-decoration: none;
  transition: color 0.2s;
}
.github svg {
  width: 18px;
  height: 18px;
  fill: currentColor;
}
.github:hover {
  color: var(--cs-text);
}
.help {
  width: 28px;
  height: 28px;
  border-radius: var(--cs-radius-md);
  border: 1px solid var(--cs-line);
  background: transparent;
  color: var(--cs-faint);
  font-family: var(--cs-mono);
  font-size: var(--cs-text-md);
  line-height: 1;
  cursor: pointer;
  transition:
    color 0.2s,
    border-color 0.2s;
}
.help:hover {
  color: var(--cs-text);
  border-color: var(--cs-accent-pale);
}
</style>
