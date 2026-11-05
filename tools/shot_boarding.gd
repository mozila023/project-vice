extends SceneTree
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String=args[0] if args.size()>0 else "res://checks/boarding-visual"
	DirAccess.make_dir_recursive_absolute(out)
	change_scene_to_file("res://scenes/front_end.tscn")
	while current_scene==null or current_scene.get("view")==null: await process_frame
	var front=current_scene
	front.set_process(false)
	front.screen="intro"
	var animation: AnimationPlayer=front.traveler.find_child("AnimationPlayer",true,false)
	animation.speed_scale=0
	print("BOARDING aircraft=",front.bounds(front.plane)," door=",front.boarding.door," steps=",front.boarding.step_count," rise=",front.boarding.rise," width=",front.boarding.WIDTH)
	for at in [0.0,1.5,2.2,3.5,4.8,5.5,6.6,7.4]:
		front.set_intro_pose(at)
		for i in range(8): await process_frame
		root.get_texture().get_image().save_png(out.path_join("boarding_"+str(at).replace(".","_")+".png"))
		print("BOARDING SHOT t=",at," actor=",front.traveler.position," yaw=",front.traveler.rotation.y)
	quit()
