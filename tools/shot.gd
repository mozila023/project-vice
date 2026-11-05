extends SceneTree
## Visual regression helper. Renders the real game scene from fixed poses and logs load time and render stats.
## Run windowed (a renderer is required), output folder is the first user argument:
##   godot --path . --script res://tools/shot.gd -- <absolute_out_dir> [pose_name ...]

const POSES := {
	# name: [x, y(above ground), z, yaw, pitch, arm_length, hour, show_hud]
	"spawn": [-514.0, 1.4, 144.0, 1.1, -0.10, 5.5, 8.5, true],
	"street": [-489.0, 1.6, 150.0, 0.0, -0.04, 4.0, 10.0, false],
	"homes": [-470.0, 1.8, 148.0, 0.5, -0.05, 6.0, 15.0, false],
	"beach": [-528.0, 1.6, 178.0, 2.3, -0.05, 5.0, 9.0, false],
	"sea": [-531.0, 2.4, 188.0, 1.9, -0.08, 5.0, 16.5, false],
	"boats": [-531.0, 1.8, 172.0, 1.2, -0.10, 6.0, 11.0, false],
	"car": [0.0, 1.8, 0.0, 0.4, -0.10, 7.0, 10.5, false],
	"driving": [0.0, 2.0, 0.0, 0.0, -0.16, 8.0, 10.5, true],
	"town": [-254.0, 2.0, 438.0, 0.6, -0.03, 6.0, 10.5, false],
	"road": [-300.0, 1.8, 380.0, 0.0, -0.04, 5.0, 14.0, false],
	"hills": [-420.0, 3.0, 40.0, -0.9, 0.03, 5.0, 11.0, false],
	"forest": [-200.0, 1.6, -250.0, 0.8, -0.02, 4.0, 12.0, false],
	"sunset": [-528.0, 2.0, 180.0, 1.75, -0.02, 5.0, 17.75, false],
	"night": [-489.0, 1.6, 150.0, 0.0, -0.04, 4.0, 22.0, false],
	"dusk": [-528.0, 2.0, 180.0, 1.75, -0.02, 5.0, 18.15, false],
	"aerial": [-620.0, 140.0, 330.0, -0.75, -0.42, 0.5, 10.0, false],
	"vila_air": [-360.0, 170.0, 620.0, -0.45, -0.55, 0.5, 10.0, false],
	"vila_street": [-268.0, 1.7, 420.0, 0.2, -0.06, 4.5, 15.5, false],
	"suburb": [-290.0, 1.7, 290.0, 1.5, -0.05, 4.5, 9.5, false],
	"ring_road": [-420.0, 1.7, 192.0, -1.2, -0.05, 4.5, 11.0, false],
}

func _initialize() -> void:
	run()

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size()>0 else OS.get_user_data_dir()
	var names: Array = args.slice(1) if args.size()>1 else POSES.keys()
	DirAccess.make_dir_recursive_absolute(out)
	var started := Time.get_ticks_msec()
	change_scene_to_file("res://scenes/island.tscn")
	while current_scene==null or current_scene.get("field_hud")==null: await process_frame
	print("SHOT load_ms=",Time.get_ticks_msec()-started)
	var game: Node=current_scene
	await process_frame
	game.set_physics_process(false)
	game.set_process_unhandled_input(false)
	for pose_name in names:
		var p: Array=(POSES[pose_name] as Array).duplicate()
		if pose_name=="driving":
			game.update_traffic(0.016)
			var car=game.cars[4]
			game.enter_car(car)
			game.yaw=atan2(-car.forward().x,-car.forward().z)
			game.pitch=p[4]
			for step in range(120):
				await physics_frame
				game.update_driving(1.0/60.0,Vector2(0,-1))
			var at: Vector3=car.position
			p[0]=at.x
			p[2]=at.z
			p[3]=game.yaw
			print("SHOT driving speed=",car.speed," heading=",car.rotation.y," camera_yaw=",game.yaw)
		if pose_name=="car":
			game.update_traffic(0.016)
			var at: Vector3=game.traffic[int(Time.get_ticks_msec())%3].node.position
			p[0]=at.x+3.0
			p[2]=at.z+4.0
		var ground: float=game.ground(p[0],p[2])
		game.player.position=Vector3(p[0],maxf(ground,0.0)+0.02,p[2])
		game.pivot.position=Vector3(p[0],maxf(ground,0.0)+p[1],p[2])
		game.pivot.rotation=Vector3(p[4],p[3],0)
		game.camera.get_parent().spring_length=p[5]
		game.day_time=p[6]
		game.field_hud.visible=p[7]
		if game.has_method("sync_daylight"): game.sync_daylight(true)
		if game.has_method("sync_view"): game.sync_view()
		# Let culling, MSAA and animated shaders settle, then time a window.
		for i in range(12): await process_frame
		var t0 := Time.get_ticks_usec()
		for i in range(30): await process_frame
		var fps := 30.0/((Time.get_ticks_usec()-t0)/1000000.0)
		var image := root.get_texture().get_image()
		image.save_png(out.path_join(str(pose_name)+".png"))
		print("SHOT %s fps=%.0f draws=%d tris=%d vram_mb=%.0f" % [pose_name,fps,
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED)/1048576.0])
	quit()


