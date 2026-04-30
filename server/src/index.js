import express from 'express';
import cors from 'cors';
import { openDatabase, getPlayerState, setPlayerState } from './db.js';

const PORT = Number(process.env.PORT || 3001);
const dbPath = process.env.DATABASE_PATH || './data/game.db';

const db = openDatabase(dbPath);
const app = express();

app.use(cors({ origin: true }));
app.use(express.json());

app.get('/api/health', (_req, res) => {
  res.json({ ok: true, service: 'api' });
});

app.get('/api/state/player', (_req, res) => {
  res.json(getPlayerState(db));
});

app.put('/api/state/player', (req, res) => {
  const { x, y } = req.body || {};
  if (typeof x !== 'number' || typeof y !== 'number' || Number.isNaN(x) || Number.isNaN(y)) {
    res.status(400).json({ error: 'x and y must be numbers' });
    return;
  }
  setPlayerState(db, { x, y });
  res.json(getPlayerState(db));
});

app.listen(PORT, () => {
  console.log(`API listening on ${PORT}`);
});
