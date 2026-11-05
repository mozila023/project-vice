extends SceneTree
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool,label: String) -> void:
	print("MINIMAP ","PASS " if ok else "FAIL ",label)
	if not ok: failures+=1

func run() -> void:
	change_scene_to_file("res://scenes/island.tscn")
	while current_scene==null or current_scene.get("field_hud")==null: await process_frame
	var game=current_scene
	game.set_physics_process(false)
	await process_frame
	var map=game.field_hud.mini_map
	var at := Vector2(game.player.position.x,game.player.position.z)
	var center := Vector2(88,88)
	check(map.map_point(at).is_equal_approx(center),"player remains at map centre")
	var north: Vector2=map.map_point(at+Vector2(0,-20))
	check(north.y<center.y and is_equal_approx(north.x,center.x),"map remains north-up")
	var near: Dictionary=map.goal_marker(at+Vector2(30,0))
	var far: Dictionary=map.goal_marker(at+Vector2(1000,500))
	check(near.inside and not far.inside and far.point.x<=164.01 and far.point.y<=164.01,"distant quest is clamped to a visible edge indicator")
	game.player.rotation.y=0
	check(map.player_direction().is_equal_approx(Vector2.UP),"on-foot arrow follows player heading")
	var walking_radius: float=map.radius()
	var car=game.cars[4]
	car.rotation.y=0
	game.enter_car(car)
	check(map.radius()>walking_radius and map.player_direction().is_equal_approx(Vector2.DOWN),"driving zooms out and follows car heading")
	game.leave_car(true)
	game.field_hud.activate("minimap",true)
	await process_frame
	await process_frame
	check(game.panel=="map" and not map.visible,"minimap click opens full map and hides local overlay")
	game.panel=""
	game.field_hud.mobile=true
	await process_frame
	await process_frame
	check(map.visible and map.position.y>=236 and map.position.y+map.size.y<game.field_hud.size.y-198,"mobile minimap clears vitals and joystick")
	print("MINIMAP RESULT ","PASS" if failures==0 else "FAIL"," failures=",failures)
	quit(0 if failures==0 else 1)
