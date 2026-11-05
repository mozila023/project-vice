extends SceneTree
## Bake unchanged town geometry and collision ahead of time, avoiding SurfaceTool work on a phone.
func _initialize() -> void: run.call_deferred()
func own_children(node: Node,owner_node: Node) -> void:
	var index := 0
	for child in node.get_children():
		if String(child.name).begins_with("@"):
			child.name=child.get_class()+"_%d"%index
		child.owner=owner_node
		own_children(child,owner_node)
		index+=1
func run() -> void:
	var world=preload("res://scripts/tropical_world.gd").new()
	root.add_child(world)
	world.build()
	var town=preload("res://scripts/settlement.gd").new()
	town.world=world
	town.allow_cache=false
	root.add_child(town)
	town.build()
	own_children(town,town)
	town.set_meta("cache_version",town.CACHE_VERSION)
	town.set_meta("world_hash",FileAccess.get_sha256("res://assets/baked/world.dat"))
	town.set_meta("night_glass",town.glass)
	town.set_meta("pole_sites",town.pole_sites)
	town.set_meta("wire_spans",town.wire_spans)
	town.set_meta("foundation_supports",town.foundation_supports)
	var houses := []
	for house in town.house_sites:
		var entry: Dictionary=house.duplicate()
		entry.body_path=town.get_path_to(house.body)
		entry.erase("body")
		houses.append(entry)
	town.set_meta("house_sites",houses)
	var paths: Array[NodePath] = []
	for lamp in town.lamps: paths.append(town.get_path_to(lamp))
	town.set_meta("lamp_paths",paths)
	var packed := PackedScene.new()
	var error := packed.pack(town)
	if error==OK: error=ResourceSaver.save(packed,town.CACHE_PATH,ResourceSaver.FLAG_COMPRESS)
	print("TOWN BAKE result=",error," houses=",houses.size()," children=",town.get_child_count())
	quit(error)
