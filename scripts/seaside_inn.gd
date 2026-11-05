extends Node3D
## Fictional playable inn near Sunshine; not a claim about a real hotel business.
const SITE := Vector2(-199,506)
const TITLE := "Seaside Inn"
const ENTRANCE := Vector2(-199,513.5)
var world: Node3D
var floor_height := 0.0
var bed_point := Vector3.ZERO
var rest_point := Vector3.ZERO
var body: StaticBody3D
var batches := {}
var materials := {}

static func reserved(x: float,z: float,margin := 0.0) -> bool:
	return absf(x-SITE.x)<8+margin and absf(z-SITE.y)<10+margin

func paint(key: String,color: String) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color=Color(color)
	material.roughness=.85
	materials[key]=material

func box(key: String,at: Vector3,size: Vector3,solid := false,basis := Basis.IDENTITY) -> void:
	var mesh := BoxMesh.new()
	mesh.size=size
	if not batches.has(key):
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		batches[key]=tool
	batches[key].append_from(mesh,0,Transform3D(basis,at))
	if solid:
		var shape := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size=size
		shape.shape=bounds
		shape.transform=Transform3D(basis,at)
		body.add_child(shape)

func build() -> void:
	name="SeasideInn"
	var lowest := INF
	floor_height=-INF
	for x in range(-6,7):
		for z in range(-4,5):
			var h: float=world.surface_height_at(SITE.x+x,SITE.y+z)
			floor_height=maxf(floor_height,h)
			lowest=minf(lowest,h)
	floor_height+=.15
	position=Vector3(SITE.x,floor_height,SITE.y)
	for entry in [["cream","e8e0cc"],["wood","7e5134"],["roof","985e48"],["linen","eee9df"],["teal","386b70"],["glass","354e58"]]: paint(entry[0],entry[1])
	for entry in [["cream","clean_plaster"],["wood","weathered_planks"],["roof","worn_corrugated_iron"]]:
		materials[entry[0]].albedo_texture=load("res://assets/environment/"+entry[1]+"_Diffuse.jpg")
		materials[entry[0]].uv1_triplanar=true
		materials[entry[0]].uv1_scale=Vector3.ONE*.45
	body=StaticBody3D.new()
	body.name="InnCollision"
	body.collision_layer=1
	add_child(body)
	var bottom: float=lowest-floor_height-.2
	box("cream",Vector3(0,bottom*.5,0),Vector3(12,-bottom,8),true)
	box("wood",Vector3(0,.025,0),Vector3(12,.05,8),true)
	box("cream",Vector3(0,1.55,-4),Vector3(12,3.1,.16),true)
	for x in [-6,6]: box("cream",Vector3(x,1.55,0),Vector3(.16,3.1,8),true)
	for x in [-3.6,3.6]: box("cream",Vector3(x,1.55,4),Vector3(4.8,3.1,.16),true)
	box("cream",Vector3(0,2.9,4),Vector3(2.4,.4,.16),true)
	for side in [-1,1]:
		box("roof",Vector3(0,3.45,side*2.15),Vector3(12.8,.13,4.55),false,Basis(Vector3.RIGHT,side*.18))
		box("cream",Vector3(0,3.04,side*4.4),Vector3(12.8,.18,.10))
	box("roof",Vector3(0,3.86,0),Vector3(12.8,.10,.18))
	for side in [-1,1]:
		var gable := ArrayMesh.new()
		var shape := []
		shape.resize(Mesh.ARRAY_MAX)
		shape[Mesh.ARRAY_VERTEX]=PackedVector3Array([Vector3(side*6,3.1,-4),Vector3(side*6,3.1,4),Vector3(side*6,3.85,0)])
		shape[Mesh.ARRAY_NORMAL]=PackedVector3Array([Vector3.RIGHT*side,Vector3.RIGHT*side,Vector3.RIGHT*side])
		shape[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,2,2,1,0])
		gable.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,shape)
		batches.cream.append_from(gable,0,Transform3D.IDENTITY)
	box("cream",Vector3(0,3.1,0),Vector3(12,.12,8))
	for x in [-3.5,3.5]:
		box("wood",Vector3(x,1.65,4.1),Vector3(1.8,1.3,.08))
		box("glass",Vector3(x,1.65,4.15),Vector3(1.6,1.1,.035))
	box("teal",Vector3(0,2.95,4.17),Vector3(5,.6,.08))
	var sign := Label3D.new()
	sign.text="SEASIDE INN  ·  ROOMS"
	sign.position=Vector3(0,2.95,4.23)
	sign.font_size=72
	sign.pixel_size=.004
	sign.outline_size=0
	add_child(sign)
	# Reception on the left; a real, reachable bed on the right.
	box("wood",Vector3(-3,.55,1.8),Vector3(2.5,1.1,.7),true)
	box("teal",Vector3(-3,1.13,1.8),Vector3(2.7,.08,.85),true)
	box("wood",Vector3(3,.23,-1.5),Vector3(2.1,.46,2.8),true)
	box("linen",Vector3(3,.53,-1.5),Vector3(2,.18,2.7),true)
	box("teal",Vector3(3,.64,-.8),Vector3(2,.04,1.25))
	for x in [2.5,3.5]: box("linen",Vector3(x,.69,-2.35),Vector3(.72,.12,.45))
	box("wood",Vector3(3,.8,-2.95),Vector3(2.15,1.1,.12),true)
	bed_point=position+Vector3(3,0,-1.5)
	rest_point=position+Vector3(1.3,.1,-1.0)
	var end_y: float=world.surface_height_at(ENTRANCE.x,ENTRANCE.y)-floor_height+.03
	var ramp := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=PackedVector3Array([Vector3(-1.18,.05,3.95),Vector3(1.18,.05,3.95),Vector3(-1.18,end_y,7.5),Vector3(1.18,end_y,7.5)])
	arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,2,1,3,2])
	arrays[Mesh.ARRAY_NORMAL]=PackedVector3Array([Vector3.UP,Vector3.UP,Vector3.UP,Vector3.UP])
	ramp.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var slope := MeshInstance3D.new()
	slope.mesh=ramp
	slope.material_override=materials.wood
	add_child(slope)
	var collision := CollisionShape3D.new()
	collision.shape=ramp.create_trimesh_shape()
	body.add_child(collision)
	for key in batches:
		var mesh := MeshInstance3D.new()
		mesh.mesh=batches[key].commit()
		mesh.material_override=materials[key]
		mesh.visibility_range_end=250
		add_child(mesh)
	batches.clear()
	var light := OmniLight3D.new()
	light.position=Vector3(0,2.5,0)
	light.light_color=Color("ffd9a6")
	light.omni_range=10
	light.shadow_enabled=false
	light.distance_fade_enabled=true
	light.distance_fade_begin=55
	light.distance_fade_length=30
	add_child(light)
	world.night_listeners.append(func(_level: float): light.light_energy=world.settlement_night()*2.0)

func contains(at: Vector3) -> bool:
	return absf(at.x-SITE.x)<6.4 and absf(at.z-SITE.y)<4.8 and absf(at.y-floor_height)<1.0
