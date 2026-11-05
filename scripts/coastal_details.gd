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
	for at in [Vector3(-5,0,6.4),Vector3(5,0,6.4)]: ground_piece("planter",game.sunshine.position+at)
	for x in [-5.6,5.5]: piece("lantern",game.sunshine,Vector3(x,2.2,4.6))
	piece("ac_unit",game.sunshine,Vector3(6.5,2,-1),PI/2)
	piece("gutter",game.sunshine,Vector3(4,3.3,4.6))
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
	kit.free()
func piece(kind: String,parent: Node3D,at: Vector3,yaw := 0.0) -> Node3D:
	var source: Node3D=kit.find_child(kind,true,false)
	if source==null: return null
	var node: Node3D=source.duplicate()
	parent.add_child(node)
	node.position=at
	node.rotation.y=yaw
	materials.polish(node)
	for mesh in node.find_children("*","MeshInstance3D",true,false): mesh.visibility_range_end=90
	if kind in ["planter","bench","bollard"]:
		var body := StaticBody3D.new()
		node.add_child(body)
		var collision := CollisionShape3D.new()
		collision.shape=BoxShape3D.new()
		collision.shape.size=Vector3(.7,1.2,.7) if kind=="planter" else Vector3(.25,.9,.25)
		collision.position.y=collision.shape.size.y/2
		body.add_child(collision)
	return node
func ground_piece(kind: String,at: Vector3) -> void:
	at.y=game.world.surface_height_at(at.x,at.z)+.015
	piece(kind,game,at)
