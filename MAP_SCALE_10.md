# Efate 1:10, coastal detail and place coverage

This update doubles geographic horizontal distances compared with the previous 1:20 map. People, cars, doors, furniture and walking speeds keep their existing metre dimensions. The geographic projection uses origin 168.363 E, 17.6625 S with 10600 units per longitude degree and 11100 per latitude degree. This is an approximate local 1:10 projection, not a surveyed GIS/digital twin. Terrain elevations remain generated; no real elevation survey is claimed.

The full map texture covers 5760 game metres. The terrain/physics grid is now 483 × 483 at 12 m spacing, retaining local terrain detail across the enlarged island. Roads and settlement placements are rebuilt from the existing OSM extract. The town bake allows up to 1100 representative buildings; it does not reproduce every mapped building individually. Generic homes still share a family of models.

Town render meshes, colliders, foundation metadata and night-light references are precomputed in `assets/baked/settlement.scn`. The game checks the world-data hash before using it and falls back to procedural building if stale. Rebuild with `tools/bake_settlement.gd` after changing the world; increment `settlement.gd`'s cache version and regenerate when changing town geometry/material generation. This removes town mesh construction from Web/mobile startup.

## Coverage inventory, 5 November 2026

The named-place query returned 773 OSM elements. After excluding points beyond the modelled island/coast, nearby duplicates and the bar's real name (per the user's temporary-name request), **737 source-linked places** are included in `assets/geography/efate-places.json`. This is complete for that documented query and filtering rule, **not proof that every real place on Efate is mapped or currently operating**. Node positions are direct coordinates; way/relation coordinates are feature-centre points, not necessarily entrances.

The bag's Island Notes tab has an All Places directory, six rows per page, English/name and Thai category search, information and tracked destinations. The map shows featured pins and a selected destination. Nearby labels are pooled, so all 737 places do not create 737 permanent animated or labelled objects. Offshore destinations use a nearby accessible shoreline approach where available. Source coordinates remain in each record.

Thirteen newly modelled sites are represented with original Blender structures or landscape scenes:

- Bauerfield International Airport (the new model uses the separately mapped [international terminal](https://www.openstreetmap.org/way/52246281), not the aerodrome boundary centroid).
- Port Vila Central Market, Vanuatu National Museum, Port Vila Central Hospital, Vanuatu Post Office.
- Mele Cascades, Blue Lagoon, Eden on the River, Ekasup Cultural Village, Eton Beach, Siviri Cave, Underwater Post Office, WW II Museum.

**These thirteen models are interpreted by place type, not photo-accurate replicas.** The Mele Cascades record retains its mapped attraction-entry pin; the interpreted cliff/pool is staged behind that entrance away from road geometry. Grounding foundations/ramps are used for buildings; nature scenes use rock/soil contact instead of concrete plinths. Building entrances face the nearest mapped road where practical. Existing Sunshine, Pad Thai and Ifira remain the priority for closer reference-based detail. Seaside Inn remains fictional; Evening Nakamal remains a temporary fictional name.

## Visual changes

- Original Blender kit: manufactured edges, corrugated standing seams, gutters/downpipes, window sills/frames, lanterns, AC units, drainage grates, planters, benches and bollards.
- Photographic materials reuse the existing credited textures: neutral plaster/concrete, weathered wood, corrugated roofing and rock normals. Materials are cached and shared. Glass transparency is retained.
- Sunshine, Pad Thai and the port receive architectural detail without changing character dimensions. Added props are grounded; obstructing props have matching collision.
- Reduced shadow separation and distance haze, balanced skylight/bounce, calmer water normal layers, pale coral sand, wet shoreline material and animated fresh-water surfaces.
- The source `.blend` files are in `art/blender/coastal_*`; runtime assets and collider data are in `assets/models/coastal_detail/`.

## Saved games and navigation

Save version 2 gains `map_scale:10`. A save without that field is treated as 1:20 and its geographic position (including Luna) is converted once; inventory, story, money and clock remain. Loaded positions that overlap rebuilt plots are relocated to the nearest free ground. Saved discoveries and tracked OSM IDs are validated against the inventory. Luna's walking search now accounts for the enlarged harbour route and chooses an open public approach rather than cutting through the water or a porch foundation. A full day still takes one real hour.

## Reproduction and sources

1. Existing road/building data: `tools/download_osm_detail.ps1`, `node tools/process_geography.mjs`.
2. Named-place survey: `tools/download_island_survey.ps1`, then `node tools/build_island_survey.mjs`. The generator also reads the separately mapped terminal in the detailed extract.
3. Godot headless: `--script res://tools/bake_world.gd`, then `--script res://tools/bake_settlement.gd`.
4. Blender: `--background --python tools/blender_coastal_upgrade.py`.
5. Import assets, run integration checks, export Web and use the original-filename publisher.

Map data: [OpenStreetMap contributors](https://www.openstreetmap.org/copyright), ODbL 1.0. Every directory entry carries its specific OSM element URL. The survey query and date are recorded above and in the download script. Data can have omissions, incorrect labels or outdated businesses; the inventory does not promote stored opening hours/prices as verified current facts.

Tourism background cross-check: Vanuatu Tourism Office [Efate](https://www.vanuatu.travel/en/about-vanuatu/provinces/shefa/efate), [Mele Cascades and Blue Lagoon](https://www.vanuatu.travel/en/about-vanuatu/provinces/shefa/efate/six-days-of-fabulous-family-moments-in-efate). These sources establish destination context, not the interpreted building dimensions.

Validation: `tools/check_coastal_upgrade.gd` checks geographic projection, scale, actor size, save migration, inventory search, tracking persistence, real capsule traversal at featured entrances and residents' physical movement. `tools/check_luna_tour.gd` retains full escort/meal/hotel checks; `tools/check_island_expansion.gd` checks schedules and repeat-proof rewards. `tools/shot_coastal_upgrade.gd` renders actual game views and the directory UI. Mobile/browser performance must be measured separately; desktop frame rates are not phone benchmarks.
