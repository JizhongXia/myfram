import Phaser from 'phaser';

async function fetchPlayer() {
  try {
    const r = await fetch('/api/state/player');
    if (!r.ok) return null;
    return r.json();
  } catch {
    return null;
  }
}

async function savePlayer(x, y) {
  try {
    await fetch('/api/state/player', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ x, y }),
    });
  } catch {
    /* offline ok */
  }
}

export class GameScene extends Phaser.Scene {
  constructor() {
    super('GameScene');
    this._saveTimer = 0;
  }

  preload() {
    this.load.image('lamp', '/assets/lamp.png');
  }

  create() {
    const { width, height } = this.scale;
    this.physics.world.setBounds(0, 0, width, height);

    this.platforms = this.physics.add.staticGroup();
    const groundY = height - 70;
    const plat = this.add.rectangle(width * 0.5, groundY, width * 0.85, 36, 0x3d5a45);
    this.physics.add.existing(plat, true);
    this.platforms.add(plat);

    const second = this.add.rectangle(width * 0.72, groundY - 90, 180, 22, 0x4a5a6e);
    this.physics.add.existing(second, true);
    this.platforms.add(second);

    this.lamp = this.physics.add.staticImage(width * 0.28, groundY - 120, 'lamp');
    this.lamp.setScale(4);
    this.lamp.refreshBody();

    this.core = this.add.circle(width * 0.55, groundY - 140, 18, 0x66e0ff);
    this.physics.add.existing(this.core, true);
    this.tweens.add({
      targets: this.core,
      scale: { from: 0.85, to: 1.12 },
      duration: 900,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.easeInOut',
    });

    const g = this.make.graphics({ x: 0, y: 0, add: false });
    g.fillStyle(0xffcc88, 1);
    g.fillRoundedRect(0, 0, 36, 48, 8);
    g.generateTexture('player_tex', 36, 48);
    g.destroy();

    this.player = this.physics.add.sprite(width * 0.5, groundY - 200, 'player_tex');
    this.player.body.setCollideWorldBounds(true);

    this.physics.add.collider(this.player, this.platforms);
    this.physics.add.collider(this.player, this.lamp);

    this.cursors = this.input.keyboard.createCursorKeys();
    this.keyA = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.A);
    this.keyD = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.D);
    this.keyW = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.W);
    this.keyS = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.S);

    fetchPlayer().then((pos) => {
      if (pos && typeof pos.x === 'number' && typeof pos.y === 'number') {
        this.player.setPosition(pos.x, pos.y);
      }
    });

    this.scale.on('resize', this.layout, this);
    this.layout(this.scale);
  }

  layout(gameSize) {
    const w = gameSize.width;
    const h = gameSize.height;
    if (!this.platforms || !this.player) return;
    this.physics.world.setBounds(0, 0, w, h);
    const groundY = h - 70;
    const children = this.platforms.getChildren();
    if (children[0]) {
      children[0].setPosition(w * 0.5, groundY);
      children[0].setSize(w * 0.85, 36);
      children[0].refreshBody();
    }
    if (children[1]) {
      children[1].setPosition(w * 0.72, groundY - 90);
      children[1].refreshBody();
    }
    if (this.lamp) {
      this.lamp.setPosition(w * 0.28, groundY - 120);
      this.lamp.refreshBody();
    }
    if (this.core) {
      this.core.setPosition(w * 0.55, groundY - 140);
      const body = this.core.body;
      if (body) body.updateFromGameObject();
    }
  }

  update(_time, delta) {
    const speed = 220;
    const body = this.player.body;
    body.setVelocityX(0);

    if (this.cursors.left.isDown || this.keyA.isDown) body.setVelocityX(-speed);
    else if (this.cursors.right.isDown || this.keyD.isDown) body.setVelocityX(speed);

    if ((this.cursors.up.isDown || this.keyW.isDown) && body.blocked.down) {
      body.setVelocityY(-420);
    }
    if (this.keyS.isDown) {
      body.setVelocityY(Math.min(body.velocity.y + 20, 400));
    }

    this._saveTimer += delta;
    if (this._saveTimer > 600) {
      this._saveTimer = 0;
      savePlayer(this.player.x, this.player.y);
    }
  }
}
