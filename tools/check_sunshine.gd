extends SceneTree
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool,label: String) -> void:
	print("SUNSHINE ","PASS " if ok else "FAIL ",label)
	if not ok: failures+=1
func run() -> void:
	root.get_node("Preferences").launch="new"
	change_scene_to_file("res://scenes/island.tscn")
	while current_scene==null or current_scene.get("field_hud")==null: await process_frame
	var game=current_scene
	game.set_physics_process(false)
	if root.focus_exited.is_connected(game.on_focus_lost): root.focus_exited.disconnect(game.on_focus_lost)
	await physics_frame
	var spa=game.sunshine
	var expected := Vector2((168.3207769-168.363)*5300.0,-(-17.7419608+17.6625)*5550.0)
	check(Vector2(spa.position.x,spa.position.z).distance_to(expected)<0.01,"shop uses the verified Port Vila geographic projection")
	check(Vector2(game.player.position.x,game.player.position.z).distance_to(spa.SPAWN)<0.1,"New Game spawns at the shop entrance")
	check(game.story.stage==0 and game.fish==0,"new start preserves the fresh story")
	var reachable := true
	for local in [Vector3(5.3,0,5.3),Vector3(5.3,0,3.65),Vector3(-1,0,3.65),Vector3(-1,0,0.0)]:
		var goal: Vector3=spa.transform*local
		for i in range(300):
			await physics_frame
			var delta: Vector3=goal-game.player.position
			delta.y=0
			if delta.length()<0.16: break
			var direction: Vector3=delta.normalized()
			game.player.velocity=Vector3(direction.x*2.5,game.player.velocity.y-12.0/60.0,direction.z*2.5)
			game.player.move_and_slide()
		if Vector2(goal.x,goal.z).distance_to(Vector2(game.player.position.x,game.player.position.z))>0.3:
			print("BLOCKED at ",game.player.position," goal ",goal)
			reachable=false
			break
	check(reachable,"player physically walks through driveway, courtyard and salon door")
	check(absf(game.player.position.y-spa.floor_height)<0.2,"player stands on the salon floor without clipping")
	game.story.tracked_place=spa.TITLE
	game.navigation.update(0,true)
	check(Vector2(game.story.target().x,game.story.target().z).distance_to(spa.SITE)<0.1,"shop can be tracked as an optional destination")
	game.panel="island"
	check(game.field_hud.buttons().has("place_4"),"journal exposes the new shop destination")
	var groups=0
	for node in spa.get_children():
		if node is MeshInstance3D: groups+=1
	check(groups<=18,"shop geometry stays batched for web and mobile")
	print("SUNSHINE RESULT ","PASS" if failures==0 else "FAIL"," failures=",failures)
	quit(0 if failures==0 else 1)
