extends Node3D
## Grass, ferns and low plants streamed around the player in small pooled cells.
const CELL := 18.0
const PER_CELL := 64
const BUILDS_PER_FRAME := 2
var world
var material: ShaderMaterial
var radius := 2
var cards: ArrayMesh
var meta := {}
var active := {}
var pool: Array[MultiMeshInstance3D] = []
var centre := Vector2i(1<<20,0)
var pending: Array[Vector2i] = []
var scratch := PackedFloat32Array()

func _ready() -> void:
	name="GroundCover"
	meta=JSON.parse_string(FileAccess.get_file_as_string("res://assets/baked/foliage_meta.json"))
	cards=preload("res://scripts/flora.gd").new().cross_card()
	material=ShaderMaterial.new()
	material.shader=load("res://shaders/foliage.gdshader")
	material.set_shader_parameter("atlas",load("res://assets/baked/foliage_ground.png"))
	material.set_shader_parameter("grid",2.0)
	material.set_shader_parameter("brightness",0.5)
	scratch.resize(PER_CELL*16)

func set_radius(value: int) -> void:
	radius=value
	var reach := (float(radius)+0.5)*CELL
	if material:
		material.set_shader_parameter("near_range",reach)
		material.set_shader_parameter("fade_width",reach*0.3)
	centre=Vector2i(1<<20,0)

func update(view: Vector3) -> void:
	var here := Vector2i(floori(view.x/CELL),floori(view.z/CELL))
	if here!=centre:
		centre=here
		for key in active.keys():
			if maxi(absi(key.x-here.x),absi(key.y-here.y))>radius:
				var node: MultiMeshInstance3D=active[key]
				node.visible=false
				pool.append(node)
				active.erase(key)
		pending.clear()
		for z in range(here.y-radius,here.y+radius+1):
			for x in range(here.x-radius,here.x+radius+1):
				if not active.has(Vector2i(x,z)): pending.append(Vector2i(x,z))
	for i in range(mini(BUILDS_PER_FRAME,pending.size())):
		build_cell(pending.pop_back())

func build_cell(key: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed=hash(key)
	var origin := Vector3(key.x*CELL,0,key.y*CELL)
	var count := 0
	for i in range(PER_CELL):
		var x := origin.x+rng.randf()*CELL
		var z := origin.z+rng.randf()*CELL
		if preload("res://scripts/sunshine_spa.gd").reserved(x,z,0.4): continue
		var kind: int=world.surface_class(x,z)
		var roll := rng.randf()
		var entry: Array
		match kind:
			1:
				entry=["grass",rng.randf_range(0.28,0.55)]
			2:
				entry=["fern",rng.randf_range(0.7,1.5)] if roll<0.5 else (["leafy",rng.randf_range(0.8,1.5)] if roll<0.75 else ["shrub",rng.randf_range(0.6,1.4)])
			3:
				entry=["grass",rng.randf_range(0.5,1.15)]
			_:
				continue
		var info: Dictionary=meta[entry[0]]
		# Authored heights differ: scale to a sensible real size for each species.
		var size: float=info.size/info.height*entry[1]
		var h: float=world.height_at(x,z)
		var yaw := rng.randf()*TAU
		var c := cos(yaw)*size
		var s := sin(yaw)*size
		var at := count*16
		var row := [c,0.0,s,x-origin.x, 0.0,size,0.0,h, -s,0.0,c,z-origin.z, float(info.cell[0]),float(info.cell[1]),rng.randf(),1.0]
		for j in range(16): scratch[at+j]=row[j]
		count+=1
	var node: MultiMeshInstance3D
	if pool.is_empty():
		node=MultiMeshInstance3D.new()
		var mm := MultiMesh.new()
		mm.transform_format=MultiMesh.TRANSFORM_3D
		mm.use_custom_data=true
		mm.mesh=cards
		mm.instance_count=PER_CELL
		node.multimesh=mm
		node.material_override=material
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
	else:
		node=pool.pop_back()
	node.position=origin
	node.visible=true
	node.multimesh.buffer=scratch
	node.multimesh.visible_instance_count=count
	active[key]=node
