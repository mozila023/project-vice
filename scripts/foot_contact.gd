extends RefCounted
## Match shoe support points to rendered terrain/roads and solid walkable surfaces.
func points(actor: Node3D,ignore_lift := false) -> PackedVector3Array:
	var skeleton: Skeleton3D=actor.get_meta("contact_skeleton") if actor.has_meta("contact_skeleton") else null
	if not is_instance_valid(skeleton):
		skeleton=actor.find_child("Skeleton3D",true,false)
		if skeleton==null: return PackedVector3Array()
		actor.set_meta("contact_skeleton",skeleton)
	var result := PackedVector3Array()
	var scale_y: float=absf(skeleton.global_transform.basis.get_scale().y)
	for side in ["L","R"]:
		for entry in [[" Foot",.096],[" Toe0",.002]]:
			var bone := skeleton.find_bone("Bip01 "+side+entry[0])
			if bone<0: continue
			var at: Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(bone).origin
			at.y-=float(entry[1])*scale_y
			if ignore_lift: at.y-=actor.position.y
			result.append(at)
	return result

func surface(body: CharacterBody3D,at: Vector3,world: Node3D) -> float:
	var height: float=world.surface_height_at(at.x,at.z)
	var query := PhysicsRayQueryParameters3D.create(Vector3(at.x,body.global_position.y+.28,at.z),Vector3(at.x,body.global_position.y-.65,at.z),1,[body.get_rid()])
	var hit := body.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.normal.y>.45: height=maxf(height,hit.position.y)
	return height

func update(body: CharacterBody3D,actor: Node3D,world: Node3D,dt: float,detailed := true) -> void:
	if not body.is_on_floor():
		actor.position.y=move_toward(actor.position.y,0,dt*3)
		return
	var required: float=maxf(0,world.surface_height_at(body.position.x,body.position.z)-body.position.y+.025)
	if detailed:
		for at in points(actor,true): required=maxf(required,surface(body,at,world)-at.y+.025)
	required=clampf(required,0,.6)
	# Raise immediately to avoid penetration; ease downward without rapidly toggling on road edges.
	actor.position.y=required if required>actor.position.y else lerpf(actor.position.y,required,clampf(dt*16,0,1))
