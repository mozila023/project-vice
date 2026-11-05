# Asset sources and web rendering changes

## Downloaded for this overhaul

- **Microsoft Rocketbox** — realistic rigged people and walking/idle animations. [Original repository](https://github.com/microsoft/Microsoft-Rocketbox), MIT. Selected `Female_Adult_01`, `Female_Adult_08`, `Male_Adult_01`, `Male_Adult_12`, plus female/male idle-breathe and neutral-walk clips. Licence in `assets/models/people/LICENSE.txt`. Textures are resized to 1024px body / 512px head and hair; animations are matched to the shared bone names. These are fictional cast members, not scans of Efate residents.
- **Innerscene original unbranded sedan** — [source and CC0 dedication](https://www.innerscene.com/tools/library/3d-parts/sedan-car-42109739). The GLB's own copyright metadata also records CC0. Upgraded in Blender 5.2 with welded vertices, beveled roofline/body creases, auto-smoothed normals, clearcoat metallic paint, and emissive headlamps/taillights, then consolidated into material batches and four animated wheel pivots with `tools/bake_sedan.gd`. The vehicle fleet shares this realistic sedan exterior in different paint colours; it no longer depicts separate van/truck/SUV body types.
- **Vanuatu Stringband music and gameplay SFX (`scripts/island_audio.gd`, `assets/audio/music/vanuatu_stringband.wav`)** — Karplus-Strong physical-modeled acoustic nylon guitar, soprano ukulele, rosewood marimba, and Vanuatu bush-bass performing Efate coastal stringband grooves and the *Yumi, Yumi, Yumi* motif, plus clean marimba/acoustic sound effects for footsteps, fishing, cooking, eating/drinking, vehicle engine RPM, and UI feedback.
- **Blender 5.2 authored 3D models (original project assets)** — custom `.glb` models created for Project Vice:
  - `assets/models/props/spa_furniture.glb` — Sunshine Wellness & Spa fluted gold-trimmed reception counter, nail polish display racks, manicure stations with UV lamps, cushioned salon chairs, Thai massage bed with bolster/towels, and ceramic potted plants.
  - `assets/models/props/village_well.glb`, `campfire_pit.glb`, `island_shelter.glb`, `coconut.glb`, `driftwood.glb`, `rock_boulder.glb` — Efate village landmarks, cooking tripod/kettle, bamboo-and-thatch shelter, and coastal resources.
  - `assets/models/watercraft/boat_fishing.glb`, `boat_row.glb` — Pacific outrigger/motor fishing skiff and wooden rowboat with oars.
  - `assets/models/aircraft/aircraft_cabin.glb`, `airport_apron_props.glb` — contoured regional twin-prop passenger cabin, overhead bins, oval window bezels, exterior wing/turboprop nacelle, and Bauerfield apron terminal/control tower/GSE tractor.
- **Cesium Air** — [original CesiumGS sample](https://github.com/CesiumGS/cesium/tree/main/Apps/SampleData/models/CesiumAir), distributed with the Cesium repository's Apache 2.0 licence, retained in `assets/models/aircraft/LICENSE.txt`. Model materials are adjusted for the game's lighting.
- **Kenney UI Pack – Adventure** — [source](https://kenney.nl/assets/ui-pack-adventure), CC0. Downloaded from Kenney's OpenGameArt distribution after the direct server returned HTML. Selected bar frame/fill sprites; licence in `assets/ui/KENNEY-LICENSE.txt`.
- **Lucide** — [source](https://github.com/lucide-icons/lucide), ISC with MIT notice for inherited Feather icons. Twelve interface icons; strokes changed to white for in-game tinting. Full notices in `assets/ui/icons/LICENSE.txt`.

The aircraft cabin and boarding stairs are code-authored geometry, not a downloaded realistic cabin model. The arrival shot uses the same actual terrain and sky as the playable island. Sound is a small synthesized engine loop. No video is downloaded.

## Existing environment assets

The island already uses downloaded photographic ground, plaster, wood, iron and asphalt textures, a photographic sky, and baked foliage atlases. The overhaul keeps these shared assets and tones down ambient fill and saturation. It targets a more natural visual direction in Godot's Compatibility renderer. It does not implement PC-class AAA features such as ray-traced lighting or high-density scanned environments.

## Web/mobile budget

The Elluk restaurant interior and independently grounded salon planters are authored in Blender. Reference URLs and reconstruction limits are in [ELLUK_UPDATE.md](ELLUK_UPDATE.md). No reference photographs are redistributed in the game. Running uses `m_run_neutral.max.fbx` and `f_run_neutral.max.fbx` from [Microsoft Rocketbox](https://github.com/microsoft/Microsoft-Rocketbox/tree/master/Assets/Animations/all_animations_max_motextr_xy), under the existing MIT licence in `assets/models/people/LICENSE.txt`.

The Sunshine Wellness & Spa landmark uses authored code geometry and existing credited textures/foliage. Its reference sources and reconstruction limits are recorded in [SUNSHINE_SPA.md](SUNSHINE_SPA.md). No Google Maps or shop photographs are shipped as textures. `tools/check_sunshine.gd` checks the projected site, New Game start, physical entrance traversal, floor collision, navigation and batching.

- Texture reuse, shared character animation clips, vehicle material batching, streamed tree collision and distance culling.
- Auto, low, balanced and high quality settings; auto remains the default.
- Excludes the unused 23MB Kenney download catalogue from exports.
- New menu, opening, HUD, compass, road guidance and settings use engine-native scenes and small assets.

Validation scripts: `tools/check_frontend.gd`, `tools/check_story.gd`, `tools/check_driving.gd`, `tools/check_boarding.gd`, `tools/check_minimap.gd`. Native-render screenshots can be reproduced with `tools/shot_front.gd`, `tools/shot.gd` and `tools/shot_boarding.gd`. Native FPS does not establish performance on physical phones.

### Boarding alignment

The aircraft retains its source metre units (21.40m fuselage bounding length, 25.74m wingspan). Its display heading is applied before centring it and placing the wheels on the apron. `boarding_sequence.gd` samples the lower aft-door UV from the actual mesh; that one anchor determines the stairs, landing, passenger path and dolly camera. Six open metal treads rise 17.63cm each, with an 82cm clear tread width. The passenger faces the doorway, reaches the landing, then settles before the cut to the separate cabin scene. Eight fixed-time rendered captures check the full approach and climb rather than one representative frame.
