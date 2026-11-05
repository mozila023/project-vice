extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	change_scene_to_file("res://scenes/island.tscn")
	while current_scene==null or current_scene.get("field_hud")==null: await process_frame
	var game=current_scene
	game.set_physics_process(false)
	if root.focus_exited.is_connected(game.on_focus_lost): root.focus_exited.disconnect(game.on_focus_lost)
	game.player.hide()
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.current=true
	camera.far=7000
	game.camera=camera
	for pose in ["sunshine","padthai","port","market","museum","waterfall","lagoon","atlas","atlas_search","map"]:
		game.panel=""; game.notice_time=0; game.day_time=10.5
		var node: Node3D=game.sunshine
		var offset := Vector3(17,8,23)
		if pose=="sunshine": offset=Vector3(-11,4.5,-15)
		if pose=="padthai": node=game.restaurant; offset=Vector3(19,8,25)
		if pose=="port": node=game.landmarks.port; offset=Vector3(35,21,36)
		for site in preload("res://scripts/place_sites.gd").SITES:
			if site.category==pose: node=game.places.featured[site.id]
		var center: Vector3=node.global_position+Vector3.UP*1.8
		game.player.position=center
		game.population.refresh()
		for i in range(45):
			await physics_frame
			game.update_villagers(1.0/60)
		camera.position=center+offset
		camera.look_at(center)
		game.field_hud.visible=pose in ["atlas","atlas_search","map"]
		game.world.update_daylight(game.day_time,true)
		game.world.update_view(camera.position,game.day_time,0)
		if pose in ["atlas","atlas_search"]:
			game.panel="island"; game.field_hud.atlas_mode=true
			if pose=="atlas_search": game.field_hud.atlas_search.text="hospital"; game.field_hud.atlas_entries=game.places.search("hospital")
		if pose=="map": game.panel="map"
		for i in range(24): await process_frame
		root.get_texture().get_image().save_png("res://checks/coastal-"+pose+".png")
		print("COASTAL SHOT ",pose," draws=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	quit()
