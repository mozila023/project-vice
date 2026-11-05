# Elluk and locomotion update

The restaurant pin supplied by the user resolves to PAD THAI Restaurant @ELLUK at latitude -17.763097, longitude 168.3091479 (Google place ID ChIJ0xHrV7ZhiW4R7pNuNzX5hRc). With the project's existing geographic projection it is at (-285.41613, 558.31335). The scene excludes generated settlement buildings and vegetation from this parcel.

References:
- User pin: https://maps.app.goo.gl/JuCx9DdzMiA2VwCT9
- Place and photo reference: https://wanderlog.com/place/details/7493908
- Interior photo identifier: https://itin-dev.wanderlogstatic.com/freeImage/rTzPmXAZTRtJrzsWznhW2tX3pM3OxgEG

Observed interior details reproduced: black/cream checker floor, cream walls and straight lintels, dark bar top over white panel front, bottle shelves, chrome stools, white chairs, purple table runners, gold pictures, Thai flag and white ceiling fans. The user subsequently supplied three Google Maps screenshots (March 2025) showing the real frontage and orange elephant sign. The rebuilt front follows these: raised cream weatherboard bungalow, screened/louvre windows, central white double door, projecting shallow gable with exposed rafters, timber stairs and handrails, white landing balusters, orange canopy sign and independently grounded roadside sign. Sign lettering includes PAD THAI, RESTAURANT@ ELLUK and 7799994. The elephant outline and lettering are editable mesh geometry, not cropped screenshots.

Unseen rear elevations, exact dimensions and orientation remain interpreted; this is not a measured architectural survey. References are not shipped as game textures. The game continues to use its compressed 1:20 island geography with human scale rooms.

Blender source: `art/blender/elluk_restaurant.blend`. Rebuild with Blender background mode and `tools/blender_elluk_update.py`. Restaurant meshes are joined by material, with a separate group for the roadside sign. The imported model uses 63 structural/furniture collision boxes. Runtime stair details are batched into shared cream/timber meshes. Timber treads and railings follow the terrain-dependent rise; a continuous collision slope prevents snagging on step edges. Foundation and stair posts extend below the actual soil. Salon planters and their leaves are separated into five roots in `spa_grounded.glb`; each root and its collision are grounded independently at runtime.

Real running clips are Microsoft's MIT licensed Rocketbox male/female `run_neutral` FBX files, retargeted by the same rotation pipeline as walking. Stamina exhaustion locks sprint until Shift/touch run is released and stamina reaches 20, avoiding rapid walk/run switching. Zero Energy permits walking. Animation uses measured horizontal velocity, so a blocked character idles.

Navigation keeps a path until the target moves or the player leaves the route, uses forward lookahead, reports remaining path distance, and has arrival hysteresis. The UI uses a fixed direction card rather than a projected screen marker. Disconnected road routes fall back to explicitly labelled destination guidance. The journal and both maps include the restaurant.

Validation: `tools/check_elluk_update.gd` includes physically climbing the stairs and entering the raised dining room. `tools/check_foundations.gd` audits all 460 generated buildings, 1,826 support volumes and 240,877 terrain samples, plus collision rays across sampled lots. `tools/check_refinement.gd` and `tools/check_sunshine.gd` cover existing house/furniture physics and salon entrance traversal. Physical phone performance has not been measured.
