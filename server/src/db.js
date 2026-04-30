import Database from 'better-sqlite3';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export function openDatabase(dbPath) {
  const dir = path.dirname(dbPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  const db = new Database(dbPath);
  db.exec(`
    CREATE TABLE IF NOT EXISTS game_state (
      key TEXT PRIMARY KEY,
      value_json TEXT NOT NULL,
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
  `);
  return db;
}

export function getPlayerState(db) {
  const row = db.prepare(`SELECT value_json FROM game_state WHERE key = 'player'`).get();
  if (!row) return { x: 400, y: 320 };
  try {
    return JSON.parse(row.value_json);
  } catch {
    return { x: 400, y: 320 };
  }
}

export function setPlayerState(db, { x, y }) {
  const value = JSON.stringify({ x: Number(x), y: Number(y) });
  db.prepare(
    `INSERT INTO game_state (key, value_json, updated_at)
     VALUES ('player', ?, datetime('now'))
     ON CONFLICT(key) DO UPDATE SET value_json = excluded.value_json, updated_at = excluded.updated_at`
  ).run(value);
}
