extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.get_node("Preferences").launch="new"
	change_scene_to_file("res://scenes/island.tscn")
	while current_scene==null or current_scene.get("field_hud")==null: await process_frame
	var game=current_scene;game.set_physics_process(false)
	await physics_frame
	var targets := [
		{"id":"sunshine","node":game.sunshine,"rect":Rect2(-9.5,-6.6,19,13.4)},
		{"id":"padthai","node":game.restaurant,"rect":Rect2(-8.6,-7.5,17.2,22)},
		{"id":"port","node":game.landmarks.port,"rect":Rect2(-24.5,-16.5,49,41)},
		{"id":"bar","node":game.landmarks.bar,"rect":Rect2(-8,-6.5,16,21)},
		{"id":"hotel","node":game.hotel,"rect":Rect2(-8,-7,16,19)}]
	for site in preload("res://scripts/place_sites.gd").SITES:
		if site.category in ["underwater_post","waterfall","river","cave","lagoon"]: continue
		targets.append({"id":site.id,"node":game.places.featured[site.id],"rect":Rect2(-site.size[0]/2.0-.6,-site.size[1]/2.0-.6,site.size[0]+1.2,site.size[1]+9.2)})
	var rules=preload("res://scripts/placement_rules.gd")
	var offsets: Array[Vector2]=[]
	for dx in range(-160,161,4):
		for dz in range(-160,161,4): offsets.append(Vector2(dx,dz))
	offsets.sort_custom(func(a,b): return a.length_squared()<b.length_squared())
	var output := {}
	for target in targets:
		var node: Node3D=target.node;var rect: Rect2=target.rect
		var original := Vector2(node.position.x,node.position.z)
		if rules.rect_clear(game.world,original,node.rotation.y,rect): continue
		var query := PhysicsShapeQueryParameters3D.new();query.shape=BoxShape3D.new()
		query.shape.size=Vector3(rect.size.x+2,7,rect.size.y+2);query.collision_mask=1|8
		var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
		for offset in offsets:
			var at: Vector2=original+offset
			if not rules.rect_clear(game.world,at,node.rotation.y,rect): continue
			var high := -INF;var low := INF
			var basis := Basis(Vector3.UP,node.rotation.y)
			for x in [-.5,0,.5]:
				for z in [-.5,0,.5]:
					var p: Vector3=Vector3(at.x,0,at.y)+basis*Vector3(rect.get_center().x+x*rect.size.x,0,rect.get_center().y+z*rect.size.y)
					var h: float=game.world.surface_height_at(p.x,p.z);high=maxf(high,h);low=minf(low,h)
			if low<.35 or high-low>1.8: continue
			query.transform=Transform3D(basis,Vector3(at.x,high+1,at.y)+basis*Vector3(rect.get_center().x,0,rect.get_center().y))
			if not space.intersect_shape(query,1).is_empty(): continue
			node.position=Vector3(at.x,high+.12,at.y)
			output[target.id]={"at":[at.x,at.y],"original":[original.x,original.y],"offset":[offset.x,offset.y]}
			print("CLEAR LANDMARK ",target.id," ",output[target.id])
			await physics_frame
			break
		if not output.has(target.id): print("NO CLEAR PLOT ",target.id)
	var file := FileAccess.open("res://checks/landmark-plots.json",FileAccess.WRITE);file.store_string(JSON.stringify(output,"\t"))
	quit()
