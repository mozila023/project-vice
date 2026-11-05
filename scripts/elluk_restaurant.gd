extends Node3D
## Front elevation follows the three user supplied March 2025 reference photographs.
## MAP_PIN retains the real restaurant location; SITE is the nearby playable plot clear of the road.
const MAP_PIN := Vector2(-570.83226,1116.6267)
const SITE := Vector2(-570.832275390625,1140.62670898438)
const LATITUDE := -17.763097
const LONGITUDE := 168.3091479
const STAIR_TOP := 7.8
const STAIR_END := 14.0
var world: Node3D
var floor_height := 0.0
var stair_count := 0
var stair_end_y := 0.0
var body: StaticBody3D
var cream: StandardMaterial3D
var wood: StandardMaterial3D
var supports: Array[Dictionary] = []

static func reserved(x: float,z: float,margin := 0.0) -> bool:
	return absf(x-SITE.x)<12.0+margin and z-SITE.y<16.0+margin and z-SITE.y> -9.0-margin

func box(label: String,at: Vector3,size: Vector3,material: Material,solid := true) -> void:
	var mesh := BoxMesh.new()
	mesh.size=size
	var instance := MeshInstance3D.new()
	instance.name=label
	instance.mesh=mesh
	instance.material_override=material
	instance.position=at
	instance.visibility_range_end=230
	add_child(instance)
	if solid: collision(at,size)

func collision(at: Vector3,size: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size=size
	shape.shape=bounds
	shape.position=at
	body.add_child(shape)

func beam(label: String,a: Vector3,b: Vector3,width: float,material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size=Vector3(width,width,a.distance_to(b))
	var instance := MeshInstance3D.new()
	instance.name=label
	instance.mesh=mesh
	instance.material_override=material
	instance.transform=Transform3D(Basis.looking_at(b-a,Vector3.UP),(a+b)*.5)
	instance.visibility_range_end=230
	add_child(instance)
	var shape := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size=mesh.size
	shape.shape=bounds
	shape.transform=instance.transform
	body.add_child(shape)

func build() -> void:
	name="PadThaiElluk"
	floor_height=world.surface_height_at(SITE.x,SITE.y)
	var bottom := floor_height
	for x in range(-8,9):
		for z in range(-6,7):
			var h: float=world.surface_height_at(SITE.x+x,SITE.y+z)
			floor_height=maxf(floor_height,h)
			bottom=minf(bottom,h)
	floor_height+=1.1
	position=Vector3(SITE.x,floor_height,SITE.y)
	cream=StandardMaterial3D.new()
	cream.albedo_color=Color("dcded0")
	cream.roughness=.85
	wood=StandardMaterial3D.new()
	wood.albedo_color=Color("774334")
	wood.albedo_texture=load("res://assets/environment/weathered_planks_Diffuse.jpg")
	wood.uv1_triplanar=true
	wood.uv1_scale=Vector3.ONE*.8
	wood.roughness=.9
	var room: Node3D=load("res://assets/models/island_refined/elluk_restaurant.glb").instantiate()
	add_child(room)
	for mesh: MeshInstance3D in room.find_children("*","MeshInstance3D",true,false): mesh.visibility_range_end=230
	body=StaticBody3D.new()
	body.name="RestaurantCollision"
	body.collision_layer=1
	add_child(body)
	var boxes: Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/island_refined/elluk_colliders.json"))
	for entry: Dictionary in boxes: collision(Vector3(entry.center[0],entry.center[1],entry.center[2]),Vector3(entry.size[0],entry.size[1],entry.size[2]))
	# Raised enclosed foundation reaches soil on all sides, including the downhill side.
	var low: float=bottom-floor_height-.25
	box("RaisedFoundation",Vector3(0,(low-.4)*.5,0),Vector3(16,-.4-low,12),cream)
	var sign: Node3D=room.find_child("RoadsideSign",true,false)
	if sign:
		var at := sign.global_position
		at.y=world.surface_height_at(at.x,at.z)+.02
		sign.global_position=at
		collision(to_local(at)+Vector3(0,1.75,0),Vector3(3.3,1.42,.10))
		for x in [-1.3,1.3]: collision(to_local(at)+Vector3(x,1.0,-.05),Vector3(.1,2.0,.1))
	build_stairs()
	build_garden()
	batch_details()

func build_garden() -> void:
	var green := StandardMaterial3D.new()
	green.albedo_color=Color("5a7639")
	green.cull_mode=BaseMaterial3D.CULL_DISABLED
	green.roughness=.9
	for side in [-1,1]:
		for i in range(6):
			var x: float=side*(2.3+i*.9)
			var z: float=8.4+sin(i*2.1)*.4
			var base := Vector3(x,world.surface_height_at(SITE.x+x,SITE.y+z)-floor_height,z)
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			for leaf in range(11):
				var angle: float=leaf*TAU/11+i
				var direction := Vector3(cos(angle),0,sin(angle))
				var lateral := Vector3(-direction.z,0,direction.x)
				var height: float=.65+float(leaf%3)*.18
				for section in range(3):
					var a := float(section)/3
					var b := float(section+1)/3
					var start := base+direction*a*.78+Vector3.UP*sin(a*1.9)*height
					var end := base+direction*b*.78+Vector3.UP*sin(b*1.9)*height
					var wa := lateral*(.055*(1-a)+.008)
					var wb := lateral*(.055*(1-b)+.001)
					for vertex in [start-wa,start+wa,end+wb,start-wa,end+wb,end-wb]: surface.add_vertex(vertex)
			surface.generate_normals()
			var plant := MeshInstance3D.new()
			plant.mesh=surface.commit()
			plant.material_override=green
			add_child(plant)

func batch_details() -> void:
	var batches := {}
	for node in get_children():
		if not node is MeshInstance3D: continue
		var material: Material=node.material_override
		if not batches.has(material):
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			batches[material]=surface
		batches[material].append_from(node.mesh,0,node.transform)
		remove_child(node)
		node.queue_free()
	for material: Material in batches:
		var node := MeshInstance3D.new()
		node.name="EntranceDetails"
		node.mesh=batches[material].commit()
		node.material_override=material
		node.visibility_range_end=230
		add_child(node)

func build_stairs() -> void:
	stair_end_y=world.surface_height_at(SITE.x,SITE.y+STAIR_END)-floor_height+.025
	stair_count=maxi(4,ceili(-stair_end_y/.17))
	var run: float=(STAIR_END-STAIR_TOP)/stair_count
	for i in range(stair_count):
		var t := float(i)/stair_count
		var y := lerpf(.035,stair_end_y,t)
		var z := STAIR_TOP+(i+.5)*run
		box("TimberTread",Vector3(0,y-.04,z),Vector3(2.2,.08,run+.025),wood,false)
	for side in [-1,1]:
		var x: float=side*1.15
		beam("StairStringer",Vector3(x,-.12,STAIR_TOP),Vector3(x,stair_end_y-.12,STAIR_END),.14,wood)
		beam("TimberHandrail",Vector3(x,1.05,STAIR_TOP),Vector3(x,stair_end_y+1.05,STAIR_END),.10,wood)
		var count := ceili((STAIR_END-STAIR_TOP)/.19)
		for i in range(count+1):
			var t := float(i)/count
			var y := lerpf(0,stair_end_y,t)
			box("StairBaluster",Vector3(x,y+.49,lerpf(STAIR_TOP,STAIR_END,t)),Vector3(.045,.98,.045),wood,false)
		for z in [STAIR_TOP,STAIR_END]:
			var y: float=0.0 if z==STAIR_TOP else stair_end_y
			var ground: float=world.surface_height_at(SITE.x+x,SITE.y+z)-floor_height-.15
			box("StairSupportPost",Vector3(x,(ground+y+1.05)*.5,z),Vector3(.13,y+1.05-ground,.13),wood)
			supports.append({"x":x,"z":z,"bottom":ground})
	# A continuous collision surface matches the tread tops, so feet do not snag on risers.
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=PackedVector3Array([Vector3(-1.1,.035,STAIR_TOP),Vector3(1.1,.035,STAIR_TOP),Vector3(-1.1,stair_end_y,STAIR_END+.05),Vector3(1.1,stair_end_y,STAIR_END+.05)])
	arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,2,1,3,2])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var shape := CollisionShape3D.new()
	shape.name="WalkableStairSlope"
	shape.shape=mesh.create_trimesh_shape()
	body.add_child(shape)
