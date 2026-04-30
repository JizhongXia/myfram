import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { XMLParser } from 'fast-xml-parser';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const CLIENT_ROOT = path.join(__dirname, '..');
const SPR_ROOT = path.join(CLIENT_ROOT, 'public', 'assets', 'sprout-lands');
const MAP_PATH = path.join(SPR_ROOT, 'data', 'map.tmx');
const OUT_PATH = path.join(CLIENT_ROOT, 'src', 'generated', 'sprout-manifest.json');

const parser = new XMLParser({
  ignoreAttributes: false,
  attributeNamePrefix: '@_',
});

function one(v) {
  if (v == null) return undefined;
  return Array.isArray(v) ? v[0] : v;
}

function toPublicUrl(absFile) {
  const rel = path.relative(path.join(CLIENT_ROOT, 'public'), absFile).split(path.sep).join('/');
  return `/${rel}`;
}

function readXml(filePath) {
  return parser.parse(fs.readFileSync(filePath, 'utf8'));
}

function resolveFrom(baseDir, rel) {
  return path.normalize(path.join(baseDir, rel));
}

function parseCsvData(inner) {
  const raw = inner?.['#text'] ?? inner;
  if (typeof raw !== 'string') return [];
  return raw
    .split(/[,\s]+/)
    .map((s) => s.trim())
    .filter(Boolean)
    .map((n) => parseInt(n, 10));
}

function parseTilesetTsx(tsxPath) {
  const dir = path.dirname(tsxPath);
  const doc = readXml(tsxPath);
  const ts = one(doc.tileset);
  if (!ts) throw new Error(`No tileset in ${tsxPath}`);
  const tw = Number(ts['@_tilewidth']);
  const th = Number(ts['@_tileheight']);
  const tilecount = ts['@_tilecount'] != null ? Number(ts['@_tilecount']) : undefined;
  const columns = ts['@_columns'] != null ? Number(ts['@_columns']) : undefined;

  const img = one(ts.image);
  if (img && img['@_source']) {
    const imgAbs = resolveFrom(dir, img['@_source']);
    return {
      kind: 'sheet',
      tilewidth: tw,
      tileheight: th,
      tilecount,
      columns,
      imageWidth: Number(img['@_width']),
      imageHeight: Number(img['@_height']),
      imageUrl: toPublicUrl(imgAbs),
    };
  }

  const tiles = [];
  const tileArr = Array.isArray(ts.tile) ? ts.tile : ts.tile ? [ts.tile] : [];
  for (const t of tileArr) {
    const id = Number(t['@_id']);
    const im = one(t.image);
    if (!im?.['@_source']) continue;
    const imgAbs = resolveFrom(dir, im['@_source']);
    tiles.push({
      localId: id,
      width: Number(im['@_width']),
      height: Number(im['@_height']),
      url: toPublicUrl(imgAbs),
    });
  }
  return {
    kind: 'tiles',
    tilewidth: tw,
    tileheight: th,
    tiles,
  };
}

function main() {
  if (!fs.existsSync(MAP_PATH)) {
    console.warn('[sprout-manifest] map.tmx missing, skip:', MAP_PATH);
    process.exit(0);
  }

  const mapDir = path.dirname(MAP_PATH);
  const mapDoc = readXml(MAP_PATH);
  const map = one(mapDoc.map);
  if (!map) throw new Error('Invalid map.tmx');
  const width = Number(map['@_width']);
  const height = Number(map['@_height']);
  const tilewidth = Number(map['@_tilewidth']);
  const tileheight = Number(map['@_tileheight']);

  const tilesetsRaw = map.tileset;
  const tilesetsArr = Array.isArray(tilesetsRaw) ? tilesetsRaw : tilesetsRaw ? [tilesetsRaw] : [];
  const tilesets = [];
  for (const ts of tilesetsArr) {
    const firstgid = Number(ts['@_firstgid']);
    const src = ts['@_source'];
    if (!src) continue;
    const tsxAbs = resolveFrom(mapDir, src);
    const parsed = parseTilesetTsx(tsxAbs);
    tilesets.push({ firstgid, ...parsed, tsxPath: path.relative(SPR_ROOT, tsxAbs) });
  }

  const layersRaw = map.layer;
  const layersArr = Array.isArray(layersRaw) ? layersRaw : layersRaw ? [layersRaw] : [];
  const layers = [];
  for (const layer of layersArr) {
    const dataEl = layer.data;
    const inner = dataEl?.['#text'] != null ? dataEl : dataEl;
    const data = parseCsvData(inner);
    if (data.length !== width * height) {
      console.warn('[sprout-manifest] layer', layer['@_name'], 'size mismatch', data.length, width * height);
    }
    layers.push({
      name: layer['@_name'],
      visible: layer['@_visible'] !== '0',
      data,
    });
  }

  const collisionLayer = layers.find((l) => l.name === 'Collision');
  const renderLayers = [
    'Ground',
    'Forest Grass',
    'Outside Decoration',
    'Hills',
    'Fence',
    'HouseFloor',
    'HouseWalls',
    'HouseFurnitureBottom',
    'HouseFurnitureTop',
  ];

  const ogRaw = map.objectgroup;
  const ogArr = Array.isArray(ogRaw) ? ogRaw : ogRaw ? [ogRaw] : [];
  const playerGroup = ogArr.find((g) => g['@_name'] === 'Player');
  let playerStart = { x: width * tilewidth * 0.5, y: height * tileheight * 0.5 };
  if (playerGroup) {
    const objs = Array.isArray(playerGroup.object)
      ? playerGroup.object
      : playerGroup.object
        ? [playerGroup.object]
        : [];
    const start = objs.find((o) => o['@_name'] === 'Start');
    if (start) {
      playerStart = { x: Number(start['@_x']), y: Number(start['@_y']) };
    }
  }

  const mapObjects = [];
  for (const g of ogArr) {
    const name = g['@_name'];
    if (name !== 'Trees' && name !== 'Decoration' && name !== 'Objects') continue;
    const objs = Array.isArray(g.object) ? g.object : g.object ? [g.object] : [];
    for (const o of objs) {
      if (o['@_gid'] == null) continue;
      const ox = Number(o['@_x']);
      const oy = Number(o['@_y']);
      if (ox < -tilewidth || oy < -tileheight || ox > width * tilewidth + tilewidth * 4) continue;
      mapObjects.push({
        gid: Number(o['@_gid']),
        x: ox,
        y: oy,
        width: o['@_width'] != null ? Number(o['@_width']) : undefined,
        height: o['@_height'] != null ? Number(o['@_height']) : undefined,
      });
    }
  }

  const manifest = {
    version: 1,
    credit:
      '美术：Sprout Lands（Cup Nooble，itch.io）。当前仓库内地图与贴图来自开源示例项目 magicjulio/sproutland（README 已署名为 Cup Nooble）。若用于商业项目，请改为使用你在 itch 购买的资源包并遵守其许可与署名要求。',
    mapWidth: width,
    mapHeight: height,
    tileWidth: tilewidth,
    tileHeight: tileheight,
    pixelWidth: width * tilewidth,
    pixelHeight: height * tileheight,
    tilesets,
    layers: layers.filter((l) => renderLayers.includes(l.name)),
    collision: collisionLayer?.data ?? [],
    playerStart,
    mapObjects,
  };

  fs.mkdirSync(path.dirname(OUT_PATH), { recursive: true });
  fs.writeFileSync(OUT_PATH, JSON.stringify(manifest));
  console.log('[sprout-manifest] wrote', path.relative(CLIENT_ROOT, OUT_PATH));
}

main();
