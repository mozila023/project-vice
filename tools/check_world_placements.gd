extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.get_node("Preferences").launch="new"
	change_scene_to_file("res://scenes/island.tscn")
	while current_scene==null or current_scene.get("field_hud")==null: await process_frame
	var game=current_scene;game.set_physics_process(false)
	var rules=preload("res://scripts/placement_rules.gd")
	var houses := 0;var poles := 0;var gaps := 0
	for house in game.settlement.house_sites:
		var d: Dictionary=house.data
		if not rules.rect_clear(game.world,Vector2(d.x,d.z),d.yaw,rules.house_rect(d.w,d.d,d.style==2)):
			houses+=1
			if houses<=8: print("ROAD HOUSE ",Vector2(d.x,d.z))
	for pole in game.settlement.pole_sites:
		if rules.clearance(game.world,Vector2(pole.x,pole.z))<.7:
			poles+=1
			if poles<=8: print("ROAD POLE ",pole)
	for support in game.settlement.foundation_supports:
		for x in [-.5,0,.5]:
			for z in [-.5,0,.5]:
				var p: Vector3=support.transform*(support.center+Vector3(x*support.size.x,0,z*support.size.z))
				if support.transform.origin.y+support.bottom>game.world.surface_height_at(p.x,p.z)-.1: gaps+=1
	var trees := 0;var tree_obstacles := 0;var resource_obstacles := 0
	for kind in ["trees","palms"]:
		for group in game.world.baked[kind]:
			for i in range(group.count):
				var p: Vector3=group.centre+Vector3(group.buffer[i*16+3],group.buffer[i*16+7],group.buffer[i*16+11])
				trees+=1
				if rules.clearance(game.world,Vector2(p.x,p.z))<.6: tree_obstacles+=1
	for item in game.resources:
		if rules.clearance(game.world,Vector2(item.node.position.x,item.node.position.z))<.4: resource_obstacles+=1
	# Exercise the actual old-save reader around a relocated starting shop.
	var old_spawn: Vector2=game.sunshine.MAP_PIN+Vector2(-5.3,-7.8)
	var legacy := {"version":2,"map_scale":10,"position":[old_spawn.x,game.ground(old_spawn.x,old_spawn.y)+.1,old_spawn.y],"coins":77,"fish":4,"story":{"tour_version":1,"stage":0,"map_scale":10,"luna":[old_spawn.x-1.4,game.ground(old_spawn.x,old_spawn.y)+.1,old_spawn.y-1.4]}}
	var path := "res://checks/legacy-layout-save.json"
	var file := FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(legacy));file.close()
	game.load_game(path)
	for i in range(4): await physics_frame
	var migrated: bool=game.coins==77 and game.fish==4 and Vector2(game.player.position.x-game.spawn.x,game.player.position.z-game.spawn.z).length()<3 and game.player.position.distance_to(game.luna.position)<4
	print("LAYOUT SAVE migration=",migrated)
	print("PLACEMENTS houses=",game.settlement.house_sites.size()," road_houses=",houses," poles=",game.settlement.pole_sites.size()," road_poles=",poles," foundation_gaps=",gaps," trees=",trees," road_trees=",tree_obstacles," road_resources=",resource_obstacles)
	quit(1 if houses+poles+gaps+tree_obstacles+resource_obstacles>0 or not migrated else 0)
