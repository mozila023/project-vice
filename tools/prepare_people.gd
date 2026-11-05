extends SceneTree

func _initialize() -> void:
	for avatar in ["Female_Adult_01","Female_Adult_08","Male_Adult_01","Male_Adult_12"]:
		var folder: String="res://tools/.cache/rocketbox/"+avatar
		for name in DirAccess.get_files_at(folder):
			if not name.ends_with(".tga"): continue
			var image := Image.load_from_file(folder.path_join(name))
			if image==null: continue
			image.resize(1024 if "body" in name else 512,1024 if "body" in name else 512,Image.INTERPOLATE_LANCZOS)
			image.save_png("res://assets/models/people/"+name.replace(".tga",".png"))
			print("PEOPLE TEXTURE ",name," ",image.get_size())
	quit()
