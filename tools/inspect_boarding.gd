extends SceneTree
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	change_scene_to_file("res://scenes/front_end.tscn")
	while current_scene==null or current_scene.get("view")==null: await process_frame
	var front=current_scene
	front.set_process(false)
	front.view.visible=false
	print("AIRCRAFT BOUNDS ",front.bounds(front.plane))
	for mesh: MeshInstance3D in front.plane.find_children("*","MeshInstance3D",true,false):
		print("AIRCRAFT MESH ",mesh.name," transform=",mesh.global_transform," bounds=",mesh.get_aabb())
		if String(mesh.name)!="Mesh": continue
		for uv in [Vector2(0.503,0.706),Vector2(0.503,0.731),Vector2(0.503,0.748),Vector2(0.503,0.269),Vector2(0.503,0.294),Vector2(0.503,0.904),Vector2(0.503,0.095)]:
			for s in range(mesh.mesh.get_surface_count()):
				var arrays: Array=mesh.mesh.surface_get_arrays(s)
				var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
				var uvs: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
				var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
				for i in range(0,indices.size(),3):
					var ia: int=indices[i]
					var ib: int=indices[i+1]
					var ic: int=indices[i+2]
					var edge0: Vector2=uvs[ib]-uvs[ia]
					var edge1: Vector2=uvs[ic]-uvs[ia]
					var delta: Vector2=uv-uvs[ia]
					var det: float=edge0.cross(edge1)
					if absf(det)<0.0000001: continue
					var beta: float=delta.cross(edge1)/det
					var gamma: float=edge0.cross(delta)/det
					if beta>=0 and gamma>=0 and beta+gamma<=1:
						var at: Vector3=mesh.global_transform*(vertices[ia]*(1-beta-gamma)+vertices[ib]*beta+vertices[ic]*gamma)
						print("DOOR UV ",uv," position=",at)
						var marker := MeshInstance3D.new()
						var sphere := SphereMesh.new()
						sphere.radius=0.05
						sphere.height=0.1
						marker.mesh=sphere
						marker.material_override=front.material(Color.YELLOW)
						front.add_child(marker)
						marker.global_position=at
						var label := Label3D.new()
						label.text=str(uv.y)
						label.font_size=28
						label.pixel_size=0.006
						label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
						front.add_child(label)
						label.global_position=at+Vector3(0.8,0,0)
	var args := OS.get_cmdline_user_args()
	var out: String=args[0] if args.size()>0 else "res://checks/boarding-inspect"
	DirAccess.make_dir_recursive_absolute(out)
	front.screen="intro"
	front.set_intro_pose(0)
	front.traveler.visible=false
	front.camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	front.camera.size=10
	for side in [1.0,-1.0]:
		front.camera.position=Vector3(0,3,side*28)
		front.camera.look_at(Vector3(0,2.5,0))
		for i in range(6): await process_frame
		root.get_texture().get_image().save_png(out.path_join("side_"+str(int(side))+".png"))
	front.camera.position=Vector3(0,30,0)
	front.camera.look_at(Vector3.ZERO,Vector3.FORWARD)
	for i in range(6): await process_frame
	root.get_texture().get_image().save_png(out.path_join("top.png"))
	quit()
