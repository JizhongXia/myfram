<script setup>
import GameView from './components/GameView.vue';
</script>

<template>
  <div class="app">
    <header class="bar">
      <h1>初始场景</h1>
      <p class="hint">方向键 / WASD 移动 · 路灯图请放到 <code>client/public/assets/lamp.png</code></p>
    </header>
    <GameView class="stage" />
  </div>
</template>

<style>
* {
  box-sizing: border-box;
}
html,
body {
  margin: 0;
  height: 100%;
  background: #0b1020;
  color: #e8ecff;
  font-family: system-ui, sans-serif;
}
#app {
  height: 100%;
}
.app {
  display: flex;
  flex-direction: column;
  height: 100%;
}
.bar {
  padding: 10px 14px;
  border-bottom: 1px solid #223;
}
.bar h1 {
  margin: 0 0 6px;
  font-size: 1.1rem;
}
.hint {
  margin: 0;
  font-size: 0.8rem;
  opacity: 0.85;
}
.stage {
  flex: 1;
  min-height: 0;
}
</style>
