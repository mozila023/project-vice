extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	change_scene_to_file("res://scenes/front_end.tscn")
	while current_scene==null or current_scene.get("view")==null: await process_frame
	for i in range(10): await process_frame
	root.get_texture().get_image().save_png("res://checks/expansion-menu.png")
	change_scene_to_file("res://scenes/island.tscn")
	while current_scene==null or current_scene.get("field_hud")==null: await process_frame
	var game=current_scene
	game.set_physics_process(false)
	if root.focus_exited.is_connected(game.on_focus_lost): root.focus_exited.disconnect(game.on_focus_lost)
	game.player.hide()
	var shot_camera := Camera3D.new()
	game.add_child(shot_camera)
	shot_camera.current=true
	shot_camera.far=7000
	game.camera=shot_camera
	for pose in ["port","bar_day","bar_evening","journal"]:
		game.panel=""
		game.notice_time=0
		game.day_time=18.1 if pose=="bar_evening" else 11.0
		game.landmarks.update_hours()
		game.story.stage=5
		var center: Vector3=game.landmarks.port.position+Vector3(0,2,0) if pose=="port" else game.landmarks.bar.position+Vector3(0,1.5,0)
		game.player.position=center
		game.population.refresh()
		for i in range(30):
			await physics_frame
			game.update_villagers(1.0/60)
		game.pivot.position=Vector3.ZERO
		game.pivot.rotation=Vector3.ZERO
		game.camera.position=center+(Vector3(45,32,47) if pose=="port" else Vector3(-16,7,-24))
		game.camera.look_at(center)
		game.world.update_daylight(game.day_time,true)
		game.world.update_view(game.camera.global_position,game.day_time,0)
		game.field_hud.visible=pose=="journal"
		if pose=="journal": game.panel="journal"
		for i in range(20): await process_frame
		root.get_texture().get_image().save_png("res://checks/expansion-"+pose+".png")
		print("EXPANSION SHOT ",pose)
	quit()
