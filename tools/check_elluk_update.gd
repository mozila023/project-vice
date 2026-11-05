extends SceneTree
var failures := 0
var report := {}
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	report[label]=ok
	print("ELLUK ","PASS " if ok else "FAIL ",label)
	if not ok: failures+=1
func advance(game,frames: int) -> void:
	for i in range(frames):
		await physics_frame
		game._physics_process(1.0/60.0)
func reset_player(game) -> void:
	game.player.position=game.restaurant.position+Vector3(0,0.05,3)
	game.player.velocity=Vector3.ZERO
	game.yaw=0
	game.paused=false
	game.panel=""
func run() -> void:
	root.get_node("Preferences").launch="new"
	change_scene_to_file("res://scenes/island.tscn")
	while current_scene==null or current_scene.get("field_hud")==null: await process_frame
	var game=current_scene
	game.set_physics_process(false)
	if root.focus_exited.is_connected(game.on_focus_lost): root.focus_exited.disconnect(game.on_focus_lost)
	await physics_frame
	var expected := Vector2((168.3091479-168.363)*5300,-(-17.763097+17.6625)*5550)
	check(game.restaurant.SITE.distance_to(expected)<0.001,"restaurant matches user supplied geographic pin")
	check(game.restaurant.find_children("*","MeshInstance3D",true,false).size()<32,"restaurant batches materials for mobile")
	var animation: AnimationPlayer=game.visual.find_child("AnimationPlayer",true,false)
	check(animation.has_animation("sprint") and animation.get_animation("sprint")!=animation.get_animation("walk"),"run uses a distinct retargeted motion clip")
	reset_player(game)
	game.energy=100;game.stamina=100;game.sprint_locked=false
	Input.action_press("forward");Input.action_press("sprint")
	await advance(game,25)
	check(game.locomotion_state=="sprint" and game.locomotion_speed>6.5,"Shift produces running at seven metres per second")
	reset_player(game)
	game.stamina=0
	await advance(game,45)
	check(game.sprint_locked and game.locomotion_state=="walk" and game.locomotion_speed>3.5,"exhausted stamina keeps walking while Shift stays held")
	reset_player(game)
	game.energy=0;game.stamina=100
	await advance(game,25)
	check(game.locomotion_state=="walk" and game.locomotion_speed>3.5,"zero Energy still allows continuous walking")
	game.player.position=game.restaurant.position+Vector3(0,.05,-4.1)
	game.player.velocity=Vector3.ZERO
	await advance(game,35)
	check(game.locomotion_speed<0.15 and game.locomotion_state=="idle","blocked character idles instead of twitching legs")
	Input.action_release("forward");Input.action_release("sprint")
	await advance(game,1)
	check(not game.sprint_locked,"releasing Shift rearms sprint after recovery")
	var pots: Array=game.sunshine.find_children("GroundedPlanter*","Node3D",true,false)
	var grounded: bool=pots.size()==5
	for pot: Node3D in pots:
		var expected_y: float=game.sunshine.floor_height if pot.position.z<2.3 else game.world.surface_height_at(pot.global_position.x,pot.global_position.z)
		grounded=grounded and absf(pot.global_position.y-expected_y-.008)<.001
		grounded=grounded and pot.find_children("*","CollisionShape3D",true,false).size()==1
	check(grounded,"all five planters and their collision rest on their own supporting surface")
	reset_player(game)
	game.story.tracked_place="Mele"
	game.navigation.update(0,true)
	var count: int=game.navigation.rebuild_count
	for i in range(300): game.navigation.update(1.0/60.0)
	check(game.navigation.rebuild_count==count,"stationary guidance does not rebuild every second")
	game.player.position=Vector3(game.sunshine.SPAWN.x,game.sunshine.floor_height,game.sunshine.SPAWN.y)
	game.navigation.update(0,true)
	check(game.navigation.road_route,"junction graph finds the coastal route from Seaside to Mele")
	if game.navigation.path.size()>12:
		var before: float=game.navigation.distance()
		for i in range(1,12):
			game.player.position=game.navigation.path[i]
			game.navigation.update(1.0/60.0)
		check(game.navigation.segment>=10 and game.navigation.distance()<before,"guidance advances forward and reduces remaining road distance")
	reset_player(game)
	game.story.tracked_place="PAD THAI @ELLUK"
	game.navigation.update(0,true)
	check(game.navigation.arrived and game.navigation.distance()<6,"restaurant destination reports arrival")
	game.player.position=Vector3(game.restaurant.SITE.x,game.world.surface_height_at(game.restaurant.SITE.x,game.restaurant.SITE.y+14)+.1,game.restaurant.SITE.y+14)
	game.player.velocity=Vector3.ZERO
	var goal: Vector3=game.restaurant.position+Vector3(0,0,2.5)
	for i in range(420):
		await physics_frame
		var delta: Vector3=goal-game.player.position
		delta.y=0
		if delta.length()<.2: break
		var direction: Vector3=delta.normalized()
		game.player.velocity=Vector3(direction.x*2.5,game.player.velocity.y-20.0/60.0,direction.z*2.5)
		game.player.move_and_slide()
	check(Vector2(goal.x-game.player.position.x,goal.z-game.player.position.z).length()<.3,"player physically climbs timber stairs and enters restaurant")
	check(absf(game.player.position.y-game.restaurant.floor_height)<.15,"restaurant floor is reached without falling through entrance")
	var file := FileAccess.open("res://checks/elluk-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures":failures,"checks":report},"\t"))
	print("ELLUK RESULT failures=",failures)
	quit(0 if failures==0 else 1)
