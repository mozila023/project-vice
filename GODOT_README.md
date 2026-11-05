# Efate / Afterlight — Godot edition

Latest local model/physics update: Blender-authored houses, fitted foundations, solid rocks and props, and an animated fishing splash. See [MODEL_REFINEMENT.md](MODEL_REFINEMENT.md) for source files and verification.

Play the public web build: https://mozila023.github.io/project-vice/

New Game starts directly at Sunshine Wellness & Spa in Seaside, Port Vila (785C+68), beside Luna. She leads a walking introduction to Pad Thai for meals/ingredient sales and Seaside Inn, a fictional playable hotel for sleeping until morning. One active real hour equals one game day. See [LUNA_ONBOARDING.md](LUNA_ONBOARDING.md). Its white boundary, timber driveway screen, massage signs, shade tree and glazed salon are reconstructed from Google Maps frontage and the business website's nail salon photo. The shop is walkable and trackable in the discovery journal and maps. Dimensions and unseen parts are interpreted; see [SUNSHINE_SPA.md](SUNSHINE_SPA.md) for the verified listing, sources and limitations. Continue retains the saved position.

The public game is hosted by GitHub Pages from the `gh-pages` branch. The `main` branch holds the source. Updating source does not automatically redeploy the web build.

After exporting to `build/refined-web`, run `tools/publish_web.ps1` to overwrite the original web filenames on `gh-pages`. This keeps `index.html` and `index.pck` at the existing play URL and revalidates the pack for returning players.

The game opens on a New Game / Continue / Settings menu. New Game loads Sunshine directly. Settings persist language, graphics quality, volume, look sensitivity, relaxed mode and quest guidance. The game uses realistic Rocketbox people, an Innerscene sedan fleet, a compass and dynamic quest direction/distance markers, road routes on the map, and a redesigned HUD. See [ASSET_CREDITS.md](ASSET_CREDITS.md) for downloaded asset sources, licences, optimization and visual limitations.

Luna’s TH/EN welcome tour introduces meals, ingredient sales and a hotel, alongside an independent island discovery journal. Relaxed exploration is the default; survival mode can be enabled in the journal. Press Tab for inventory, quests and island notes, E to interact/drive, F to fish, and M for the map. See [ISLAND_STORY.md](ISLAND_STORY.md) for island research sources and mission details.

The north-up minimap centres on the player, shows facing direction, nearby roads/villagers and the tracked quest route, and points to off-map goals at its edge. It zooms out when driving. Tap it or press M for the full map. It reuses the existing atlas at 10Hz, with separate desktop/mobile placement to keep touch controls clear.

Open `project.godot` with Godot 4.7 and press F6 on `scenes/island.tscn`, or F5 for the main scene.

The current Godot game focuses on peaceful exploration, fishing, cooking, village life and Luna’s welcome tour. Custom 3D landmarks, watercraft, spa interior furniture, aircraft cabin, and smoothed vehicle meshes are authored in Blender 5.2, paired with Vanuatu Stringband acoustic music (`assets/audio/music/vanuatu_stringband.wav`) and musical gameplay SFX (`scripts/island_audio.gd`). Downloaded assets and their licences are documented in `ASSET_CREDITS.md`.

Map data: roads, land use and building density come from OpenStreetMap (© OpenStreetMap contributors, ODbL). To rebuild: `tools/download_osm_detail.ps1`, `node tools/process_geography.mjs`, then run `tools/clean_textures.gd` (only if wall textures change) and `tools/bake_world.gd` with `godot --headless --path . --script`, followed by `godot --headless --path . --import`. The game map is 1:20, so streets are generalised and one game building stands for many mapped ones.

Controls: WASD move/drive, mouse or touch look, Shift sprint, Space jump/handbrake, E interact/enter/exit/reel, F cast/cancel, Q eat, Esc pause, Tab bag/menu, M map, F5 save, F9 load. Inventory, quests, island notes and map share compact tabs inside the bag. Tab closes any of these tabs. Language is chosen before entering the game; gameplay has no TH/EN or quest button/card. Touch controls include a bag button.

Shift now plays a distinct running clip. After Stamina exhaustion, release Shift (or toggle touch RUN off) and recover at least 20 Stamina to run again. Energy at zero still permits walking. PAD THAI @ELLUK is available under Tab → Island Notes → TRACK. Its location follows the supplied Maps pin; the interior is photo referenced and unseen exterior details remain interpreted. See [ELLUK_UPDATE.md](ELLUK_UPDATE.md).

Saves use `user://efate_life_save.json` and include player needs, inventory, story progress, collected resources, discoveries and language. Vehicle positions reset on a new launch. Preferences use a separate `user://vice_settings.cfg`. Starting New Game leaves the previous save intact until a new save is written.

Validated in Godot 4.7.2 with the front-end, story and driving integration scripts, rendered desktop screenshots and the exported resource pack. The published web build is also checked in Chrome. Physical-phone performance has not been measured.
