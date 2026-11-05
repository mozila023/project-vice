extends SceneTree
var failures := 0
var preferences: Node

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool,label: String) -> void:
	print("FRONT ","PASS " if ok else "FAIL ",label)
	if not ok: failures+=1

func run() -> void:
	preferences=root.get_node('Preferences')
	change_scene_to_file("res://scenes/front_end.tscn")
	while current_scene==null or current_scene.get("view")==null: await process_frame
	var front=current_scene
	check(front.screen=="menu" and front.camera.current,"launch opens the main menu")
	front.screen="settings"
	await process_frame
	await process_frame
	check(is_instance_valid(front.view.settings),"main-menu settings panel opens")
	preferences.save("res://checks/preferences-test.cfg")
	var config := ConfigFile.new()
	check(config.load("res://checks/preferences-test.cfg")==OK and config.get_value("game","language")==preferences.language and config.get_value("game","quality")==preferences.quality,"settings serialize to a separate test file")
	front.start_new_game()
	check(front.screen=="intro" and preferences.launch=="new" and front.traveler.visible,"New Game begins boarding scene")
	front.set_intro_pose(11.0)
	check(front.cabin.visible and not front.apron.visible,"second cinematic shot is inside the aircraft")
	front.set_intro_pose(20.0)
	check(front.island.visible and front.island_environment.environment!=null and front.front_environment.environment==null,"arrival uses the real island and one active environment")
	front.arrive()
	front.arrive()
	check(front.loading,"skip intro starts loading exactly once")
	var deadline := Time.get_ticks_msec()+20000
	while (current_scene==front or current_scene==null) and Time.get_ticks_msec()<deadline: await process_frame
	check(current_scene!=front and current_scene!=null,"cinematic transitions into the playable island")
	if current_scene==null or current_scene==front:
		quit(1)
		return
	var game=current_scene
	game.set_physics_process(false)
	check(game.story.stage==0 and game.fish==0,"new game starts with fresh story and inventory")
	check(game.player.visible and game.player.collision_mask!=0,"player is controllable after arrival")
	check(game.navigation.graph.get_point_count()>100,"quest navigation indexes mapped roads")
	game.story.stage=4
	game.navigation.update(0,true)
	check(game.navigation.road_route and game.navigation.route.size()>2,"distant quest follows connected road waypoints")
	check(is_finite(game.navigation.bearing()) and game.navigation.distance()>0,"guidance supplies direction and distance")
	game.story.stage=3
	game.wood=0
	var wood_goal: Vector3=game.story.target()
	game.wood=3
	check(game.story.target().is_equal_approx(game.villagers[0].body.position) and not wood_goal.is_equal_approx(game.story.target()),"quest target switches from driftwood to Malia when supplies are ready")
	var previous_navigation: bool=preferences.navigation
	preferences.navigation=false
	check(not game.navigation.active(),"settings can disable quest guidance")
	preferences.navigation=previous_navigation
	game.field_hud.activate("settings",true)
	await process_frame
	await process_frame
	check(game.panel=="settings" and is_instance_valid(game.field_hud.settings_view),"settings open from the pause flow without resetting the island")
	game.field_hud.activate("main_menu",true)
	await process_frame
	await process_frame
	check(current_scene!=game and current_scene.get("screen")=="menu","return to main menu works")
	print("FRONT RESULT ","PASS" if failures==0 else "FAIL"," failures=",failures)
	quit(0 if failures==0 else 1)
