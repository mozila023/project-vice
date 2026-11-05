extends RefCounted
## Microsoft Rocketbox MIT avatars, with compact textures and shared retargeted clips.
const TYPES := ["Female_Adult_08","Male_Adult_01","Female_Adult_01","Male_Adult_12"]
var scenes := {}
var clips := {}
var fabrics := {}

func create(index: int,height := 1.75) -> Node3D:
	var kind: String=TYPES[index%TYPES.size()]
	if not scenes.has(kind): scenes[kind]=load("res://assets/models/people/"+kind+".fbx")
	var actor: Node3D=scenes[kind].instantiate()
	actor.set_meta("real_person",true)
	var skeleton: Skeleton3D=actor.find_child("Skeleton3D",true,false)
	var player: AnimationPlayer=actor.find_child("AnimationPlayer",true,false)
	if player:
		for name in player.get_animation_library_list(): player.remove_animation_library(name)
	else:
		player=AnimationPlayer.new()
		player.name="AnimationPlayer"
		actor.add_child(player)
	var library := AnimationLibrary.new()
	var gender := "f" if kind.begins_with("Female") else "m"
	for name in ["idle","walk"]:
		var key: String=kind+name
		if not clips.has(key): clips[key]=retarget(gender,name,skeleton)
		library.add_animation(name,clips[key])
	library.add_animation("sprint",clips[kind+"walk"])
	library.add_animation("holding-both",clips[kind+"idle"])
	player.add_animation_library("",library)
	player.play("idle")
	var bounds := AABB()
	var found := false
	for mesh: MeshInstance3D in actor.find_children("*","MeshInstance3D",true,false):
		mesh.visibility_range_end=95
		var transform := Transform3D.IDENTITY
		var cursor: Node3D=mesh
		while cursor!=actor:
			transform=cursor.transform*transform
			cursor=cursor.get_parent()
		var box: AABB=transform*mesh.get_aabb()
		bounds=bounds.merge(box) if found else box
		found=true
		for s in range(mesh.mesh.get_surface_count()):
			var source=mesh.get_active_material(s)
			if not source is StandardMaterial3D: continue
			var slot: String=source.resource_name
			var texture_path: String="res://assets/models/people/"+slot+"_color.png"
			if not ResourceLoader.exists(texture_path): continue
			if not fabrics.has(slot):
				var mat := StandardMaterial3D.new()
				mat.resource_name=slot
				mat.albedo_texture=load(texture_path)
				mat.roughness=0.9 if slot.ends_with("body") else 0.7
				mat.metallic_specular=0.2
				mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				if slot.ends_with("opacity"):
					mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
					mat.alpha_scissor_threshold=0.4
					mat.cull_mode=BaseMaterial3D.CULL_DISABLED
				fabrics[slot]=mat
			mesh.set_surface_override_material(s,fabrics[slot])
	# Bounds are transformed from the FBX's Z-up mesh into the imported scene's Y-up space.
	var full_height: float=maxf(bounds.size.y,bounds.size.z)
	if full_height>0.1: actor.scale=Vector3.ONE*(height/full_height)
	return actor

func retarget(gender: String,name: String,target: Skeleton3D) -> Animation:
	var filename: String=gender+("_walk_neutral.max.fbx" if name=="walk" else "_idle_breathe_01.max.fbx")
	var source: Node=load("res://assets/models/people/"+filename).instantiate()
	var skeleton: Skeleton3D=source.find_child("Skeleton3D",true,false)
	var player: AnimationPlayer=source.find_child("AnimationPlayer",true,false)
	var animation: Animation=player.get_animation("Take 001").duplicate(true)
	for track in range(animation.get_track_count()-1,-1,-1):
		var path: NodePath=animation.track_get_path(track)
		var bone: String=String(path.get_subname(0)) if path.get_subname_count()>0 else ""
		var dst: int=target.find_bone(bone)
		var src: int=skeleton.find_bone(bone)
		if dst<0 or src<0 or animation.track_get_type(track)!=Animation.TYPE_ROTATION_3D:
			animation.remove_track(track)
			continue
		animation.track_set_path(track,NodePath("Skeleton3D:"+bone))
		for key in range(animation.track_get_key_count(track)):
			var value: Quaternion=animation.track_get_key_value(track,key)
			animation.track_set_key_value(track,key,value.normalized())
	animation.loop_mode=Animation.LOOP_LINEAR
	source.free()
	return animation
