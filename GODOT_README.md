# Efate / Afterlight — Godot edition

Play the public web build: https://mozila023.github.io/project-vice/

New Game now starts at Sunshine Wellness & Spa in Seaside, Port Vila (785C+68), after the flight introduction. Its white boundary, timber driveway screen, massage signs, shade tree and glazed salon are reconstructed from Google Maps frontage and the business website's nail salon photo. The shop is walkable and trackable in the discovery journal and maps. Dimensions and unseen parts are interpreted; see [SUNSHINE_SPA.md](SUNSHINE_SPA.md) for the verified listing, sources and limitations. Continue retains the saved position.

The public game is hosted by GitHub Pages from the `gh-pages` branch. The `main` branch holds the source. Updating source does not automatically redeploy the web build.

The game opens on a New Game / Continue / Settings menu. New Game plays a skippable three-shot flight introduction before arriving on the island. Settings persist language, graphics quality, volume, look sensitivity, relaxed mode and quest guidance. The game uses realistic Rocketbox people, an Innerscene sedan fleet, a compass and dynamic quest direction/distance markers, road routes on the map, and a redesigned HUD. See [ASSET_CREDITS.md](ASSET_CREDITS.md) for downloaded asset sources, licences, optimization and visual limitations.

An optional six-chapter TH/EN story and an independent discovery journal cover Mele, Port Vila, Port Havannah and Eton. Relaxed exploration is the default; survival mode can be enabled in the journal. Press J for the journal, L for TH/EN, E to interact/drive, F to fish, and M for the map. See [ISLAND_STORY.md](ISLAND_STORY.md) for island research sources and mission details.

The north-up minimap centres on the player, shows facing direction, nearby roads/villagers and the tracked quest route, and points to off-map goals at its edge. It zooms out when driving. Tap it or press M for the full map. It reuses the existing atlas at 10Hz, with separate desktop/mobile placement to keep touch controls clear.

Open `project.godot` with Godot 4.7 and press F6 on `scenes/island.tscn`, or F5 for the main scene.

The current Godot game focuses on peaceful exploration, fishing, cooking, village life and an optional recovery story. Custom 3D landmarks, watercraft, spa interior furniture, aircraft cabin, and smoothed vehicle meshes are authored in Blender 5.2; downloaded assets and their licences are documented in `ASSET_CREDITS.md`.

Map data: roads, land use and building density come from OpenStreetMap (© OpenStreetMap contributors, ODbL). To rebuild: `tools/download_osm_detail.ps1`, `node tools/process_geography.mjs`, then run `tools/clean_textures.gd` (only if wall textures change) and `tools/bake_world.gd` with `godot --headless --path . --script`, followed by `godot --headless --path . --import`. The game map is 1:20, so streets are generalised and one game building stands for many mapped ones.

Controls: WASD move/drive, mouse or touch look, Shift sprint, Space jump/handbrake, E interact/enter/exit/reel, F cast/cancel, Q eat, Esc pause, Tab pack, J journal, L language, M map, F5 save, F9 load. Touch controls are provided on mobile.

Saves use `user://efate_life_save.json` and include player needs, inventory, story progress, collected resources, discoveries and language. Vehicle positions reset on a new launch. Preferences use a separate `user://vice_settings.cfg`. Starting New Game leaves the previous save intact until a new save is written.

Validated in Godot 4.7.2 with the front-end, story and driving integration scripts, rendered desktop screenshots and the exported resource pack. Browser UI verification was blocked by a Computer Use approval timeout. Physical-phone performance has not been measured.
