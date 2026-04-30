import Phaser from 'phaser';
import { GameScene } from './GameScene.js';

export function createGame(parent) {
  return new Phaser.Game({
    type: Phaser.AUTO,
    parent,
    width: Math.min(window.innerWidth, 900),
    height: Math.min(window.innerHeight - 120, 520),
    backgroundColor: '#1a2540',
    physics: {
      default: 'arcade',
      arcade: {
        gravity: { y: 900 },
        debug: false,
      },
    },
    scene: [GameScene],
    scale: {
      mode: Phaser.Scale.RESIZE,
      autoCenter: Phaser.Scale.CENTER_BOTH,
    },
  });
}
