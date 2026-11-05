# Efate: Coasts & Connections

An optional, fictional six-chapter story: meet Malia in Mele, supply fish, cook a shared meal, contribute driftwood to shelter repairs, visit Port Vila, and return home. The characters and storm are invented; these missions do not reconstruct an actual disaster or claim to depict a particular community's customs.

Players can explore without accepting the story. Relaxed mode is the default: food, thirst and energy do not decay with time. Survival mode remains available from the journal. Exploration of Mele, Port Vila, Port Havannah and Eton unlocks bilingual island notes independently of the story, with a one-time 10-vatu discovery reward. Map targets use the existing simplified OpenStreetMap place coordinates, not exact attraction entrances. The map is compressed to 1:20; the game is not a navigation guide.

## Controls

- J / JOURNAL: optional story, island notes, relaxed/survival mode, map tracking.
- L / TH–EN: switch language. Thai font is bundled for offline and web use.
- M: map and gold destination marker.
- E / USE: talk, cook, collect, enter/exit a vehicle.
- F: cast/cancel fishing. E reels when a fish bites.
- F5/F9 or pause menu: save/load, including story, language and discoveries.

## Research and creative boundaries

Consulted 2026-11-05. In-game facts are paraphrased from the Vanuatu Tourism Office:

- [Round Island Tours](https://www.vanuatu.travel/en/plan/tours/round-island-tours): Efate's sightseeing loop includes Eton and Blue Lagoon. Inspired the open-ended island road-trip structure. Blue Lagoon itself has not been added as a simulated attraction.
- [Active Romance: Efate & Santo](https://www.vanuatu.travel/en/about-vanuatu/provinces/sanma/santo/active-romance-6-days-on-efate-santo): Port Vila markets and local foods, and Havannah Harbour's position northwest of Port Vila with nearby Moso. Used for short Port Vila and Havannah discovery notes; no opening hours or travel-time claims are used.
- [Eton Beach](https://www.vanuatu.travel/en/eton-beach): east-coast location, white sand and river inlet. The Eton note describes the real beach area, not a promise that its inlet is accurately modeled in this game.
- [Kastom](https://www.vanuatu.travel/en/about-vanuatu/understanding-kastom): respect hosts and ask before entering homes, gardens or customary land. Used for dialogue about being a considerate guest. No sacred rites or dress patterns are reproduced.

Villager clothes use twelve original everyday colour palettes with plain, striped and checked fabrics. They are fictional contemporary outfits, not authenticated traditional garments. The base models and their animations are retained.

Font: Noto Sans Thai, Google Fonts, SIL Open Font License; see `assets/fonts/OFL.txt`.

## Validation

Run `godot --headless --path . --script res://tools/check_story.gd` to exercise quest transitions through gameplay interactions, rewards, wardrobe isolation, Thai glyph coverage, save-data compatibility and language switching. Vehicle regression checks remain in `tools/check_driving.gd`.
