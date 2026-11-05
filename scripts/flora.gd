extends RefCounted
## Plant meshes. All built with vertex colour for baked shading, and a soft outward normal
## so cards light as a rounded volume instead of a flat sheet.

const SEGMENTS := 5

## Slender curved coconut palm: surface 0 trunk, surface 1 fronds.
func palm_mesh() -> ArrayMesh:
	var trunk := SurfaceTool.new()
	trunk.begin(Mesh.PRIMITIVE_TRIANGLES)
	var height := 11.0
	var sides := 6
	var rings := 5
	var ring_pts: Array=[]
	for r in range(rings+1):
		var t := float(r)/rings
		var y := t*height
		var lean := t*t*1.5
		var radius := lerpf(0.21,0.11,pow(t,0.7))+0.13*pow(maxf(0.0,1.0-t*7.0),2.0)
		ring_pts.append([Vector3(lean,y,0),radius,t])
	for r in range(rings):
		for s in range(sides):
			var quad: Array=[]
			for v in [[r,s],[r+1,s],[r,s+1],[r+1,s+1]]:
				var ring: Array=ring_pts[v[0]]
				var a: float=v[1]*TAU/sides
				var dir := Vector3(cos(a),0,sin(a))
				quad.append({"p":ring[0]+dir*ring[1],"n":dir,"uv":Vector2(float(v[1])/sides*1.0,ring[2]*height/2.2),"c":Color.WHITE})
			for i in [0,2,1,1,2,3]:
				trunk.set_normal(quad[i].n)
				trunk.set_uv(quad[i].uv)
				trunk.set_color(quad[i].c)
				trunk.add_vertex(quad[i].p)
	var crown := Vector3(1.5,height,0)
	var fronds := SurfaceTool.new()
	fronds.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := 13
	for i in range(count):
		var golden := i*2.39996
		var tier := float(i)/(count-1)
		# Newest fronds stand tall, oldest hang low.
		var rise := lerpf(1.25,-0.15,tier)
		var length := lerpf(4.1,5.0,sin(tier*PI))
		add_frond(fronds,crown+Vector3(0,0.15-tier*0.35,0),golden,rise,length,lerpf(1.0,0.72,tier))
	# Hanging coconuts below the crown.
	for i in range(3):
		var a := i*TAU/3+0.4
		add_ball(trunk,crown+Vector3(cos(a)*0.34,-0.42-(i%2)*0.14,sin(a)*0.34),0.15,Color(0.36,0.38,0.2))
	var mesh := ArrayMesh.new()
	trunk.commit(mesh)
	fronds.commit(mesh)
	return mesh

func add_frond(s: SurfaceTool,origin: Vector3,angle: float,rise: float,length: float,shade: float) -> void:
	var dir := Vector3(cos(angle),0,sin(angle))
	var side := dir.cross(Vector3.UP)
	var width := length*0.30
	var last_c := origin
	var last_up := Vector3.UP
	for j in range(SEGMENTS):
		var t0 := float(j)/SEGMENTS
		var t1 := float(j+1)/SEGMENTS
		var c0 := frond_point(origin,dir,rise,length,t0)
		var c1 := frond_point(origin,dir,rise,length,t1)
		# The pinnae fold down from the midrib in a shallow V.
		var fold := Vector3.DOWN*width*0.34
		var w0 := side*width*sin(minf(t0*1.04+0.04,1.0)*PI)
		var w1 := side*width*sin(minf(t1*1.04+0.04,1.0)*PI)
		var n := (dir*0.35+Vector3.UP).normalized()
		var tone := Color.WHITE*shade*lerpf(0.82,1.0,t1)
		for sign_side in [-1.0,1.0]:
			var u_out: float=0.5+sign_side*0.5
			var quad := [[c0,Vector2(0.5,t0)],[c1,Vector2(0.5,t1)],[c0+w0*sign_side+fold*sin(t0*PI)*0.8,Vector2(u_out,t0)],[c1+w1*sign_side+fold*sin(t1*PI)*0.8,Vector2(u_out,t1)]]
			for k in [0,1,2,2,1,3]:
				s.set_normal(n)
				s.set_uv(quad[k][1])
				s.set_color(tone)
				s.set_uv2(Vector2(tone.r,0))
				s.add_vertex(quad[k][0])
		last_c=c1
		last_up=n

func frond_point(origin: Vector3,dir: Vector3,rise: float,length: float,t: float) -> Vector3:
	return origin+dir*(t*length)+Vector3.UP*(rise*sin(minf(t*1.25,1.0)*PI*0.5)*length*0.42-t*t*length*0.62)

func add_ball(s: SurfaceTool,centre: Vector3,radius: float,color: Color) -> void:
	var lats := 2
	var lons := 5
	for la in range(lats):
		for lo in range(lons):
			var pts: Array=[]
			for v in [[la,lo],[la+1,lo],[la,lo+1],[la+1,lo+1]]:
				var theta: float=float(v[0])/lats*PI
				var phi: float=float(v[1])/lons*TAU
				pts.append(Vector3(sin(theta)*cos(phi),cos(theta),sin(theta)*sin(phi)))
			for i in [0,2,1,1,2,3]:
				s.set_normal(pts[i])
				s.set_uv(Vector2(0.5,0.5))
				s.set_color(color*2.2)
				s.add_vertex(centre+pts[i]*radius)

## Three crossed cards sharing the impostor image. Base centre at the origin, unit size.
func cross_card() -> ArrayMesh:
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(3):
		var a := i*PI/3.0+0.26
		var right := Vector3(cos(a),0,sin(a))*0.5
		var quad := [[-right,Vector2(0,1)],[right,Vector2(1,1)],[-right+Vector3.UP,Vector2(0,0)],[right+Vector3.UP,Vector2(1,0)]]
		for k in [0,2,1,1,2,3]:
			var p: Vector3=quad[k][0]
			# Rounded normal: each plane lights as part of one dome.
			s.set_normal((p-Vector3(0,0.2,0)).normalized())
			s.set_uv(quad[k][1])
			s.add_vertex(p)
	return s.commit()

## Single quad, turned toward the camera in the vertex shader.
func billboard_card() -> ArrayMesh:
	var s := SurfaceTool.new()
	s.begin(Mesh.PRIMITIVE_TRIANGLES)
	var quad := [[Vector3(-0.5,0,0),Vector2(0,1)],[Vector3(0.5,0,0),Vector2(1,1)],[Vector3(-0.5,1,0),Vector2(0,0)],[Vector3(0.5,1,0),Vector2(1,0)]]
	for k in [0,2,1,1,2,3]:
		s.set_normal(Vector3.FORWARD)
		s.set_uv(quad[k][1])
		s.add_vertex(quad[k][0])
	return s.commit()

