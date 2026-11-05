extends Node3D
## Blender architectural pieces stay local to each building; placements share real floor/collision heights.
var game: Node3D
var kit: Node3D
var materials=preload("res://scripts/coastal_materials.gd").new()
func build(owner_game: Node3D) -> void:
	game=owner_game
	kit=load("res://assets/models/coastal_detail/detail_kit.glb").instantiate()
	for building in [game.sunshine,game.restaurant,game.landmarks.port,game.landmarks.bar]: materials.polish(building)
	# Sunshine forecourt and facade. Keep its front door and Luna's start free.
	var spa_offset: Vector3=game.sunshine.SHELL_OFFSET
	for at in [Vector3(-5,0,5.8),Vector3(7.5,0,5.8)]: ground_piece("planter",game.sunshine.to_global(at+spa_offset))
	for x in [-6.0,6.0]: piece("lantern",game.sunshine,Vector3(x,2.2,4.36)+spa_offset)
	# Fix the condenser to the opaque rear wall, away from the glazed side elevation.
	piece("ac_unit",game.sunshine,Vector3(4.5,1.8,-4.54)+spa_offset,PI)
	piece("gutter",game.sunshine,Vector3(4,3.3,4.65)+spa_offset)
	# Raised restaurant: timber rails and stairs remain untouched and fully walkable.
	for x in [-6,6]:
		piece("lantern",game.restaurant,Vector3(x,2.1,6.15))
		piece("gutter",game.restaurant,Vector3(x,3.1,6.3))
		ground_piece("planter",game.restaurant.position+Vector3(x,0,14.8))
	piece("ac_unit",game.restaurant,Vector3(8.15,1.6,-3),PI/2)
	# Port office frontage, drains and mooring edge details outside the quest-crate aisle.
	for x in [-20,-10,0,10,20]: piece("drain",game.landmarks.port,Vector3(x,.025,14.7))
	for z in [-10,-4,3,10]: piece("bollard",game.landmarks.port,Vector3(-23,.02,z))
	piece("ac_unit",game.landmarks.port,Vector3(20.6,2.1,5),PI/2)
	for x in [11.5,18.5]: piece("lantern",game.landmarks.port,Vector3(x,2.3,9.7))
	var scanned=preload("res://scripts/real_prop_assets.gd")
	scanned.place("covered_car",game.landmarks.port,Vector3(-4,0,-5))
	scanned.place("overhead_crane",game.landmarks.port,Vector3(-16,4.7,12),0,false)
	for at in [Vector3(-16,0,-10),Vector3(-16,2.4,-10),Vector3(-16,0,-4),Vector3(-16,0,2),Vector3(-9,0,-9)]:
		var cargo: Node3D=scanned.place("shipping_container",game.landmarks.port,at,PI/2)
		cargo.scale.x=2.45/3.0
	for at in [Vector3(12,0,11.5),Vector3(12.7,0,11.5)]: scanned.place("industrial_container",game.landmarks.port,at)
	add_harbor_boats()
	kit.free()
func add_harbor_boats() -> void:
	var chosen: Array[Vector3]=[]
	for kind in ["speedboat","tugboat","cargo_ship"]:
		var found := false
		for radius in [40,65,90,125,165,210]:
			if found: break
			for i in range(24):
				var angle := TAU*i/24
				var at: Vector3=game.landmarks.port.position+Vector3(cos(angle)*radius,0,sin(angle)*radius)
				var clear := true
				for previous in chosen:
					if previous.distance_to(at)<38: clear=false
				for x in [-15,0,15]:
					for z in [-15,0,15]:
						if game.world.surface_height_at(at.x+x,at.z+z)>-2.5: clear=false
				if not clear: continue
				at.y=-.45 if kind=="speedboat" else -1.2
				var boat: Node3D=preload("res://scripts/real_prop_assets.gd").place(kind,game,at,PI/4,false)
				boat.name="Harbor_"+kind
				for mesh in boat.find_children("*","MeshInstance3D",true,false):
					mesh.visibility_range_end=650
					mesh.create_trimesh_collision()
				chosen.append(at); found=true; break
func piece(kind: String,parent: Node3D,at: Vector3,yaw := 0.0) -> Node3D:
	var source: Node3D=kit.find_child(kind,true,false)
	if source==null: return null
	var node: Node3D=source.duplicate()
	node.name="Detail_"+kind
	parent.add_child(node,true)
	node.position=at
	node.rotation.y=yaw
	materials.polish(node)
	if kind=="gutter": extend_downpipe(node)
	for mesh in node.find_children("*","MeshInstance3D",true,false): mesh.visibility_range_end=90
	if kind in ["planter","bench","bollard"]:
		var body := StaticBody3D.new()
		node.add_child(body)
		var collision := CollisionShape3D.new()
		if kind in ["planter","bollard"]:
			collision.shape=CylinderShape3D.new()
			collision.shape.radius=.39 if kind=="planter" else .11
			collision.shape.height=.72 if kind=="planter" else .9
			collision.position.y=collision.shape.height/2
		else:
			collision.shape=BoxShape3D.new()
			collision.shape.size=Vector3(1.8,1.05,.6)
			collision.position.y=.525
		body.add_child(collision)
	return node
func extend_downpipe(node: Node3D) -> void:
	var start := node.to_global(Vector3(1,-2.7,0))
	var height: float=game.world.surface_height_at(start.x,start.z)+.02
	if start.y<=height+.02: return
	var end := node.to_local(Vector3(start.x,height,start.z))
	var mesh := MeshInstance3D.new()
	mesh.name="GroundedDownpipe"
	mesh.mesh=CylinderMesh.new()
	mesh.mesh.top_radius=.045; mesh.mesh.bottom_radius=.045
	mesh.mesh.height=-2.7-end.y
	mesh.position=Vector3(1,(-2.7+end.y)/2,0)
	mesh.material_override=materials.material("steel",Color("29332f"))
	mesh.visibility_range_end=90
	node.add_child(mesh)
func ground_piece(kind: String,at: Vector3) -> void:
	at.y=game.world.surface_height_at(at.x,at.z)+.015
	piece(kind,game,at)
