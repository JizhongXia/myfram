import Phaser from 'phaser';
import manifest from '../generated/sprout-manifest.json';

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

const FLIP_MASK = ~(0x80000000 | 0x40000000 | 0x20000000) >>> 0;

function stripGid(gid) {
  if (!gid) return 0;
  return gid & FLIP_MASK;
}

function findTilesetForGid(gid, tilesets) {
  const sorted = [...tilesets].sort((a, b) => b.firstgid - a.firstgid);
  return sorted.find((ts) => gid >= ts.firstgid);
}

export class GameScene extends Phaser.Scene {
  constructor() {
    super('GameScene');
    this._saveTimer = 0;
    this._facing = 'down';
  }

  preload() {
    const m = manifest;

    for (const ts of m.tilesets) {
      if (ts.kind === 'sheet') {
        const key = `ts_${ts.firstgid}`;
        this.load.spritesheet(key, ts.imageUrl, {
          frameWidth: ts.tilewidth,
          frameHeight: ts.tileheight,
        });
      } else if (ts.kind === 'tiles' && ts.tiles) {
        for (const t of ts.tiles) {
          this.load.image(`obj_${ts.firstgid}_${t.localId}`, t.url);
        }
      }
    }

    const walkDirs = [
      ['down', 4],
      ['left', 4],
      ['right', 4],
      ['up', 2],
    ];
    for (const [dir, count] of walkDirs) {
      for (let i = 0; i < count; i++) {
        this.load.image(`p_${dir}_${i}`, `/assets/sprout-lands/graphics/character/${dir}/${i}.png`);
      }
    }

    this.load.image('core_sprite', '/assets/sprout-lands/graphics/fruit/apple.png');
  }

  create() {
    const m = manifest;
    const tw = m.tileWidth;
    const th = m.tileHeight;

    this.physics.world.setBounds(0, 0, m.pixelWidth, m.pixelHeight);

    let depth = 0;
    for (const layer of m.layers) {
      if (!layer.visible) continue;
      const cont = this.add.container(0, 0);
      cont.setDepth(depth++);
      for (let ty = 0; ty < m.mapHeight; ty++) {
        for (let tx = 0; tx < m.mapWidth; tx++) {
          const raw = layer.data[ty * m.mapWidth + tx];
          const gid = stripGid(raw);
          if (!gid) continue;
          const ts = findTilesetForGid(gid, m.tilesets);
          if (!ts) continue;
          const local = gid - ts.firstgid;
          const cx = tx * tw + tw / 2;
          const cy = ty * th + th / 2;
          if (ts.kind === 'sheet') {
            const spr = this.add.image(cx, cy, `ts_${ts.firstgid}`, local);
            spr.setOrigin(0.5, 0.5);
            cont.add(spr);
          } else if (ts.kind === 'tiles') {
            const spr = this.add.image(cx, cy, `obj_${ts.firstgid}_${local}`);
            spr.setOrigin(0.5, 0.5);
            cont.add(spr);
          }
        }
      }
    }

    this.platforms = this.physics.add.staticGroup();
    for (let ty = 0; ty < m.mapHeight; ty++) {
      for (let tx = 0; tx < m.mapWidth; tx++) {
        const v = m.collision[ty * m.mapWidth + tx];
        if (!v) continue;
        const rect = this.add.rectangle(tx * tw + tw / 2, ty * th + th / 2, tw, th, 0x000000, 0);
        this.physics.add.existing(rect, true);
        this.platforms.add(rect);
      }
    }

    const objDepth = depth + 5;
    for (const o of m.mapObjects) {
      const gid = stripGid(o.gid);
      const ts = findTilesetForGid(gid, m.tilesets);
      if (!ts || ts.kind !== 'tiles') continue;
      const local = gid - ts.firstgid;
      const tileDef = ts.tiles.find((t) => t.localId === local);
      const w = o.width ?? tileDef?.width ?? tw;
      const h = o.height ?? tileDef?.height ?? th;
      const cx = o.x + w / 2;
      const cy = o.y - h / 2;
      const spr = this.add.image(cx, cy, `obj_${ts.firstgid}_${local}`);
      spr.setDisplaySize(w, h);
      spr.setDepth(objDepth);
    }

    const coreX = m.playerStart.x + 180;
    const coreY = m.playerStart.y - 40;
    this.core = this.add.image(coreX, coreY, 'core_sprite');
    this.core.setDepth(objDepth + 2);
    this.tweens.add({
      targets: this.core,
      scale: { from: 0.9, to: 1.15 },
      duration: 900,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.easeInOut',
    });

    this.anims.create({
      key: 'walk_down',
      frames: [0, 1, 2, 3].map((i) => ({ key: `p_down_${i}` })),
      frameRate: 8,
      repeat: -1,
    });
    this.anims.create({
      key: 'walk_left',
      frames: [0, 1, 2, 3].map((i) => ({ key: `p_left_${i}` })),
      frameRate: 8,
      repeat: -1,
    });
    this.anims.create({
      key: 'walk_right',
      frames: [0, 1, 2, 3].map((i) => ({ key: `p_right_${i}` })),
      frameRate: 8,
      repeat: -1,
    });
    this.anims.create({
      key: 'walk_up',
      frames: [0, 1].map((i) => ({ key: `p_up_${i}` })),
      frameRate: 6,
      repeat: -1,
    });

    this.player = this.physics.add.sprite(m.playerStart.x, m.playerStart.y, 'p_down_0');
    this.player.setDepth(objDepth + 10);
    this.player.body.setSize(28, 20);
    this.player.body.setOffset(
      (this.player.width - 28) / 2,
      this.player.height - 24,
    );
    this.player.body.setCollideWorldBounds(true);

    this.physics.add.collider(this.player, this.platforms);

    this.cameras.main.setBounds(0, 0, m.pixelWidth, m.pixelHeight);
    this.cameras.main.startFollow(this.player, true, 0.12, 0.12);
    this.cameras.main.setZoom(1);

    this.cursors = this.input.keyboard.createCursorKeys();
    this.keyA = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.A);
    this.keyD = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.D);
    this.keyW = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.W);
    this.keyS = this.input.keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.S);

    fetchPlayer().then((pos) => {
      if (pos && typeof pos.x === 'number' && typeof pos.y === 'number') {
        this.player.setPosition(
          Phaser.Math.Clamp(pos.x, 0, m.pixelWidth),
          Phaser.Math.Clamp(pos.y, 0, m.pixelHeight),
        );
      }
    });
  }

  update(_time, delta) {
    const speed = 200;
    const body = this.player.body;
    body.setVelocity(0, 0);

    let vx = 0;
    let vy = 0;
    if (this.cursors.left.isDown || this.keyA.isDown) vx -= speed;
    if (this.cursors.right.isDown || this.keyD.isDown) vx += speed;
    if (this.cursors.up.isDown || this.keyW.isDown) vy -= speed;
    if (this.cursors.down.isDown || this.keyS.isDown) vy += speed;

    if (vx !== 0 && vy !== 0) {
      vx *= 0.707;
      vy *= 0.707;
    }
    body.setVelocity(vx, vy);

    if (vy < 0) {
      this._facing = 'up';
      this.player.play('walk_up', true);
    } else if (vy > 0) {
      this._facing = 'down';
      this.player.play('walk_down', true);
    } else if (vx < 0) {
      this._facing = 'left';
      this.player.play('walk_left', true);
    } else if (vx > 0) {
      this._facing = 'right';
      this.player.play('walk_right', true);
    } else {
      this.player.anims.stop();
      const idleKey = `p_${this._facing}_0`;
      this.player.setTexture(idleKey);
    }

    this._saveTimer += delta;
    if (this._saveTimer > 600) {
      this._saveTimer = 0;
      savePlayer(this.player.x, this.player.y);
    }
  }
}
