extends RefCounted
## Blender-derived per-component proxies. Keep openings between furniture and shelter posts.
var definitions: Dictionary

func _init() -> void:
	definitions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/island_refined/prop_physics.json"))

func add(root: Node3D,kind: String,skip_names: Array = []) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name="PropCollision_"+kind
	body.collision_layer=1
	body.collision_mask=0
	root.add_child(body)
	for box in definitions[kind].boxes:
		if box.name in skip_names: continue
		var shape := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size=Vector3(box.size[0],box.size[1],box.size[2])
		shape.shape=bounds
		shape.position=Vector3(box.center[0],box.center[1],box.center[2])
		body.add_child(shape)
	return body

func ground_on(root: Node3D,kind: String,world: Node3D) -> void:
	var low: Array=definitions[kind].min
	root.position.y=world.surface_height_at(root.position.x,root.position.z)-float(low[1])+0.008
