extends SceneTree
## Consolidates the CC0 sedan's small parts into material batches and four wheel pivots.
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var source: Node3D=load("res://assets/models/vehicles/sedan.glb").instantiate()
	root.add_child(source)
	var result := Node3D.new()
	result.name="RoadCar"
	var batches := {}
	var wheels := {}
	for front in [true,false]:
		for left in [true,false]:
			var key: String=("front" if front else "back")+"-"+("left" if left else "right")
			var wheel := Node3D.new()
			wheel.name="wheel-"+key
			wheel.position=Vector3(0.93 if left else -0.93,0.33,1.36 if front else -1.36)
			result.add_child(wheel)
			wheel.owner=result
			wheels[key]=wheel
	for node: MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
		var label: String=String(node.name).to_lower()
		var is_wheel: bool=(label.begins_with("front_") or label.begins_with("rear_"))
		var parent: Node3D=result
		if is_wheel:
			var front: bool=label.begins_with("front_")
			var center: Vector3=node.global_transform*node.get_aabb().get_center()
			parent=wheels[("front" if front else "back")+"-"+("left" if center.x>0 else "right")]
		for s in range(node.mesh.get_surface_count()):
			var mat: Material=node.get_active_material(s)
			var key: String=String(parent.name)+"/"+mat.resource_name
			if not batches.has(key): batches[key]={"surface":SurfaceTool.new(),"parent":parent,"mat":mat}
			var transform: Transform3D=node.global_transform
			transform.origin-=parent.position if is_wheel else Vector3.ZERO
			batches[key].surface.append_from(node.mesh,s,transform)
	for key in batches:
		var batch: Dictionary=batches[key]
		var mesh := MeshInstance3D.new()
		mesh.name=key.get_file()
		mesh.mesh=batch.surface.commit()
		mesh.material_override=batch.mat
		batch.parent.add_child(mesh)
		mesh.owner=result
	var packed := PackedScene.new()
	packed.pack(result)
	ResourceSaver.save(packed,"res://assets/models/vehicles/road_car.scn")
	print("SEDAN batched parts=",batches.size())
	result.free()
	source.free()
	quit()
