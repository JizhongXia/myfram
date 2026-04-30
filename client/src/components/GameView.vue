<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue';
import { createGame } from '../game/createGame.js';

const host = ref(null);
let game;

onMounted(() => {
  if (!host.value) return;
  game = createGame(host.value);
});

onBeforeUnmount(() => {
  if (game) {
    game.destroy(true);
    game = undefined;
  }
});
</script>

<template>
  <div ref="host" class="host" />
</template>

<style scoped>
.host {
  width: 100%;
  height: 100%;
  touch-action: none;
}
</style>
