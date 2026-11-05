extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.get_node("Preferences").launch="new"
	change_scene_to_file("res://scenes/island.tscn")
	while current_scene==null or current_scene.get("field_hud")==null: await process_frame
	var game=current_scene;game.set_physics_process(false)
	await physics_frame
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape=CapsuleShape3D.new();query.shape.radius=.25;query.shape.height=1.5
	query.collision_mask=1|8
	var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
	var seen := {};var obstacles := {};var samples := 0
	for road in game.world.geography.roads:
		if road.type=="runway": continue
		for i in range(road.points.size()-1):
			var a := Vector2(road.points[i][0],road.points[i][1]);var b := Vector2(road.points[i+1][0],road.points[i+1][1])
			var steps := maxi(1,ceili(a.distance_to(b)/2))
			var side := (b-a).normalized().orthogonal()
			for j in range(steps+1):
				for lane in [-.65,0,.65]:
					var p: Vector2=a.lerp(b,float(j)/steps)+side*lane*game.world.road_half(road.type)
					var key := Vector2i(roundi(p.x),roundi(p.y))
					if seen.has(key): continue
					seen[key]=true
					var y: float=game.world.surface_height_at(p.x,p.y)
					if y<.1: continue
					query.transform=Transform3D(Basis.IDENTITY,Vector3(p.x,y+1,p.y));samples+=1
					for hit in space.intersect_shape(query,8):
						var path: String=hit.collider.get_path()
						if not obstacles.has(path): obstacles[path]={"at":p,"path":path}
	for obstacle in obstacles.values(): print("ROAD OBSTACLE ",obstacle)
	print("ROAD SCAN samples=",samples," unique_obstacles=",obstacles.size())
	quit(0 if obstacles.is_empty() else 1)
