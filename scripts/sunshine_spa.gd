extends Node3D
## MAP_PIN is the verified business location. SITE stages the model clear of the compressed road network.
## Interior follows the site's salon photograph; frontage follows the Google Maps
## exterior photo. Unseen elevations/dimensions are interpreted. See SUNSHINE_SPA.md.
const MAP_PIN := Vector2(-447.56486,882.01488)
const SITE := Vector2(-495.564849853516,854.014892578125)
const ADDRESS := "785C+68 · Seaside · Port Vila · Vanuatu"
const TITLE := "Sunshine Wellness & Spa"
const SPAWN := SITE+Vector2(-5.3,-7.8)
var world: Node3D
var batches := {}
var materials := {}
var body: StaticBody3D
var floor_height := 0.0
const SHELL_OFFSET := Vector3(-1,0,-2)
var offset := SHELL_OFFSET

static func reserved(x: float,z: float,margin := 0.0) -> bool:
	return absf(x-SITE.x)<10.0+margin and absf(z-SITE.y)<8.5+margin

func paint(key: String,color: String,roughness := 0.7) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color=Color(color)
	m.roughness=roughness
	materials[key]=m
	return m

func box(key: String,at: Vector3,size: Vector3,solid := false) -> void:
	at+=offset
	var mesh := BoxMesh.new()
	mesh.size=size
	append(key,mesh,Transform3D(Basis.IDENTITY,at))
	if solid:
		var shape := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size=size
		shape.shape=bounds
		shape.position=at
		body.add_child(shape)

func append(key: String,mesh: Mesh,transform: Transform3D) -> void:
	if not batches.has(key):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		batches[key]=surface
	batches[key].append_from(mesh,0,transform)

func cylinder(key: String,at: Vector3,radius: float,height: float) -> void:
	at+=offset
	var mesh := CylinderMesh.new()
	mesh.top_radius=radius
	mesh.bottom_radius=radius
	mesh.height=height
	mesh.radial_segments=12
	append(key,mesh,Transform3D(Basis.IDENTITY,at))

func label(value: String,at: Vector3,size: int,pixel: float,color: Color) -> void:
	var text := Label3D.new()
	text.text=value
	text.font=load("res://assets/fonts/NotoSansThai.ttf")
	text.font_size=size
	text.pixel_size=pixel
	text.modulate=color
	text.outline_size=0
	text.position=at+offset
	text.no_depth_test=false
	text.visibility_range_end=90
	add_child(text)

func build() -> void:
	name="SunshineWellnessSpa"
	offset=SHELL_OFFSET
	var lowest := INF
	floor_height=-INF
	var facing := Basis(Vector3.UP,PI)
	for x in range(14):
		for z in range(10):
			var sample: Vector3=facing*(Vector3(-6.2+x*12.4/13,0,-4.45+z*8.9/9)+SHELL_OFFSET)
			var ground: float=world.surface_height_at(SITE.x+sample.x,SITE.y+sample.z)
			floor_height=maxf(floor_height,ground)
			lowest=minf(lowest,ground)
	floor_height+=0.12
	position=Vector3(SITE.x,floor_height,SITE.y)
	rotation.y=PI
	paint("plaster","eee9df")
	paint("tile","e2d9c6",0.45)
	paint("grout","a79e8d")
	paint("frame","d1d2cd",0.35)
	paint("steel","252b2b",0.45)
	paint("wood","b68d5d")
	paint("cream","f7f0e2")
	paint("blue","153d60")
	paint("gold","d0ac63",0.45)
	paint("green","42664d")
	paint("roof","757e78")
	paint("pink","d5839b")
	paint("red","ae3943")
	paint("violet","735d8c")
	for entry in [["plaster","clean_plaster"],["wood","clean_planks"],["roof","worn_corrugated_iron"]]:
		var m: StandardMaterial3D=materials[entry[0]]
		m.albedo_texture=load("res://assets/environment/"+entry[1]+"_Diffuse.jpg")
		m.uv1_triplanar=true
		m.uv1_scale=Vector3.ONE*0.5
	var glass := paint("glass","b1cfcb",0.15)
	glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	glass.albedo_color.a=0.13
	glass.cull_mode=BaseMaterial3D.CULL_DISABLED
	body=StaticBody3D.new()
	body.name="WalkableSalon"
	body.collision_layer=1
	add_child(body)
	var foundation_depth: float=maxf(1.7,floor_height-lowest+.35)
	box("plaster",Vector3(0,-foundation_depth/2-.03,0),Vector3(12.4,foundation_depth,8.9),true)
	box("tile",Vector3(0,-0.015,0),Vector3(12,0.03,8.5),true)
	# Fine grout, cream tiles and aluminium window frames visible in the reference.
	for x in range(-6,7): box("grout",Vector3(x,0.004,0),Vector3(0.008,0.003,8.5))
	for z in range(-4,5): box("grout",Vector3(0,0.004,z),Vector3(12,0.003,0.008))
	box("plaster",Vector3(0,1.6,-4.25),Vector3(12.3,3.2,0.18),true)
	box("plaster",Vector3(-6,1.6,0),Vector3(0.18,3.2,8.5),true)
	box("plaster",Vector3(6,0.42,0),Vector3(0.18,0.84,8.5),true)
	box("glass",Vector3(6,1.93,0),Vector3(0.04,2.14,8.5),true)
	for z in [-4.2,-2.1,0,2.1,4.2]: box("frame",Vector3(6,1.94,z),Vector3(0.1,2.2,0.06))
	# Front door is a real 2m opening with continuous walkable threshold.
	for x in [-3.55,3.55]:
		box("glass",Vector3(x,1.42,4.25),Vector3(4.9,2.76,0.035),true)
		box("frame",Vector3(x,0.08,4.25),Vector3(4.9,0.07,0.09))
		box("frame",Vector3(x,2.78,4.25),Vector3(4.9,0.07,0.09))
	for x in [-6.0,-3.6,-1.05,1.05,3.6,6.0]: box("frame",Vector3(x,1.42,4.25),Vector3(0.075,2.85,0.09))
	box("plaster",Vector3(0,3.04,4.25),Vector3(12.3,0.42,0.2))
	box("roof",Vector3(0,3.32,0),Vector3(12.9,0.18,9.3),true)
	box("cream",Vector3(0,2.88,5.0),Vector3(12.8,0.1,1.6))
	for x in [-6.1,6.1]: box("frame",Vector3(x,0.93,5.55),Vector3(0.09,3.85,0.09),true)
	box("cream",Vector3(0,3.02,4.39),Vector3(7.0,0.66,0.06))
	label(TITLE,Vector3(0,3.06,4.435),64,0.003,Color("a7803c"))
	label("THAI MASSAGE · NAIL · SPA",Vector3(0,2.84,4.435),32,0.003,Color("516e56"))
	box("blue",Vector3(4.9,1.65,4.3),Vector3(1.7,1.4,0.05))
	label("SUNSHINE\nWelcome / ยินดีต้อนรับ\nPort Vila · Seaside",Vector3(4.9,1.67,4.34),30,0.0034,Color("f0d8a4"))
	# Furniture follows the photographed nail salon: sculpted in Blender (black steel, pale timber, cream seating).
	var furn_scene: PackedScene=load("res://assets/models/island_refined/spa_grounded.glb")
	if furn_scene!=null:
		var furn: Node3D=furn_scene.instantiate()
		furn.name="SpaBlenderFurniture"
		add_child(furn)
		for m: MeshInstance3D in furn.find_children("*","MeshInstance3D",true,false):
			m.visibility_range_end=180
		preload("res://scripts/prop_physics.gd").new().add(furn,"spa_furniture",["SpaPlanterPots"])
		for pot: Node3D in furn.find_children("GroundedPlanter*","Node3D",true,false):
			var at := pot.global_position
			var indoors: bool=pot.position.z<2.3
			at.y=(floor_height if indoors else world.surface_height_at(at.x,at.z))+0.008
			pot.global_position=at
			var collision := StaticBody3D.new()
			collision.collision_layer=1
			pot.add_child(collision)
			var shape := CollisionShape3D.new()
			var cylinder := CylinderShape3D.new()
			cylinder.radius=0.245
			cylinder.height=0.44
			shape.shape=cylinder
			shape.position.y=0.22
			collision.add_child(shape)
	for x in [-4.7,-2.8]: collider_only(Vector3(x,0.26,2.9),Vector3(1.35,0.5,0.4))
	for z in [-1.5,1.25]:
		collider_only(Vector3(3.5,0.76,z),Vector3(1.65,0.07,0.7))
		for cz in [-0.9,0.9]: collider_only(Vector3(3.5,0.46,z+cz),Vector3(0.6,0.12,0.52))
	collider_only(Vector3(-3.8,0.52,-2.8),Vector3(3.6,1.04,0.75))
	label("Sunshine\nWellness & Spa",Vector3(-3.8,2.0,-4.13),48,0.004,Color("a7803c"))
	# Back treatment corner is a gameplay interpretation, not a claim about the real floor plan.
	box("cream",Vector3(0,1.28,-2.85),Vector3(0.08,2.56,2.7),true)
	collider_only(Vector3(2.6,0.6,-2.9),Vector3(2.0,0.12,0.8))
	build_ramp()
	offset=Vector3.ZERO
	build_frontage()
	for key in batches:
		var node := MeshInstance3D.new()
		node.name=key.capitalize()+"Batch"
		node.mesh=batches[key].commit()
		node.material_override=materials[key]
		node.visibility_range_end=220
		add_child(node)
	batches.clear()

func collider_only(at: Vector3,size: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size=size
	shape.shape=bounds
	shape.position=at+offset
	body.add_child(shape)

func build_ramp() -> void:
	# The game compresses Efate 1:20; keep this doorway at human scale and bridge the grade.
	box("tile",Vector3(0,-0.015,4.45),Vector3(2.1,0.03,0.5),true)
	var end := Vector3(0,0,5.6)+offset
	var world_end: Vector3=transform*end
	end.y=world.height_at(world_end.x,world_end.z)-floor_height+0.025
	box("plaster",Vector3(0,end.y*0.5-0.45,4.95),Vector3(2.08,absf(end.y)+0.85,1.25),false)
	var vertices := PackedVector3Array([Vector3(-1.05,0,4.65)+offset,Vector3(1.05,0,4.65)+offset,end+Vector3(-1.05,0,0),end+Vector3(1.05,0,0)])
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=PackedVector3Array([Vector3.UP,Vector3.UP,Vector3.UP,Vector3.UP])
	arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,2,1,3,2])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	append("tile",mesh,Transform3D.IDENTITY)
	var shape := CollisionShape3D.new()
	shape.shape=mesh.create_trimesh_shape()
	body.add_child(shape)

func build_frontage() -> void:
	# Observed frontage: white rendered boundary, right-hand two-track driveway,
	# horizontal timber screen and a tall shade tree in front of a low glazed salon.
	for entry in [[-2.75,12.5],[8.1,2.2]]:
		box("plaster",Vector3(entry[0],0.025,6.5),Vector3(entry[1],2.8,0.22),true)
	for x in [-9.0,3.5,7.0,9.2]:
		box("plaster",Vector3(x,0.275,6.5),Vector3(0.36,3.3,0.36),true)
		box("cream",Vector3(x,1.96,6.5),Vector3(0.48,0.09,0.48))
	# Entry narrows visually along the screen; the 3.1m gap stays fully passable.
	box("plaster",Vector3(3.5,-0.16,5.3),Vector3(0.18,1.88,2.4),true)
	for y in range(7): box("wood",Vector3(3.5,0.87+y*0.125,5.3),Vector3(0.07,0.105,2.4),true)
	box("cream",Vector3(3.5,1.84,5.7),Vector3(0.13,0.48,1.4))
	# Rotate the entrance sign to face the street, as seen in the reference.
	box("cream",Vector3(2.0,1.56,6.65),Vector3(2.3,0.55,0.055))
	label("MASSAGE",Vector3(2.0,1.57,6.69),48,0.006,Color("a63c35"))
	box("green",Vector3(-1.5,0.82,6.66),Vector3(3.5,1.55,0.055))
	label("Sunshine\nWellness & Spa\nTHAI MASSAGE · NAIL\n785C+68 · Port Vila",Vector3(-1.5,0.85,6.71),40,0.005,Color("f5e5b2"))
	for x in [4.15,6.35]:
		# Ground-hugging wheel tracks do not introduce an invisible step at the gate.
		var plane := PlaneMesh.new()
		plane.size=Vector2(0.72,8.6)
		var at := Vector3(x,0,4.1)
		at.y=world.height_at((transform*at).x,(transform*at).z)-floor_height+0.035
		append("grout",plane,Transform3D(Basis.IDENTITY,at))
	# Existing atlas keeps the added shade tree cheap on mobile. Its species is approximate.
	var tree_world: Vector3=transform*Vector3(-3.8,0,4.0)
	var tree_y: float=world.height_at(tree_world.x,tree_world.z)-floor_height-0.08
	var tree := MeshInstance3D.new()
	tree.name="FrontShadeTree"
	tree.mesh=preload("res://scripts/flora.gd").new().cross_card()
	tree.material_override=world.card_near
	tree.position=Vector3(-3.8,tree_y,4.0)
	tree.scale=Vector3(11,12,11)
	add_child(tree)
	# Trunk collision is separate from the alpha cards and outside the door/driveway.
	var trunk := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius=0.22
	shape.height=4.8
	trunk.shape=shape
	trunk.position=Vector3(-3.8,tree_y+2.4,4.0)
	body.add_child(trunk)
