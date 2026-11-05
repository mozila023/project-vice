extends Node3D
## One measured doorway anchors the stairs, landing, passenger path and camera.
## UV is on the lower edge of the aft passenger-door marking on Cesium Air.
const DOOR_UV := Vector2(0.503,0.687)
const WIDTH := 0.82
const RUN := 0.28
const LANDING := 0.60
const APPROACH_END := 1.5
const CLIMB_END := 5.5
const LANDING_END := 6.6
var door := Vector3.ZERO
var entry := Vector3.ZERO
var first_step := Vector3.ZERO
var last_step := Vector3.ZERO
var approach := Vector3.ZERO
var step_count := 0
var rise := 0.0

func build(aircraft: Node3D) -> void:
	door=point_at_uv(aircraft,DOOR_UV)
	assert(door.is_finite(),"The aircraft's aft door UV must exist")
	step_count=maxi(1,ceili(door.y/0.18))
	rise=door.y/step_count
	entry=door+Vector3(0,0,-0.55)
	var base_z: float=entry.z-LANDING*0.5-step_count*RUN
	first_step=Vector3(door.x,rise,base_z+RUN*0.5)
	last_step=Vector3(door.x,door.y,base_z+(step_count-0.5)*RUN)
	approach=Vector3(door.x,0.0,base_z-1.15)
	var metal := surface(Color("707d80"),0.48,0.45)
	var tread := surface(Color("343f43"),0.94)
	var rail := surface(Color("bdc4c1"),0.4,0.6)
	for i in range(step_count):
		var at := Vector3(door.x,(i+1)*rise,base_z+(i+0.5)*RUN)
		box("Tread_%02d"%i,at-Vector3.UP*0.022,Vector3(WIDTH,0.044,RUN+0.02),metal)
		box("Grip_%02d"%i,at+Vector3.UP*0.003,Vector3(WIDTH-0.08,0.006,RUN-0.055),tread)
		box("Nosing_%02d"%i,at+Vector3(0,0.007,-RUN*0.43),Vector3(WIDTH-0.03,0.008,0.025),surface(Color("c2b47f"),0.75))
	box("Landing",entry-Vector3.UP*0.025,Vector3(WIDTH+0.06,0.05,LANDING),metal)
	box("LandingGrip",entry+Vector3.UP*0.003,Vector3(WIDTH-0.04,0.006,LANDING-0.06),tread)
	for side in [-1.0,1.0]:
		var x: float=door.x+side*(WIDTH*0.5-0.04)
		beam("Stringer",Vector3(x,0.06,base_z),Vector3(x,door.y-0.05,entry.z-LANDING*0.5),0.055,0.10,metal)
		beam("Handrail",Vector3(x,0.87,base_z),Vector3(x,door.y+0.87,entry.z-LANDING*0.5),0.035,0.035,rail)
		beam("MidRail",Vector3(x,0.46,base_z),Vector3(x,door.y+0.46,entry.z-LANDING*0.5),0.024,0.024,rail)
		beam("LandingRail",Vector3(x,door.y+0.87,entry.z-LANDING*0.5),Vector3(x,door.y+0.87,entry.z+LANDING*0.4),0.035,0.035,rail)
		beam("LandingMidRail",Vector3(x,door.y+0.46,entry.z-LANDING*0.5),Vector3(x,door.y+0.46,entry.z+LANDING*0.4),0.024,0.024,rail)
		for i in [0,step_count/2,step_count-1]:
			var at := Vector3(x,(i+1)*rise,base_z+(i+0.5)*RUN)
			beam("RailPost",at,at+Vector3.UP*0.87,0.03,0.03,rail)
		beam("LandingSupport",Vector3(x,0.025,entry.z),Vector3(x,door.y-0.025,entry.z),0.055,0.055,metal)
		beam("DiagBrace",Vector3(x,0.12,base_z+0.35),Vector3(x,door.y-0.08,entry.z),0.032,0.032,metal)
		box("FootPad",Vector3(x,0.02,base_z),Vector3(0.18,0.04,0.3),tread)
		box("CasterWheel",Vector3(x,0.08,entry.z),Vector3(0.08,0.16,0.16),tread)
		box("SafetyBumper",Vector3(x,door.y,entry.z+LANDING*0.48),Vector3(0.12,0.09,0.09),surface(Color("d6a228"),0.55))
	# A visible open doorway, sized for the human cast. The shot cuts on the
	# landing before the actor crosses the exterior shell into the separate cabin.
	var opening := MeshInstance3D.new()
	var portal := QuadMesh.new()
	portal.size=Vector2(0.84,1.82)
	portal.material=surface(Color("111b21"),1)
	opening.mesh=portal
	opening.rotation.y=PI
	opening.position=door+Vector3(0,0.91,-0.23)
	opening.name="OpenDoorway"
	add_child(opening)
	for side in [-1.0,1.0]:
		box("DoorJamb",door+Vector3(side*0.44,0.91,-0.26),Vector3(0.045,1.86,0.065),rail)
	box("DoorHeader",door+Vector3(0,1.84,-0.26),Vector3(0.91,0.045,0.065),rail)
	box("Threshold",door+Vector3(0,-0.025,-0.34),Vector3(0.91,0.05,0.28),metal)
	var leaf := Node3D.new()
	leaf.name="OpenDoorLeaf"
	leaf.position=door+Vector3(0.44,0.91,-0.28)
	leaf.rotation.y=-PI*0.5
	add_child(leaf)
	var panel := MeshInstance3D.new()
	var panel_mesh := BoxMesh.new()
	panel_mesh.size=Vector3(0.83,1.79,0.04)
	panel_mesh.material=surface(Color("c7c9bf"),0.62)
	panel.mesh=panel_mesh
	panel.position.x=-0.415
	leaf.add_child(panel)

func surface(color: Color,roughness: float,metallic := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color=color
	material.roughness=roughness
	material.metallic=metallic
	return material

func box(label: String,at: Vector3,size: Vector3,mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name=label
	var mesh := BoxMesh.new()
	mesh.size=size
	mesh.material=mat
	node.mesh=mesh
	node.position=at
	add_child(node)
	return node

func beam(label: String,a: Vector3,b: Vector3,width: float,height: float,mat: Material) -> void:
	var node := box(label,(a+b)*0.5,Vector3(width,height,a.distance_to(b)),mat)
	node.look_at(b,Vector3.UP if absf((b-a).normalized().dot(Vector3.UP))<0.99 else Vector3.RIGHT)

func pose(at: float) -> Dictionary:
	var position: Vector3
	var clip := "walk"
	var animation_time: float=at*0.78
	if at<APPROACH_END:
		var u: float=clampf(at/APPROACH_END,0,1)
		position=approach.lerp(first_step,u)
		position.y=rise*smoothstep(0.78,1.0,u)
	elif at<CLIMB_END:
		position=first_step.lerp(last_step,(at-APPROACH_END)/(CLIMB_END-APPROACH_END))
	elif at<LANDING_END:
		position=last_step.lerp(entry,(at-CLIMB_END)/(LANDING_END-CLIMB_END))
	else:
		position=entry
		clip="idle"
		animation_time=at-LANDING_END
	return {"position":position,"yaw":0.0,"clip":clip,"animation_time":animation_time}

func camera_pose(at: float) -> Dictionary:
	var u: float=smoothstep(0.0,LANDING_END,at)
	return {
		"position":door+Vector3(-7.1,2.1,-10.2).lerp(Vector3(-4.3,1.65,-6.5),u),
		"target":door+Vector3(0.45,0.85,-0.9)
	}

func point_at_uv(aircraft: Node3D,uv: Vector2) -> Vector3:
	for node: MeshInstance3D in aircraft.find_children("*","MeshInstance3D",true,false):
		if String(node.name)!="Mesh": continue
		for s in range(node.mesh.get_surface_count()):
			var arrays: Array=node.mesh.surface_get_arrays(s)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var uvs: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			for i in range(0,indices.size(),3):
				var a: int=indices[i]
				var b: int=indices[i+1]
				var c: int=indices[i+2]
				var edge0: Vector2=uvs[b]-uvs[a]
				var edge1: Vector2=uvs[c]-uvs[a]
				var delta: Vector2=uv-uvs[a]
				var det: float=edge0.cross(edge1)
				if absf(det)<0.0000001: continue
				var beta: float=delta.cross(edge1)/det
				var gamma: float=edge0.cross(delta)/det
				if beta>=0 and gamma>=0 and beta+gamma<=1:
					return to_local(node.global_transform*(vertices[a]*(1-beta-gamma)+vertices[b]*beta+vertices[c]*gamma))
	return Vector3.INF
