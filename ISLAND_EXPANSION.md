# Island neighbours and evening gathering

The original island, Sunshine/Luna start, restaurant and inn remain in place. The new main menu uses a Blender-rendered view of the actual terrain grid (relief enhanced for the aerial illustration), with the language choice kept in Settings. No second real-time island is loaded behind the menu.

## Places

- Ifira Port Development Services: supplied Maps pin **-17.7561814, 168.3040646**, game coordinates **(-312.35762, 519.93177)**. Blender model includes a public quay, warehouse, office, containers, static reach stacker and boat hoist. The photographed lift/boat is a reference; unseen layout and dimensions are interpreted for gameplay, not a surveyed reconstruction. Office gameplay hours: 07:00–18:00.
- **Evening Nakamal**: temporary fictional game name requested by the user. Supplied bar pin **-17.7758292, 168.292499**, game coordinates **(-373.6553, 628.97706)**. Three service windows, covered benches, tables, shutters and warm evening lamps. Gameplay hours **16:00–23:00**, not a guarantee of real business hours. No real bar name is displayed in gameplay.
- Each landmark has a solid concrete foundation extending below its terrain samples, matching physical proxies and a traversable ramp/landing. Existing building and foliage generation reserves both parcels.

Editable Blender files: `art/blender/ifira_port.blend`, `evening_nakamal.blend`, `efate_aerial.blend`. Runtime GLBs and matching collider data are under `assets/models/island_expansion/`. Regeneration: run Godot headless with `--script res://tools/export_aerial_terrain.gd`, then run `tools/blender_island_expansion.py` in Blender. The cached terrain input is generated from `world.dat` and is not source data for the game.

## Island stories and residents

After Luna's optional welcome tour, the bag journal offers four stories: inspect three cargo lists and report to the port office; greet residents in Mele, Eton and Port Havannah; greet the evening host and listen to the community story; bring two fresh fish to Pad Thai's community meal. Rewards are saved and issued once. The evening story requires no drinking.

Thirty named residents have home regions in ten island areas and daily schedules. A twelve-avatar pool streams nearby awake residents, preserving the prior animated-character budget. Ordinary neighbours are absent at night; a small watch remains and Pango neighbours appear in the evening. Unloaded/sleeping avatars have no collision, interaction or minimap dots. Luna is separate from the pool. One real hour still equals one game day.

## References and credits

- [Supplied port location](https://maps.app.goo.gl/wdVUxhf9djib9yhE9), [supplied bar location](https://maps.app.goo.gl/2hfurfYTYj6hVtHK6).
- Vanuatu Project Management Unit: [Lapetasi wharf project](https://vpmu.gov.vu/index.php/projects/lapitasi), [IPDS reach stackers](https://vpmu.gov.vu/index.php/news/111-new-reach-stackers-to-ease-container-handling).
- Vanuatu Tourism Office: [Bislama](https://www.vanuatu.travel/en/about-vanuatu/bislama), [visitor etiquette](https://www.vanuatu.travel/en/things-to-know/travel-tips/etiquette), [nakamal background](https://www.vanuatu.travel/en/plan/planning-tools/guides/how-to-drink-kava).
- Original Blender architecture and illustration created for this game. Aerial terrain/coastline reuses the existing baked island and map texture; existing OpenStreetMap/asset credits remain applicable. Service boat reuses the already-credited `boat_fishing.glb`; no Maps photograph is distributed as a runtime texture. Rocketbox resident models retain their existing MIT credit.

Checks: `tools/check_island_expansion.gd` covers population regions and night reduction, service hours/shutters, story rewards and persistence, bag pagination, and physical traversal of both ramps. `tools/check_luna_tour.gd` retains real escort and existing service checks. `tools/shot_expansion.gd` captures actual rendered menu, landmarks and journal. Web delivery overwrites the original `index.*` on `gh-pages` using `tools/publish_web.ps1`.
