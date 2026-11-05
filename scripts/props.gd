extends RefCounted
## Procedural boats and rocks.

var shared := {}

func plain(key: String,color: Color,roughness := 0.8,metal := 0.0) -> StandardMaterial3D:
	if shared.has(key): return shared[key]
	var m := StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=roughness
	m.metallic=metal
	shared[key]=m
	return m

func begin() -> SurfaceTool:
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	return s

## Quad a-b-c-d, wound so its front faces along `out`.
func face(s: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3,out: Vector3) -> void:
	var outward := (c-a).cross(d-b).dot(out)>0.0
	var order := [a,c,b,a,d,c] if outward else [a,b,c,a,c,d]
	s.set_smooth_group(-1)
	for p in order: s.add_vertex(p)

func box(s: SurfaceTool,c: Vector3,size: Vector3) -> void:
	var h := size*0.5
	var p := [Vector3(-h.x,-h.y,-h.z),Vector3(h.x,-h.y,-h.z),Vector3(h.x,h.y,-h.z),Vector3(-h.x,h.y,-h.z),Vector3(-h.x,-h.y,h.z),Vector3(h.x,-h.y,h.z),Vector3(h.x,h.y,h.z),Vector3(-h.x,h.y,h.z)]
	for q in [[4,5,6,7],[1,0,3,2],[5,1,2,6],[0,4,7,3],[7,6,2,3],[0,1,5,4]]:
		face(s,c+p[q[0]],c+p[q[1]],c+p[q[2]],c+p[q[3]],(p[q[0]]+p[q[1]]+p[q[2]]+p[q[3]]))

## A fibreglass island boat with an outboard, or a smaller open wooden dinghy.
func boat(fishing: bool) -> Node3D:
	var root := Node3D.new()
	var length := 6.6 if fishing else 3.6
	var beam := 0.92 if fishing else 0.68
	var depth := 0.74 if fishing else 0.5
	var hull := begin()
	var inner := begin()
	var count := 8
	var last: Array=[]
	for i in range(count+1):
		var t := float(i)/count
		var z := (t-0.42)*length
		var w := beam*pow(sin(clampf(t*0.97+0.13,0.0,1.0)*PI),0.62)
		if t>0.98: w=0.02
		var sheer := depth+pow(maxf(t-0.55,0.0),2.0)*0.9
		var keel := pow(maxf(t-0.72,0.0),2.0)*4.2
		var row := [Vector3(0,keel,z),Vector3(w*0.72,keel+depth*0.26,z),Vector3(w,sheer,z),Vector3(-w*0.72,keel+depth*0.26,z),Vector3(-w,sheer,z)]
		if i>0:
			face(hull,last[0],row[0],row[1],last[1],Vector3(1,-1,0))
			face(hull,last[1],row[1],row[2],last[2],Vector3(1,-0.2,0))
			face(hull,row[0],last[0],last[3],row[3],Vector3(-1,-1,0))
			face(hull,row[3],last[3],last[4],row[4],Vector3(-1,-0.2,0))
			# Bottom boards sit well below the gunwale, so the boat reads as open.
			var drop := Vector3.DOWN*depth*0.5
			face(inner,last[2]+drop*0.9,row[2]+drop*0.9,row[4]+drop*0.9,last[4]+drop*0.9,Vector3.UP)
		last=row
	var mesh := ArrayMesh.new()
	hull.generate_normals()
	inner.generate_normals()
	hull.commit(mesh)
	inner.commit(mesh)
	var node := MeshInstance3D.new()
	node.mesh=mesh
	var skin := StandardMaterial3D.new()
	skin.roughness=0.3 if fishing else 0.8
	skin.albedo_color=Color(0.86,0.87,0.84) if fishing else Color(0.40,0.27,0.17)
	skin.cull_mode=BaseMaterial3D.CULL_DISABLED
	node.set_surface_override_material(0,skin)
	node.set_surface_override_material(1,plain("boat_in",Color(0.20,0.19,0.17),0.9))
	node.visibility_range_end=260.0
	root.add_child(node)
	if fishing:
		var motor := begin()
		box(motor,Vector3(0,0.98,-length*0.42-0.14),Vector3(0.34,0.46,0.42))
		box(motor,Vector3(0,0.42,-length*0.42-0.14),Vector3(0.11,0.72,0.16))
		motor.generate_normals()
		var engine := MeshInstance3D.new()
		engine.mesh=motor.commit()
		engine.material_override=plain("motor",Color(0.05,0.06,0.07),0.4,0.3)
		engine.visibility_range_end=120.0
		root.add_child(engine)
	return root

func rock_mesh() -> ArrayMesh:
	var noise := FastNoiseLite.new()
	noise.seed=9
	noise.frequency=1.3
	noise.fractal_octaves=3
	var s := begin()
	var lats := 5
	var lons := 8
	for la in range(lats):
		for lo in range(lons):
			var quad: Array=[]
			for v in [[la,lo],[la+1,lo],[la,lo+1],[la+1,lo+1]]:
				var theta: float=float(v[0])/lats*PI
				var phi: float=float(v[1]%lons)/lons*TAU
				var dir := Vector3(sin(theta)*cos(phi),cos(theta),sin(theta)*sin(phi))
				var r := 1.0+noise.get_noise_3dv(dir)*0.62
				quad.append({"p":dir*r,"uv":Vector2(float(v[1])/lons*2.0,float(v[0])/lats),"c":Color.WHITE*lerpf(0.55,1.0,clampf(dir.y*0.8+0.5,0,1))})
			for i in [0,2,1,1,2,3]:
				s.set_uv(quad[i].uv)
				s.set_color(quad[i].c)
				s.add_vertex(quad[i].p)
	s.generate_normals()
	s.generate_tangents()
	return s.commit()

