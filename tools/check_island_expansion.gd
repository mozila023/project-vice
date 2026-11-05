extends SceneTree
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	print("EXPANSION ","PASS " if ok else "FAIL ",label)
	if not ok: failures+=1
func walk(game,goal: Vector3) -> bool:
	for i in range(700):
		await physics_frame
		var delta: Vector3=goal-game.player.position
		delta.y=0
		if delta.length()<.3: return true
		var direction: Vector3=delta.normalized()
		game.player.velocity=Vector3(direction.x*3,game.player.velocity.y-20.0/60,direction.z*3)
		game.player.move_and_slide()
		game.player.apply_floor_snap()
	print("WALK stopped ",game.player.position," goal ",goal)
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
	var clear_poles := true
	for at in game.settlement.pole_sites:
		if game.landmarks.reserved(at.x,at.z): clear_poles=false
	check(clear_poles,"electrical poles and connected wires avoid new landmark roofs")
	check(game.population.records.size()==30,"thirty scheduled residents across ten island regions")
	var day_count := 0
	var night_count := 0
	for zone in game.population.ZONES:
		game.player.position=Vector3(zone[1],game.ground(zone[1],zone[2])+.2,zone[2])
		game.day_time=12
		game.population.refresh()
		var locals := 0
		for npc in game.villagers:
			if npc.get("guide",false): continue
			if npc.active:
				day_count+=1
				if npc.region==zone[0]: locals+=1
			else: check(npc.body.collision_layer==0 and not npc.body.visible,"sleeping/unloaded resident cannot block or interact")
		if zone[0]!="Pango": check(locals>0,"daytime residents in "+zone[0])
		game.day_time=1
		game.population.refresh()
		for npc in game.villagers:
			if not npc.get("guide",false) and npc.active: night_count+=1
	check(night_count<day_count/3,"night population is sparse while ordinary neighbours sleep")
	for hour in [8.0,16.0,22.9,23.0]:
		game.day_time=hour
		game.landmarks.update_hours()
		check(game.landmarks.bar_open==(hour>=16 and hour<23),"bar hours at "+str(hour))
		check(game.landmarks.shutters.visible!=game.landmarks.bar_open,"Blender shutters match opening hours")
	game.story.stage=5
	for i in range(3): game.quests.inspect(i)
	game.player.position=game.landmarks.port_desk
	game.day_time=12; game.panel="port"
	var money: int=game.coins
	game.quests.action("port_report"); game.quests.action("port_report")
	check(game.coins==money+25 and 0 in game.quests.claimed,"cargo survey pays once at port office")
	for name in ["Maya","Elise","Sam"]: game.quests.on_talk(name)
	check(game.quests.greetings.size()==3,"regional greetings teach three distinct villages")
	game.quests.claim(1); game.quests.claim(1)
	check(game.coins==money+65,"neighbour quest pays once")
	game.player.position=game.landmarks.bar_desk; game.panel="nakamal"; game.day_time=8; game.landmarks.update_hours()
	game.quests.action("bar_greet")
	check(not game.quests.bar_greet,"closed bar cannot complete evening story")
	game.day_time=18; game.landmarks.update_hours()
	game.quests.action("bar_greet"); game.quests.action("bar_story"); game.quests.action("bar_story")
	check(game.coins==money+85 and 2 in game.quests.claimed,"evening story completes without requiring consumption")
	game.player.position=Vector3(game.restaurant.SITE.x,game.restaurant.floor_height,game.restaurant.SITE.y+2)
	game.panel="restaurant"; game.fish=2
	game.quests.action("community_meal"); game.quests.action("community_meal")
	check(game.fish==0 and game.coins==money+120,"shared meal consumes two fish and rewards once")
	var saved: Dictionary=game.story.data()
	game.story.restore(saved)
	check(game.quests.claimed.size()==4 and game.quests.greetings.size()==3,"new stories persist alongside Luna tour in saves")
	game.panel="island"; game.field_hud.notes_page=1
	check(game.field_hud.buttons().has("place_8") and not game.field_hud.buttons().has("place_0"),"island notes paginate without overflowing bag")
	game.panel="journal"
	check(game.field_hud.buttons().has("quest_3"),"four island stories selectable from bag journal")
	for node in [game.landmarks.port,game.landmarks.bar]:
		var depth: float=32 if node==game.landmarks.port else 12
		var start: Vector3=node.to_global(Vector3(0,0,depth/2+8))
		start.y=game.world.surface_height_at(start.x,start.z)+.2
		game.player.position=start
		game.player.velocity=Vector3.ZERO
		check(await walk(game,node.to_global(Vector3(0,0,depth/2-1))),"player physically walks entrance ramp of "+node.name)
	print("EXPANSION RESULT failures=",failures)
	quit(0 if failures==0 else 1)
