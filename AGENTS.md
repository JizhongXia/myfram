# AGENTS.md

## Project Overview

MyFram is a farm simulation game built with Godot 4.x (GDScript). See `README.md` for architecture details including the 60×60 tile map system, terrain types, and API reference.

## Cursor Cloud specific instructions

### Engine

- **Godot 4.6.2** is pre-installed at `~/.local/bin/godot`.

### Running the game

- **Headless (CI/testing):** `godot --headless --quit` from the project root. Runs one frame and exits. Good for verifying scripts load and map data initializes correctly.
- **GUI mode:** `godot` from the project root. Opens the game window with the main scene (`scenes/map/MapManager.tscn`).
- **Editor:** `godot -e` opens the Godot editor.

### Project structure

- `project.godot` — engine config, main scene is `res://scenes/map/MapManager.tscn`.
- `scenes/map/` — scene files and scripts for the map system.
- `scripts/` — shared data scripts (e.g. `map_data.gd`).
- `assets/` — placeholder for TileSet resources and art.
- `.godot/` — auto-generated import cache (gitignored).

### Key caveats

- The `TileMapLayer` node has no TileSet assigned yet. The game falls back to `ColorRect`-based rendering automatically.
- When editing `.tscn` files by hand, be careful with Godot's UID references — they must be unique.
- `godot --headless --import` is useful to re-import the project after adding new assets.
- No external dependencies or package managers are used — Godot is self-contained.
