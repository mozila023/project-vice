extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String=args[0] if args.size()>0 else "res://checks/front-visual"
	DirAccess.make_dir_recursive_absolute(out)
	change_scene_to_file("res://scenes/front_end.tscn")
	while current_scene==null or current_scene.get("view")==null: await process_frame
	var front=current_scene
	front.set_process(false)
	for pose in ["menu","settings"]:
		front.screen="menu" if pose=="menu" else ("settings" if pose=="settings" else "intro")
		for i in range(15): await process_frame
		root.get_texture().get_image().save_png(out.path_join(pose+".png"))
		print("FRONT SHOT ",pose)
	quit()
