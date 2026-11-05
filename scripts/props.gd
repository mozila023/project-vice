extends RefCounted
## Blender-authored island boats and volcanic/coral rocks.

var shared := {}
var boat_cache := {}
var rock_cached: ArrayMesh

func plain(key: String,color: Color,roughness := 0.8,metal := 0.0) -> StandardMaterial3D:
	if shared.has(key): return shared[key]
	var m := StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=roughness
	m.metallic=metal
	shared[key]=m
	return m

## A fibreglass island boat with an outboard, or a smaller open wooden dinghy, sculpted in Blender.
func boat(fishing: bool) -> Node3D:
	var path := "res://assets/models/watercraft/boat_fishing.glb" if fishing else "res://assets/models/watercraft/boat_row.glb"
	if not boat_cache.has(path):
		boat_cache[path]=load(path)
	var root: Node3D=boat_cache[path].instantiate()
	for mesh: MeshInstance3D in root.find_children("*","MeshInstance3D",true,false):
		mesh.visibility_range_end=260.0
	return root

func rock_mesh() -> ArrayMesh:
	if rock_cached!=null:
		return rock_cached
	var scene: PackedScene=load("res://assets/models/props/rock_boulder.glb")
	if scene!=null:
		var inst: Node3D=scene.instantiate()
		for mesh: MeshInstance3D in inst.find_children("*","MeshInstance3D",true,false):
			if mesh.mesh is ArrayMesh:
				rock_cached=mesh.mesh
				break
		inst.free()
	if rock_cached!=null:
		return rock_cached
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	s.add_vertex(Vector3.ZERO)
	s.add_vertex(Vector3.RIGHT)
	s.add_vertex(Vector3.UP)
	rock_cached=s.commit()
	return rock_cached


