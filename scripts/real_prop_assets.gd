extends RefCounted
## Scanned props retain their photographic materials and exact grounded bounds.
static func place(kind: String,parent: Node3D,at: Vector3,yaw := 0.0,solid := true) -> Node3D:
	var node: Node3D=load("res://assets/models/real_props/"+kind+".glb").instantiate()
	node.name="Scanned_"+kind
	parent.add_child(node,true)
	node.position=at
	node.rotation.y=yaw
	for mesh in node.find_children("*","MeshInstance3D",true,false): mesh.visibility_range_end=140
	if solid:
		var info: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/real_props/asset_info.json"))[kind]
		var body := StaticBody3D.new()
		node.add_child(body)
		var shape := CollisionShape3D.new()
		shape.shape=BoxShape3D.new()
		shape.shape.size=Vector3(info.size[0],info.size[1],info.size[2])
		shape.position=Vector3((info.min[0]+info.max[0])/2,(info.min[1]+info.max[1])/2,(info.min[2]+info.max[2])/2)
		body.add_child(shape)
	return node
