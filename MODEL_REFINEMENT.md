# Blender model and collision refinement

The coastal house is authored by `tools/blender_refine_island.py` in Blender 5.2. It exports a 314-triangle GLB, seven matching collision boxes and an editable `art/blender/island_refined.blend`. Roof panels are closed solids; the old protruding gable trim and stacked window panels are removed. The runtime keeps material/chunk batching and varies wall/roof colours.

`scripts/settlement.gd` fits foundations, porches and both entrance steps to the visible terrain/road surface. Shop foundations and awning slabs also receive terrain-dependent bases instead of fixed depths. Full footprint sampling catches low terrain between corners. Each rendered support has a matching collision volume. Walls, slab, steps and porch posts have separate collision shapes, leaving the porch opening clear. Ordinary homes remain exterior-only; the Sunshine salon keeps its walkable interior.

Blender also measures connected components of the existing well, shelter, campfire and salon furniture. `prop_physics.json` contains fitted proxies that preserve gaps between posts and table/chair legs. Loose UV/normal seams are welded for the measurements to avoid one collider per face. Ground props are placed using their actual mesh bottoms. Batched rocks now share a convex collision hull at exactly the same transform as their rendered instances.

The fishing splash is a Blender-authored, 20-track droplet animation. Bites and successful catches play it for one second, with shadows disabled, then remove the node.

Verification:

- `tools/check_refinement.gd`: imported house, wall/capsule blocking, porch posts/opening, rock hulls, prop ground contact, furniture proxies, splash animation and cleanup.
- `tools/check_foundations.gd`: every generated building, all foundation/porch/step support types, dense terrain contact audit and sampled support collision rays.
- `tools/check_sunshine.gd`: actual walking through the driveway/courtyard/salon entrance and standing on the salon floor.
- Blender review: `checks/blender-house-preview.png`; Godot review: `checks/godot-refined-house.png`.

This update changes the local project and local export. It does not publish to the existing GitHub Pages site. Physical phone performance has not been measured.
