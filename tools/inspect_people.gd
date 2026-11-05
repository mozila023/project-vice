extends SceneTree
func _initialize() -> void:
	for file in ["Female_Adult_01.fbx","Male_Adult_12.fbx","m_walk_neutral.max.fbx"]:
		var node: Node=load("res://assets/models/people/"+file).instantiate()
		root.add_child(node)
		print("PEOPLE FILE ",file)
		for skeleton: Skeleton3D in node.find_children("*","Skeleton3D",true,false):
			print("SKELETON ",node.get_path_to(skeleton)," count=",skeleton.get_bone_count()," root=",skeleton.get_bone_name(0)," rest=",skeleton.get_bone_rest(0))
		for mesh: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
			print("MESH ",mesh.name," ",mesh.get_aabb())
			for surface in range(mesh.mesh.get_surface_count()):
				var mat=mesh.get_active_material(surface)
				print("MAT ",surface," ",mat.resource_name if mat else "NULL")
		for player: AnimationPlayer in node.find_children("*","AnimationPlayer",true,false):
			print("ANIMS ",player.get_animation_list()," root=",player.root_node)
			for name in player.get_animation_list():
				var clip: Animation=player.get_animation(name)
				if name!="RESET":
					print("CLIP ",name," length=",clip.length," count=",clip.get_track_count())
					for track in range(mini(6,clip.get_track_count())): print("TRACK ",clip.track_get_path(track)," ",clip.track_get_type(track))
					for track in range(clip.get_track_count()):
						if "L UpperArm" in String(clip.track_get_path(track)) or "R UpperArm" in String(clip.track_get_path(track)):
							print("ARM ",clip.track_get_path(track)," value=",clip.track_get_key_value(track,0))
		node.free()
	quit()
