# Island placement repair

The previous town pass admitted 94 buildings whose full roof/porch/stair envelopes intersected the rendered road corridor, and six poles within its edge buffer. It used a coarse distance texture and sparse lot samples; some landmark-avoidance offsets also put poles back onto roads.

`placement_rules.gd` now checks road segments against inflated, rotated building rectangles, including verandas, steps and shop awnings. The world bake uses those checks. Pole adjustments validate roads, dry ground and building parcels before rebuilding their wires and collision at the same positions. Loose gatherable props also avoid roads.

Ground supports are now closed boxes in the town's concrete render mesh, with a longer visibility distance than walls. They retain matching collision volumes. The renderer audit checks the actual mesh corners against every recorded support, samples terrain at half-metre intervals, and casts collision rays through sloped foundations.

Several interpreted landmark models also obstructed roads. `art/layout/model_plots.json` records their original model positions and nearby staged plots; their geographic source pins remain unchanged in the directory. `MAP_PIN`, `PORT_PIN` and `BAR_PIN` retain the supplied business locations. Model plots are playable approximations, not surveyed real building locations. Navigation targets the playable entrances. Layout version 2 migrates old saves near relocated model plots without resetting possessions or quest progress.

Verification: `tools/check_world_placements.gd` checks every town house, pole, foundation, tree/palm origin and gatherable resource against roads/terrain; `tools/check_road_obstacles.gd` samples three lanes along the island roads against actual static collision; `tools/check_foundations.gd` verifies rendered geometry and collision. The Luna escort and coastal entrance checks cover gameplay after the rebuild.
