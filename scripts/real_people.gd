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
	var hold_key: String=kind+"holding-both"
	if not clips.has(hold_key): clips[hold_key]=holding_pose(clips[kind+"idle"])
	library.add_animation("holding-both",clips[hold_key])
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
	ground_feet(animation,target)
	animation.loop_mode=Animation.LOOP_LINEAR
	source.free()
	return animation

func bone_origin(target: Skeleton3D,idx: int) -> Vector3:
	var t := Transform3D.IDENTITY
	var cur := idx
	while cur>=0:
		t=target.get_bone_pose(cur)*t
		cur=target.get_bone_parent(cur)
	return t.origin

## Rebuilds the root pelvis vertical curve from the leg rotations so the supporting foot
## stays planted at y=0 throughout every stride instead of pedalling in mid-air.
func ground_feet(animation: Animation,target: Skeleton3D) -> void:
	var root_idx: int=target.find_bone("Bip01")
	var l_foot: int=target.find_bone("Bip01 L Foot")
	var l_toe: int=target.find_bone("Bip01 L Toe0")
	var r_foot: int=target.find_bone("Bip01 R Foot")
	var r_toe: int=target.find_bone("Bip01 R Toe0")
	if root_idx<0 or l_foot<0 or l_toe<0 or r_foot<0 or r_toe<0: return
	var rest_origin: Vector3=target.get_bone_rest(root_idx).origin
	var mapped: Array[Dictionary]=[]
	for track in range(animation.get_track_count()):
		if animation.track_get_type(track)!=Animation.TYPE_ROTATION_3D: continue
		var bone: String=String(animation.track_get_path(track).get_subname(0))
		var idx: int=target.find_bone(bone)
		if idx>=0: mapped.append({"track":track,"bone":idx})
	var pos_track: int=animation.add_track(Animation.TYPE_POSITION_3D)
	animation.track_set_path(pos_track,NodePath("Skeleton3D:Bip01"))
	var samples := 24
	for i in range(samples+1):
		var t: float=animation.length*float(i)/float(samples)
		target.set_bone_pose_position(root_idx,rest_origin)
		for entry in mapped:
			target.set_bone_pose_rotation(entry.bone,animation.rotation_track_interpolate(entry.track,t))
		var ly: float=minf(bone_origin(target,l_toe).y-0.002,bone_origin(target,l_foot).y-0.096)
		var ry: float=minf(bone_origin(target,r_toe).y-0.002,bone_origin(target,r_foot).y-0.096)
		var support: float=minf(ly,ry)
		animation.position_track_insert_key(pos_track,t,rest_origin-Vector3(0,support+0.008,0))
	target.reset_bone_poses()

## Two-handed fishing stance derived from the avatar's idle clip.
func holding_pose(idle_clip: Animation) -> Animation:
	var clip: Animation=idle_clip.duplicate(true)
	var overrides := {
		"Bip01 R UpperArm":Quaternion.from_euler(Vector3(-0.35,-0.10,-0.48)),
		"Bip01 L UpperArm":Quaternion.from_euler(Vector3(0.35,0.10,-0.44)),
	}
	var direct := {
		"Bip01 R Forearm":Quaternion(0,0,-0.64,0.768).normalized(),
		"Bip01 L Forearm":Quaternion(0,0,-0.58,0.815).normalized(),
	}
	for track in range(clip.get_track_count()):
		if clip.track_get_type(track)!=Animation.TYPE_ROTATION_3D: continue
		var bone: String=String(clip.track_get_path(track).get_subname(0))
		if overrides.has(bone):
			var delta: Quaternion=overrides[bone]
			for k in range(clip.track_get_key_count(track)):
				var base_q: Quaternion=clip.track_get_key_value(track,k)
				clip.track_set_key_value(track,k,(base_q*delta).normalized())
		elif direct.has(bone):
			var target_q: Quaternion=direct[bone]
			for k in range(clip.track_get_key_count(track)):
				clip.track_set_key_value(track,k,target_q)
	return clip
