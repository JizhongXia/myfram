import test from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function wait(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function httpJson(method, url, body) {
  return fetch(url, {
    method,
    headers: body ? { 'Content-Type': 'application/json' } : undefined,
    body: body ? JSON.stringify(body) : undefined,
  }).then(async (r) => {
    const text = await r.text();
    let data;
    try {
      data = text ? JSON.parse(text) : null;
    } catch {
      data = text;
    }
    return { status: r.status, data };
  });
}

test('API health and player state', async (t) => {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'game-api-'));
  const dbFile = path.join(tmp, 'test.db');
  const env = { ...process.env, PORT: '0', DATABASE_PATH: dbFile };

  const proc = spawn('node', [path.join(__dirname, '..', 'src', 'index.js')], {
    env: { ...env, PORT: '3099' },
    stdio: ['ignore', 'pipe', 'pipe'],
  });

  let port = 3099;
  let ready = false;
  const onData = (chunk) => {
    const s = String(chunk);
    if (s.includes('listening')) ready = true;
  };
  proc.stdout.on('data', onData);
  proc.stderr.on('data', onData);

  for (let i = 0; i < 50; i++) {
    if (ready) break;
    await wait(50);
  }

  const base = `http://127.0.0.1:${port}`;

  try {
    const health = await httpJson('GET', `${base}/api/health`);
    assert.equal(health.status, 200);
    assert.equal(health.data.ok, true);

    const initial = await httpJson('GET', `${base}/api/state/player`);
    assert.equal(initial.status, 200);
    assert.equal(typeof initial.data.x, 'number');
    assert.equal(typeof initial.data.y, 'number');

    const put = await httpJson('PUT', `${base}/api/state/player`, { x: 123, y: 456 });
    assert.equal(put.status, 200);
    assert.deepEqual(put.data, { x: 123, y: 456 });

    const again = await httpJson('GET', `${base}/api/state/player`);
    assert.deepEqual(again.data, { x: 123, y: 456 });
  } finally {
    proc.kill('SIGTERM');
    await wait(100);
  }
});
