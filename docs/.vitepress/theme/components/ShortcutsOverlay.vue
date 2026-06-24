<script setup lang="ts">
defineProps<{
  open: boolean;
  shortcuts: { keys: string[]; label: string }[];
}>();
const emit = defineEmits<{ "update:open": [value: boolean] }>();

function close() {
  emit("update:open", false);
}
</script>

<template>
  <Transition name="fade">
    <div v-if="open" class="overlay" @click="close">
      <div class="card" @click.stop>
        <h2 class="title">Keyboard shortcuts</h2>
        <dl class="list">
          <div v-for="s in shortcuts" :key="s.label" class="row">
            <dt>
              <kbd v-for="k in s.keys" :key="k">{{ k }}</kbd>
            </dt>
            <dd>{{ s.label }}</dd>
          </div>
        </dl>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.overlay {
  position: fixed;
  inset: 0;
  z-index: 50;
  display: grid;
  place-items: center;
  padding: 24px;
  background: rgba(6, 6, 10, 0.6);
  backdrop-filter: blur(4px);
  -webkit-backdrop-filter: blur(4px);
}
.card {
  width: min(420px, 100%);
  padding: 26px 28px;
  border-radius: var(--cs-radius-lg);
  border: 1px solid rgba(255, 255, 255, 0.12);
  background: rgba(16, 16, 22, 0.92);
  box-shadow: 0 40px 120px -40px rgba(0, 0, 0, 0.9);
  color: var(--cs-text);
}
.title {
  margin: 0 0 18px;
  font-family: var(--cs-display);
  font-weight: 500;
  font-size: var(--cs-text-lg);
}
.list {
  margin: 0;
  display: grid;
  gap: 12px;
}
.row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}
.row dt {
  display: flex;
  gap: 6px;
}
.row dd {
  margin: 0;
  font-family: var(--cs-mono);
  font-size: var(--cs-text-md);
  color: var(--cs-text-dim);
}
kbd {
  font-family: var(--cs-mono);
  font-size: var(--cs-text-xs);
  line-height: 1;
  min-width: 22px;
  padding: 5px 7px;
  text-align: center;
  border-radius: var(--cs-radius-sm);
  border: 1px solid var(--cs-line-strong);
  border-bottom-width: 2px;
  background: rgba(255, 255, 255, 0.06);
  color: var(--cs-text);
}
</style>
