extends SceneTree
func _initialize() -> void:
	var w=load("res://scripts/tropical_world.gd").new()
	w.baked=bytes_to_var(FileAccess.get_file_as_bytes("res://assets/baked/world.dat"))
	w.heights=w.baked.heights
	var at := Vector2((168.3207769-168.363)*5300.0,-(-17.7419608+17.6625)*5550.0)
	print("SPA at=",at," height=",w.height_at(at.x,at.y))
	for b in w.baked.buildings:
		if Vector2(b.x,b.z).distance_to(at)<35: print("BUILDING ",b)
	var geo=JSON.parse_string(FileAccess.get_file_as_string("res://assets/geography/efate-game-map.json"))
	for r in geo.roads:
		for p in r.points:
			if Vector2(p[0],p[1]).distance_to(at)<20: print("ROAD ",r); break
	w.free()
	quit()
