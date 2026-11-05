extends RefCounted
## Procedural vehicles, boats and rocks with believable proportions and physically based paint.

const KINDS := {
	# Stations rear to front: [z, sill, shoulder, top, half_width, top_half_width, side_glass, top_glass]
	"sedan": {"stations":[
		[-2.25,0.42,0.82,0.86,0.80,0.74,false,false],[-2.05,0.34,0.90,0.97,0.87,0.80,false,false],
		[-1.55,0.30,0.92,1.02,0.89,0.80,false,false],[-1.30,0.30,0.93,1.03,0.89,0.78,false,true],
		[-0.75,0.30,0.93,1.40,0.89,0.66,true,false],[0.0,0.30,0.93,1.43,0.89,0.66,true,false],
		[0.45,0.30,0.93,1.38,0.89,0.68,false,true],[1.10,0.30,0.92,1.00,0.89,0.76,false,false],
		[1.85,0.34,0.84,0.87,0.86,0.76,false,false],[2.20,0.44,0.72,0.76,0.78,0.68,false,false]],
		"wheel_z":[-1.35,1.32],"wheel_r":0.32,"track":0.80},
	"van": {"stations":[
		[-2.45,0.40,1.15,1.20,0.90,0.86,false,false],[-2.38,0.36,1.15,1.98,0.94,0.82,true,false],
		[-1.2,0.34,1.15,2.05,0.95,0.82,true,false],[0.2,0.34,1.15,2.06,0.95,0.82,true,false],
		[1.1,0.34,1.15,2.02,0.95,0.82,false,true],[1.80,0.34,1.12,1.22,0.95,0.84,false,false],
		[2.25,0.38,0.98,1.02,0.90,0.80,false,false],[2.42,0.48,0.76,0.82,0.82,0.72,false,false]],
		"wheel_z":[-1.45,1.42],"wheel_r":0.33,"track":0.84},
	"truck": {"stations":[
		[-2.55,0.56,1.06,1.10,0.86,0.84,false,false],[-2.50,0.52,1.08,1.12,0.90,0.88,false,false],
		[-0.62,0.52,1.08,1.12,0.90,0.88,false,false],[-0.60,0.50,1.10,1.80,0.90,0.74,false,false],
		[-0.40,0.50,1.10,1.84,0.90,0.74,true,false],[0.45,0.50,1.10,1.84,0.90,0.74,true,false],
		[0.92,0.50,1.10,1.78,0.90,0.76,false,true],[1.45,0.50,1.10,1.20,0.90,0.80,false,false],
		[2.15,0.54,1.02,1.08,0.88,0.78,false,false],[2.48,0.62,0.86,0.92,0.80,0.72,false,false]],
		"wheel_z":[-1.55,1.45],"wheel_r":0.37,"track":0.82},
}

var shared := {}

func paint_material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color=color
	m.metallic=0.45
	m.roughness=0.28
	m.metallic_specular=0.6
	return m

func plain(key: String,color: Color,roughness := 0.8,metal := 0.0) -> StandardMaterial3D:
	if shared.has(key): return shared[key]
	var m := StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=roughness
	m.metallic=metal
	shared[key]=m
	return m

func vehicle(kind: String,color: Color) -> Node3D:
	var root := Node3D.new()
	root.name=kind.capitalize()
	var spec: Dictionary=KINDS[kind]
	var cache_key := "mesh_"+kind
	if not shared.has(cache_key): shared[cache_key]=vehicle_body(spec)
	var body := MeshInstance3D.new()
	body.mesh=shared[cache_key]
	body.set_surface_override_material(0,paint_material(color))
	body.set_surface_override_material(1,plain("glass",Color(0.035,0.055,0.065),0.06,0.2))
	body.set_surface_override_material(2,plain("trim",Color(0.03,0.03,0.032),0.65))
	body.set_surface_override_material(3,plain("lamp",Color(0.9,0.92,0.86),0.15,0.3))
	body.set_surface_override_material(4,plain("tail",Color(0.55,0.04,0.03),0.2))
	body.visibility_range_end=240.0
	root.add_child(body)
	var tyre_key := "tyre_%.2f" % spec.wheel_r
	if not shared.has(tyre_key): shared[tyre_key]=wheel_mesh(spec.wheel_r)
	for z in spec.wheel_z:
		for side in [-1.0,1.0]:
			var pivot := Node3D.new()
			pivot.name="wheel_%d_%d" % [int(z*10),int(side)]
			pivot.position=Vector3(side*(st_width(spec)-0.05),spec.wheel_r,z)
			var wheel := MeshInstance3D.new()
			wheel.mesh=shared[tyre_key]
			wheel.set_surface_override_material(0,plain("tyre",Color(0.025,0.025,0.027),0.9))
			wheel.set_surface_override_material(1,plain("rim",Color(0.62,0.63,0.62),0.35,0.75))
			wheel.rotation.z=PI/2
			wheel.scale=Vector3(side,1,1)
			wheel.visibility_range_end=140.0
			pivot.add_child(wheel)
			root.add_child(pivot)
	return root

func st_width(spec: Dictionary) -> float:
	return spec.stations[2][4]

func vehicle_body(spec: Dictionary) -> ArrayMesh:
	var paint := begin()
	var glass := begin()
	var trim := begin()
	var lamp := begin()
	var tail := begin()
	var st: Array=spec.stations
	for i in range(st.size()-1):
		var a: Array=st[i]
		var b: Array=st[i+1]
		for side in [-1.0,1.0]:
			var ring_a := section(a,side)
			var ring_b := section(b,side)
			# Rocker, door, then the window line. Glass where the station calls for it.
			face(trim,ring_a[0],ring_b[0],ring_b[1],ring_a[1],Vector3(side,-0.2,0))
			face(paint,ring_a[1],ring_b[1],ring_b[2],ring_a[2],Vector3(side,0,0))
			face(glass if a[6] else paint,ring_a[2],ring_b[2],ring_b[3],ring_a[3],Vector3(side,0.3,0))
		var top_a := [Vector3(-a[5],a[3],a[0]),Vector3(a[5],a[3],a[0])]
		var top_b := [Vector3(-b[5],b[3],b[0]),Vector3(b[5],b[3],b[0])]
		face(glass if a[7] else paint,top_a[0],top_a[1],top_b[1],top_b[0],Vector3.UP)
		face(trim,Vector3(-a[4]*0.95,a[1],a[0]),Vector3(-b[4]*0.95,b[1],b[0]),Vector3(b[4]*0.95,b[1],b[0]),Vector3(a[4]*0.95,a[1],a[0]),Vector3.DOWN)
	# Dark wheel wells, so tyres read against the body instead of through it.
	for z in spec.wheel_z:
		for side in [-1.0,1.0]:
			box(trim,Vector3(side*st[2][4],spec.wheel_r+0.08,z),Vector3(0.03,spec.wheel_r*2.0+0.2,spec.wheel_r*2.5))
	# Close the nose and the tail.
	cap(paint,st[0],false)
	cap(paint,st[st.size()-1],true)
	var f: Array=st[st.size()-1]
	var r: Array=st[0]
	var fz: float=f[0]+0.012
	var rz: float=r[0]-0.012
	var mid: float=lerpf(f[1],f[2],0.62)
	var rm: float=lerpf(r[1],r[2],0.72)
	for side in [-1.0,1.0]:
		var x: float=side*f[4]*0.62
		face(lamp,Vector3(x-0.17,mid-0.08,fz),Vector3(x+0.17,mid-0.08,fz),Vector3(x+0.17,mid+0.08,fz),Vector3(x-0.17,mid+0.08,fz),Vector3.BACK)
		var rx: float=side*r[4]*0.72
		face(tail,Vector3(rx+0.13,rm-0.07,rz),Vector3(rx-0.13,rm-0.07,rz),Vector3(rx-0.13,rm+0.07,rz),Vector3(rx+0.13,rm+0.07,rz),Vector3.FORWARD)
	# Bumpers and grille.
	box(trim,Vector3(0,f[1]+0.05,fz+0.04),Vector3(f[4]*2.0,0.17,0.14))
	box(trim,Vector3(0,r[1]+0.05,rz-0.04),Vector3(r[4]*2.0,0.17,0.14))
	face(trim,Vector3(-0.36,mid-0.11,fz+0.004),Vector3(0.36,mid-0.11,fz+0.004),Vector3(0.36,mid+0.1,fz+0.004),Vector3(-0.36,mid+0.1,fz+0.004),Vector3.BACK)
	var mesh := ArrayMesh.new()
	for s in [paint,glass,trim,lamp,tail]:
		s.generate_normals()
		s.commit(mesh)
	return mesh

func section(row: Array,side: float) -> Array:
	var w: float=row[4]*side
	var tw: float=row[5]*side
	return [Vector3(w*0.95,row[1],row[0]),Vector3(w,row[1]+0.14,row[0]),Vector3(w,row[2],row[0]),Vector3(tw,row[3],row[0])]

func cap(s: SurfaceTool,row: Array,front: bool) -> void:
	var l := section(row,-1.0)
	var r := section(row,1.0)
	for i in range(3):
		face(s,l[i],r[i],r[i+1],l[i+1],Vector3.BACK if front else Vector3.FORWARD)

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

func wheel_mesh(radius: float) -> ArrayMesh:
	var tyre := begin()
	var rim := begin()
	var sides := 14
	var half := 0.11
	for i in range(sides):
		var a0 := i*TAU/sides
		var a1 := (i+1)*TAU/sides
		var o0 := Vector3(cos(a0),0,sin(a0))
		var o1 := Vector3(cos(a1),0,sin(a1))
		face(tyre,o0*radius+Vector3.DOWN*half,o1*radius+Vector3.DOWN*half,o1*radius+Vector3.UP*half,o0*radius+Vector3.UP*half,o0)
		for y in [-half,half]:
			var at := Vector3(0,y,0)
			face(tyre,o0*radius*0.64+at,o1*radius*0.64+at,o1*radius+at,o0*radius+at,Vector3.UP*y)
			var hub := Vector3(0,y*0.8,0)
			var ring: Vector3=o0*radius*0.64+at
			var ring2: Vector3=o1*radius*0.64+at
			face(rim,hub,hub,ring2,ring,Vector3.UP*y)
	var mesh := ArrayMesh.new()
	tyre.generate_normals()
	rim.generate_normals()
	tyre.commit(mesh)
	rim.commit(mesh)
	return mesh

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

