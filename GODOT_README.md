# Efate / Afterlight — Godot edition

Play the public web build: https://mozila023.github.io/project-vice/

The public game is hosted by GitHub Pages from the `gh-pages` branch. The `main` branch holds the source. Updating source does not automatically redeploy the web build.

The current game includes an optional six-chapter TH/EN story, twelve villager outfit palettes with fabric patterns, driveable cars, and an independent discovery journal for Mele, Port Vila, Port Havannah and Eton. Relaxed exploration is the default; survival mode can be enabled in the journal. Press J for the journal, L for TH/EN, E to interact/drive, F to fish, and M for the map. See [ISLAND_STORY.md](ISLAND_STORY.md) for research sources, creative boundaries, controls and validation.

Open `project.godot` with Godot 4.7 and press F6 on `scenes/island.tscn`, or F5 for the main scene.

The previous Unity project is retained in `app/`. This Godot edition reconstructs its island survival loop with procedural assets: terrain, animated ocean shader, palms, settlement details, supplies, infected and a radio objective. No downloaded assets or additional asset licenses are required.

Map data: roads, land use and building density come from OpenStreetMap (© OpenStreetMap contributors, ODbL). To rebuild: `tools/download_osm_detail.ps1`, `node tools/process_geography.mjs`, then run `tools/clean_textures.gd` (only if wall textures change) and `tools/bake_world.gd` with `godot --headless --path . --script`, followed by `godot --headless --path . --import`. The game map is 1:20, so streets are generalised and one game building stands for many mapped ones.

Controls: WASD move, mouse look, Shift sprint, C slow movement, Space jump, left mouse fire, right mouse aim, R reload, E supplies, Esc pause, Tab pack, M navigation coordinates, F5 save, F9 load.

Saves use `user://efate_save.json` and restore player position, health, stamina, food, ammunition and objective status. Enemy and supply world state currently resets on a new launch. The map panel currently provides coordinates rather than a rendered island map. Models are procedural placeholders; animation, interiors and audio from the Unity version have not been ported.

Verified in Godot 4.7.2: scene launches, character grounded, forward movement through runtime input, firing consumes ammunition, reload transfers ammunition, supply pickup restores resources, save/load restores player values. Fixed a typed-array error when bullets hit terrain, hidden road geometry, and clipped HUD at the initial viewport size.
