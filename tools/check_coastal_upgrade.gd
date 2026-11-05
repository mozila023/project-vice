extends SceneTree
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	print("COASTAL ","PASS " if ok else "FAIL ",label)
	if not ok: failures+=1
func walk(game,goal: Vector3,limit := 650) -> bool:
	for i in range(limit):
		await physics_frame
		var delta: Vector3=goal-game.player.position
		delta.y=0
		if delta.length()<.35: return true
		var direction: Vector3=delta.normalized()
		game.player.velocity=Vector3(direction.x*3,game.player.velocity.y-20.0/60,direction.z*3)
		game.player.move_and_slide(); game.player.apply_floor_snap()
	print("COASTAL WALK stopped ",game.player.position," goal ",goal)
	return false
func run() -> void:
	root.get_node("Preferences").launch="new"
	change_scene_to_file("res://scenes/island.tscn")
	var deadline := Time.get_ticks_msec()+30000
	while current_scene==null or current_scene.get("field_hud")==null:
		await process_frame
		if Time.get_ticks_msec()>deadline: quit(2); return
	var game=current_scene
	game.set_physics_process(false)
	if root.focus_exited.is_connected(game.on_focus_lost): root.focus_exited.disconnect(game.on_focus_lost)
	await physics_frame
	var coordinates := preload("res://scripts/map_coordinates.gd")
	check(game.world.geography.meters_per_game_meter==10 and game.world.GRID_N==483,"island geography and detailed physical heightfield use 1:10")
	check(coordinates.project(-17.763097,168.3091479).distance_to(game.restaurant.SITE)<.01,"Pad Thai GPS pin projects correctly at doubled map scale")
	check(game.player.scale==Vector3.ONE and game.player.get_child(0) is CollisionShape3D,"resident dimensions are not stretched with the island")
	check(game.player.position.distance_to(game.luna.position)<3,"Luna remains within interaction range at new Sunshine spawn")
	check(coordinates.migrate_position(Vector3(-200,3,400),20)==Vector3(-400,6,800),"legacy save coordinates migrate once to 1:10")
	check(coordinates.migrate_position(Vector3(-400,6,800),10)==Vector3(-400,6,800),"new save positions do not migrate a second time")
	check(game.places.entries.size()==737 and game.places.featured.size()==13,"complete imported inventory and thirteen Blender landmarks available")
	for entry in game.places.entries:
		if coordinates.project(entry.latitude,entry.longitude).distance_to(Vector2(entry.at[0],entry.at[1]))>.001:
			check(false,"pin projection mismatch: "+entry.name)
	check(game.places.search("hospital").size()>0 and game.places.search("Blue Lagoon").size()==1,"inventory search finds services and natural attractions")
	game.story.language="th"
	check(game.places.search("โรงพยาบาล").size()>0,"Thai category search finds mapped hospitals")
	game.panel="island"; game.field_hud.atlas_mode=false
	var tap := InputEventScreenTouch.new()
	tap.index=0; tap.pressed=true
	tap.position=game.field_hud.buttons().atlas_toggle.get_center()
	game.field_hud._input(tap)
	var emulated := InputEventMouseButton.new()
	emulated.device=-1; emulated.button_index=MOUSE_BUTTON_LEFT; emulated.pressed=true; emulated.position=tap.position
	game.field_hud._input(emulated)
	check(game.field_hud.atlas_mode,"one touch opens directory once despite an emulated mouse event")
	tap.pressed=false; game.field_hud._input(tap)
	game.field_hud.atlas_search.text="Blue Lagoon"
	game.field_hud.atlas_search.text_changed.emit("Blue Lagoon")
	game.field_hud.activate("atlas_0",true)
	check(game.panel=="place_info" and game.places.by_id[game.places.selected].name=="Blue Lagoon","bag search opens a selected place's information")
	game.field_hud.activate("track_place",true)
	game.navigation.update(0,true)
	check(game.panel=="map" and game.navigation.active() and game.story.target().is_finite(),"selected real place supplies a finite navigation destination")
	var saved: Dictionary=game.story.data()
	game.story.restore(saved)
	check(game.story.tracked_place==game.places.selected,"place tracking survives save restore")
	game.panel=""
	for site in preload("res://scripts/place_sites.gd").SITES:
		var node: Node3D=game.places.featured[site.id]
		check(node.find_children("*","MeshInstance3D",true,false).size()>0,"Blender model loaded: "+site.name)
		# Coastal/underwater sites can be observed without guiding the player into the sea.
		if site.category=="underwater_post": continue
		var start: Vector3=node.to_global(Vector3(0,0,site.size[1]/2+8))
		start.y=game.world.surface_height_at(start.x,start.z)+.15
		game.player.position=start; game.player.velocity=Vector3.ZERO
		check(await walk(game,node.to_global(Vector3(0,0,site.size[1]/2-.7))),"physical entrance ramp: "+site.name)
	# Nearby neighbours genuinely move rather than only appearing as map records.
	game.player.position=Vector3(-978,game.ground(-978,282)+.2,282)
	game.day_time=12; game.population.refresh()
	var starts := {}
	for npc in game.villagers:
		if not npc.get("guide",false) and npc.active: starts[npc.name]=npc.body.position
	for i in range(300):
		await physics_frame
		game.update_villagers(1.0/60)
	var movers := 0
	for npc in game.villagers:
		if starts.has(npc.name) and npc.body.position.distance_to(starts[npc.name])>.5: movers+=1
	check(movers>0,"scheduled residents physically walk their local routes on enlarged island")
	# Exercise the real save reader without touching the user's save file.
	var legacy_position: Vector3=game.spawn/2.0
	var legacy := {"version":2,"position":[legacy_position.x,legacy_position.y,legacy_position.z],"coins":77,"fish":4,"days":3,"day_time":14.0,"story":{"tour_version":1,"stage":5,"luna":[legacy_position.x-1,legacy_position.y,legacy_position.z-1]}}
	var file := FileAccess.open("res://checks/legacy-scale-save.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy)); file.close()
	game.load_game("res://checks/legacy-scale-save.json")
	for i in range(3): await physics_frame
	check(game.coins==77 and game.fish==4 and game.days==3 and game.story.stage==5,"real legacy-save reader preserves inventory, money, clock and tour")
	check(Vector2(game.player.position.x-game.spawn.x,game.player.position.z-game.spawn.z).length()<4,"legacy-save player is placed at the corresponding new-world location")
	game.save_game("res://checks/current-scale-save.json")
	var new_save: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://checks/current-scale-save.json"))
	check(new_save.map_scale==10 and new_save.story.map_scale==10,"new save records both player and guide scale")
	var before: Vector3=game.player.position
	game.load_game("res://checks/current-scale-save.json")
	for i in range(3): await physics_frame
	check(game.player.position.distance_to(before)<.1,"loading a migrated save again does not double its position")
	print("COASTAL RESULT failures=",failures)
	quit(0 if failures==0 else 1)
