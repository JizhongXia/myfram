<script setup>
import GameView from './components/GameView.vue';
import manifest from './generated/sprout-manifest.json';

const credit = manifest.credit;
</script>

<template>
  <div class="app">
    <header class="bar">
      <h1>初始场景</h1>
      <p class="hint">
        Sprout Lands 风格牧场地图（WASD / 方向键移动）。美术来源见页脚说明；商业发行请使用你在 itch 下载的包并保留署名。
      </p>
    </header>
    <GameView class="stage" />
    <footer class="foot">
      <small>{{ credit }}</small>
    </footer>
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
.foot {
  padding: 6px 14px 10px;
  font-size: 0.7rem;
  opacity: 0.75;
  border-top: 1px solid #223;
}
.foot small {
  line-height: 1.35;
}
</style>
