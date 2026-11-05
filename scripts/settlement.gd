extends Node3D
## Towns and villages from the baked placement list: corrugated-iron homes on concrete plinths,
## verandas, louvre windows and rain tanks, concrete shop blocks in Port Vila, power lines along the road.
const CHUNK := 180.0
var world: Node3D
var materials := {}
var tools := {}
var glass: StandardMaterial3D
var lamps: Array[OmniLight3D] = []

const WALL_PAINTS := [Color("e4dfca"),Color("b5cdc0"),Color("d8c49d"),Color("ece9dc"),Color("9fc0c6"),Color("d8ab90"),Color("c5cfa8"),Color("e8d9b0")]
const ROOF_PAINTS := [Color("8a9591"),Color("ab6147"),Color("6a8a87"),Color("a9aba5"),Color("875440"),Color("4f6f7a")]
const SHOP_PAINTS := [Color("d7d2c3"),Color("c6b79a"),Color("9eb8bb"),Color("d9c3a0"),Color("e6e2d8")]
const SIGN_PAINTS := [Color("a33a2c"),Color("1f6a7a"),Color("d0902c"),Color("2d6a44"),Color("31465e")]

func pbr(key: String,file: String,metres: float,roughness := 0.9,metal := 0.0,normal_file := "") -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture=load("res://assets/environment/"+file+"_Diffuse.jpg")
	m.normal_enabled=true
	m.normal_texture=load("res://assets/environment/"+(normal_file if normal_file!="" else file)+"_nor_gl.jpg")
	m.vertex_color_use_as_albedo=true
	m.uv1_scale=Vector3.ONE/metres
	m.roughness=roughness
	m.metallic=metal
	m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.normal_scale=0.7
	materials[key]=m
	return m

func make_materials() -> void:
	# clean_* are neutral versions from tools/clean_textures.gd, so wall paint shows its true colour.
	pbr("board","clean_planks",2.4,0.9,0.0,"white_planks_clean")
	pbr("plaster","clean_plaster",3.0,0.9,0.0,"white_plaster_rough_01")
	# Low metalness: there is no reflection probe here, so strongly metallic roofs render almost black.
	pbr("iron","worn_corrugated_iron",2.0,0.62,0.12)
	pbr("rust","rusty_corrugated_iron",2.0,0.74,0.08)
	pbr("wood","weathered_planks",2.2)
	pbr("concrete","clean_concrete",3.0,0.9,0.0,"concrete_floor_worn_001").normal_enabled=false
	# Louvre blades as one textured quad rather than a stack of boxes: far fewer triangles, and they anti-alias.
	var slats := Image.create(4,32,true,Image.FORMAT_RGBA8)
	for y in range(32):
		var blade: float=1.0 if y%32<20 else 0.0
		var tone: float=lerpf(0.72,1.0,float(y%32)/20.0) if blade>0.0 else 0.0
		for x in range(4): slats.set_pixel(x,y,Color(tone,tone,tone,blade))
	slats.generate_mipmaps()
	var louvre := StandardMaterial3D.new()
	louvre.albedo_texture=ImageTexture.create_from_image(slats)
	louvre.vertex_color_use_as_albedo=true
	louvre.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	louvre.alpha_scissor_threshold=0.5
	louvre.alpha_antialiasing_mode=BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
	louvre.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	louvre.roughness=0.7
	materials["louvre"]=louvre
	var paint := StandardMaterial3D.new()
	paint.vertex_color_use_as_albedo=true
	paint.roughness=0.7
	materials["paint"]=paint
	glass=StandardMaterial3D.new()
	# With no reflection probes, dark glossy glass renders as flat black panels; a mid tone reads as tinted glass.
	glass.albedo_color=Color(0.30,0.37,0.39)
	glass.roughness=0.18
	glass.metallic=0.0
	glass.emission_enabled=true
	glass.emission=Color(1.0,0.72,0.40)
	glass.emission_energy_multiplier=0.0
	materials["glass"]=glass
	var wire := StandardMaterial3D.new()
	wire.albedo_color=Color(0.03,0.03,0.03)
	wire.roughness=0.6
	wire.cull_mode=BaseMaterial3D.CULL_DISABLED
	materials["wire"]=wire

func build() -> void:
	make_materials()
	for data in world.baked.buildings:
		var rng := RandomNumberGenerator.new()
		rng.seed=data.seed
		var base: float=footing(data)
		var t := Transform3D(Basis(Vector3.UP,data.yaw),Vector3(data.x,base,data.z))
		var chunk := Vector2i(floori(data.x/CHUNK),floori(data.z/CHUNK))
		if data.style==2: shop(chunk,t,data,rng)
		else: house(chunk,t,data,rng)
		add_collider(t,data)
	for chain in world.baked.poles: power_line(chain)
	commit()
	street_lamps()
	world.night_listeners.append(on_night)

func footing(data: Dictionary) -> float:
	var r: float=maxf(data.w,data.d)*0.5
	# Average, not highest: the plinth runs well below ground, so downhill corners never show a wall of concrete.
	var total := 0.0
	for o in [Vector2.ZERO,Vector2(-r,-r),Vector2(r,-r),Vector2(-r,r),Vector2(r,r)]:
		total+=world.height_at(data.x+o.x,data.z+o.y)
	return total/5.0

func add_collider(t: Transform3D,data: Dictionary) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	var height: float=3.2*data.storeys+0.4
	bounds.size=Vector3(data.w,height,data.d)
	shape.shape=bounds
	body.add_child(shape)
	add_child(body)
	body.global_transform=Transform3D(t.basis,t.origin+Vector3.UP*height*0.5)

func tool_for(chunk: Vector2i,key: String) -> SurfaceTool:
	var id := Vector3i(chunk.x,chunk.y,materials.keys().find(key))
	if not tools.has(id):
		var s := SurfaceTool.new()
		s.begin(Mesh.PRIMITIVE_TRIANGLES)
		tools[id]={"tool":s,"key":key,"chunk":chunk}
	return tools[id].tool

func commit() -> void:
	for id in tools:
		var entry: Dictionary=tools[id]
		var s: SurfaceTool=entry.tool
		if entry.key in ["board","plaster","iron","rust","wood","concrete"]: s.generate_tangents()
		var node := MeshInstance3D.new()
		node.name="Town_%s_%d_%d" % [entry.key,entry.chunk.x,entry.chunk.y]
		node.mesh=s.commit()
		node.material_override=materials[entry.key]
		node.visibility_range_end=world.building_range()
		if entry.key=="wire":
			node.visibility_range_end=200.0
			node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
	tools.clear()

## Quad wound counter-clockwise seen from outside; UVs in metres. Vertex shading on the bottom and top edges fakes
## ambient occlusion at the ground and under the eaves, which this renderer cannot compute at runtime.
func quad(s: SurfaceTool,t: Transform3D,a: Vector3,b: Vector3,c: Vector3,d: Vector3,uv: Array,color: Color,bottom_shade := 1.0,top_shade := 1.0) -> void:
	var n: Vector3=(t.basis*(b-a).cross(d-a)).normalized()
	var pts := [a,b,c,d]
	for i in [0,2,1,0,3,2]:
		s.set_normal(n)
		s.set_uv(uv[i])
		s.set_color(color*(bottom_shade if i<2 else top_shade))
		s.add_vertex(t*pts[i])

func wall_quad(s: SurfaceTool,t: Transform3D,a: Vector3,b: Vector3,top: float,color: Color,shade := 0.74) -> void:
	var len_ab := a.distance_to(b)
	var c := Vector3(b.x,top,b.z)
	var d := Vector3(a.x,top,a.z)
	var offset := a.x+a.z*1.7
	quad(s,t,a,b,c,d,[Vector2(offset,a.y),Vector2(offset+len_ab,a.y),Vector2(offset+len_ab,top),Vector2(offset,top)],color,shade,0.86)

const ALL_FACES := [[0,1,2,3],[4,5,6,7],[1,4,7,2],[5,0,3,6],[3,2,7,6],[5,4,1,0]]
## Only what can be seen on a box fixed against a wall: skips its back and underside.
const WALL_FACES := [[0,1,2,3],[1,4,7,2],[5,0,3,6],[3,2,7,6]]

func cube(s: SurfaceTool,t: Transform3D,centre: Vector3,size: Vector3,color: Color,faces: Array=ALL_FACES) -> void:
	var h := size*0.5
	var p := [centre+Vector3(-h.x,-h.y,h.z),centre+Vector3(h.x,-h.y,h.z),centre+Vector3(h.x,h.y,h.z),centre+Vector3(-h.x,h.y,h.z),
		centre+Vector3(h.x,-h.y,-h.z),centre+Vector3(-h.x,-h.y,-h.z),centre+Vector3(-h.x,h.y,-h.z),centre+Vector3(h.x,h.y,-h.z)]
	for f in faces:
		var a: Vector3=p[f[0]]
		var b: Vector3=p[f[1]]
		var c: Vector3=p[f[2]]
		var d: Vector3=p[f[3]]
		var w := a.distance_to(b)
		var v := a.distance_to(d)
		quad(s,t,a,b,c,d,[Vector2(0,0),Vector2(w,0),Vector2(w,v),Vector2(0,v)],color)

## Frame, glass, and louvre blades on a wall plane. side: 0 front(+z) 1 back 2 right(+x) 3 left.
func window(chunk: Vector2i,t: Transform3D,side: int,along: float,half_depth: float,sill: float,w: float,h: float,trim: Color,louvres := true) -> void:
	var yaw: float=[0.0,PI,PI/2,-PI/2][side]
	var local := t*Transform3D(Basis(Vector3.UP,yaw),Vector3(0,0,0).lerp(Vector3.ZERO,0))
	var f := local*Transform3D(Basis.IDENTITY,Vector3(along,sill,half_depth))
	var paint := tool_for(chunk,"paint")
	cube(paint,f,Vector3(0,h*0.5,0.015),Vector3(w+0.14,h+0.14,0.05),trim,WALL_FACES)
	var g := tool_for(chunk,"glass")
	quad(g,f,Vector3(-w*0.5,0,0.05),Vector3(w*0.5,0,0.05),Vector3(w*0.5,h,0.05),Vector3(-w*0.5,h,0.05),[Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN],Color.WHITE)
	if louvres:
		var rows: float=h/0.24
		quad(tool_for(chunk,"louvre"),f,Vector3(-w*0.5,0,0.075),Vector3(w*0.5,0,0.075),Vector3(w*0.5,h,0.075),Vector3(-w*0.5,h,0.075),[Vector2(0,rows),Vector2(1,rows),Vector2(1,0),Vector2(0,0)],trim.darkened(0.08))
	else:
		cube(paint,f,Vector3(0,h*0.5,0.07),Vector3(0.05,h,0.03),trim,WALL_FACES)
	cube(paint,f,Vector3(0,-0.03,0.09),Vector3(w+0.24,0.06,0.13),trim.darkened(0.12),WALL_FACES)

func house(chunk: Vector2i,t: Transform3D,data: Dictionary,rng: RandomNumberGenerator) -> void:
	var w: float=data.w
	var d: float=data.d
	var wall_h := 2.9
	var floor_y := 0.42
	var hw := w*0.5
	var hd := d*0.5
	var paint_color: Color=WALL_PAINTS[rng.randi()%WALL_PAINTS.size()]
	var roof_color: Color=ROOF_PAINTS[rng.randi()%ROOF_PAINTS.size()]
	var wall_key: String="board" if data.style==0 else "plaster"
	var rusty := rng.randf()<0.42
	var roof_key: String="rust" if rusty else "iron"
	if rusty: roof_color=Color(0.9,0.86,0.8)
	var trim := Color("c8c6b8") if rng.randf()<0.7 else paint_color.darkened(0.35)
	var concrete := tool_for(chunk,"concrete")
	cube(concrete,t,Vector3(0,-1.3,0),Vector3(w+0.5,3.44,d+0.5),Color(0.72,0.71,0.66))
	var s := tool_for(chunk,wall_key)
	var top := floor_y+wall_h
	wall_quad(s,t,Vector3(-hw,floor_y,hd),Vector3(hw,floor_y,hd),top,paint_color)
	wall_quad(s,t,Vector3(hw,floor_y,-hd),Vector3(-hw,floor_y,-hd),top,paint_color)
	wall_quad(s,t,Vector3(hw,floor_y,hd),Vector3(hw,floor_y,-hd),top,paint_color)
	wall_quad(s,t,Vector3(-hw,floor_y,-hd),Vector3(-hw,floor_y,hd),top,paint_color)
	# Ridge along the frontage: open gables on some homes, the cyclone-resistant hipped roof on others.
	var hip := rng.randf()<0.45
	var rise := d*0.2
	var over := 0.55
	var ridge := top+rise
	var eave := top-over*rise/hd
	var r := tool_for(chunk,roof_key)
	var ex: float=hw+over
	var ez: float=hd+over
	# Half length of the ridge: on a hip it stops short of the ends, by as much as the roof is deep.
	var rx: float=maxf(ex-ez,0.4) if hip else ex
	var run := Vector2(ez,rise+over*rise/hd).length()
	quad(r,t,Vector3(-ex,eave,ez),Vector3(ex,eave,ez),Vector3(rx,ridge,0),Vector3(-rx,ridge,0),[Vector2(-ex,0),Vector2(ex,0),Vector2(rx,run),Vector2(-rx,run)],roof_color)
	quad(r,t,Vector3(ex,eave,-ez),Vector3(-ex,eave,-ez),Vector3(-rx,ridge,0),Vector3(rx,ridge,0),[Vector2(-ex,0),Vector2(ex,0),Vector2(rx,run),Vector2(-rx,run)],roof_color)
	# Soffit and roof ends.
	var shade := Color(0.33,0.32,0.30)
	var paint := tool_for(chunk,"paint")
	var no_uv := [Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO]
	quad(paint,t,Vector3(ex,eave-0.02,ez),Vector3(-ex,eave-0.02,ez),Vector3(-rx,ridge-0.04,0),Vector3(rx,ridge-0.04,0),no_uv,shade)
	quad(paint,t,Vector3(-ex,eave-0.02,-ez),Vector3(ex,eave-0.02,-ez),Vector3(rx,ridge-0.04,0),Vector3(-rx,ridge-0.04,0),no_uv,shade)
	for side in [-1.0,1.0]:
		if hip:
			var near_corner := Vector3(side*ex,eave,ez*side)
			var far_corner := Vector3(side*ex,eave,-ez*side)
			var tip := Vector3(side*rx,ridge,0)
			triangle(r,t,near_corner,far_corner,tip,roof_color)
			triangle(paint,t,far_corner+Vector3.DOWN*0.02,near_corner+Vector3.DOWN*0.02,tip+Vector3.DOWN*0.04,shade)
			continue
		var x: float=side*hw
		var a := Vector3(x,top,hd*side)
		var b := Vector3(x,top,-hd*side)
		var apex := Vector3(x,ridge,0)
		var n: Vector3=(t.basis*Vector3(side,0,0)).normalized()
		for i in range(3):
			var p: Vector3=[a,b,apex][[0,2,1][i]]
			s.set_normal(n)
			s.set_uv(Vector2(p.z,p.y))
			s.set_color(paint_color*0.92)
			s.add_vertex(t*p)
		for z_sign in [-1.0,1.0]:
			cube(paint,t,Vector3(x+side*over,lerpf(eave,ridge,0.5),z_sign*(hd+over)*0.5),Vector3(0.05,0.14,hd+over+0.3),trim)
	cube(paint,t,Vector3(0,eave-0.03,hd+over),Vector3(w+over*2,0.17,0.05),trim)
	cube(paint,t,Vector3(0,eave-0.03,-hd-over),Vector3(w+over*2,0.17,0.05),trim)
	cube(tool_for(chunk,roof_key),t,Vector3(0,ridge+0.03,0),Vector3(rx*2.0,0.08,0.34),roof_color.darkened(0.08))
	# Openings: door plus windows along the front, windows on the other walls.
	var wood := tool_for(chunk,"wood")
	var door_x: float=rng.randf_range(-hw*0.25,hw*0.25)
	cube(wood,t,Vector3(door_x,floor_y+1.03,hd+0.03),Vector3(0.96,2.06,0.07),Color(0.68,0.60,0.5).lerp(paint_color,0.3))
	cube(paint,t,Vector3(door_x,floor_y+2.1,hd+0.04),Vector3(1.12,0.09,0.08),trim)
	for x in [door_x-0.53,door_x+0.53]:
		cube(paint,t,Vector3(x,floor_y+1.03,hd+0.04),Vector3(0.09,2.1,0.08),trim)
	var win_w := 1.25
	var spot := -hw+1.3
	while spot<hw-1.0:
		if absf(spot-door_x)>1.45: window(chunk,t,0,spot,hd,floor_y+0.95,win_w,1.3,trim)
		spot+=rng.randf_range(2.3,3.1)
	spot=-hw+1.5
	while spot<hw-1.0:
		window(chunk,t,1,spot,hd,floor_y+1.05,1.1,1.15,trim)
		spot+=rng.randf_range(2.8,3.8)
	for side in [2,3]:
		var span_half := hd-1.3
		var z := -span_half
		while z<=span_half:
			window(chunk,t,side,z,hw,floor_y+1.0,1.1,1.2,trim)
			z+=maxf(2.4,span_half*2.0)
	# Veranda on most homes: slab, posts, lean-to roof.
	if rng.randf()<0.72:
		var deck_d := 2.3
		var vw := w*rng.randf_range(0.55,0.95)
		var deck_y := floor_y-0.06
		cube(concrete,t,Vector3(0,deck_y-0.6,hd+deck_d*0.5),Vector3(vw,1.32,deck_d),Color(0.74,0.73,0.68))
		for step in range(2):
			cube(concrete,t,Vector3(door_x,deck_y-0.18-step*0.15,hd+deck_d+0.18+step*0.26),Vector3(1.5,0.16,0.3),Color(0.70,0.69,0.65))
		var low := top-0.72
		var high := top-0.14
		var hx: float=vw*0.5+0.2
		quad(r,t,Vector3(-hx,low,hd+deck_d+0.35),Vector3(hx,low,hd+deck_d+0.35),Vector3(hx,high,hd+0.02),Vector3(-hx,high,hd+0.02),[Vector2(0,0),Vector2(hx*2,0),Vector2(hx*2,deck_d),Vector2(0,deck_d)],roof_color)
		quad(paint,t,Vector3(hx,low-0.02,hd+deck_d+0.35),Vector3(-hx,low-0.02,hd+deck_d+0.35),Vector3(-hx,high-0.02,hd+0.02),Vector3(hx,high-0.02,hd+0.02),[Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO],shade)
		for x in [-vw*0.5+0.1,vw*0.5-0.1,-vw*0.17,vw*0.17]:
			cube(wood,t,Vector3(x,(deck_y+low)*0.5,hd+deck_d-0.1),Vector3(0.11,low-deck_y,0.11),trim.darkened(0.1))
	# Rain tank and downpipe: nearly every Vanuatu home collects roof water.
	if rng.randf()<0.7:
		var tx: float=(hw+1.05)*(1.0 if rng.randf()<0.5 else -1.0)
		cylinder(paint,t,Vector3(tx,0.0,-hd*0.35),0.85,2.1,Color(0.25,0.33,0.26) if rng.randf()<0.6 else Color(0.70,0.71,0.68))
		cube(paint,t,Vector3(tx*0.93,lerpf(2.1,eave,0.5),-hd-over*0.5),Vector3(0.09,eave-2.1,0.09),Color(0.82,0.82,0.78))

## Triangle wound counter-clockwise seen from outside, UVs taken from its position in metres.
func triangle(s: SurfaceTool,t: Transform3D,a: Vector3,b: Vector3,c: Vector3,color: Color) -> void:
	var n: Vector3=(t.basis*(b-a).cross(c-a)).normalized()
	for p: Vector3 in [a,c,b]:
		s.set_normal(n)
		s.set_uv(Vector2(p.z,p.x+p.y))
		s.set_color(color)
		s.add_vertex(t*p)

func cylinder(s: SurfaceTool,t: Transform3D,base: Vector3,radius: float,height: float,color: Color) -> void:
	var sides := 10
	for i in range(sides):
		var a0 := i*TAU/sides
		var a1 := (i+1)*TAU/sides
		var o0 := Vector3(sin(a0),0,cos(a0))
		var o1 := Vector3(sin(a1),0,cos(a1))
		var rib: float=0.92 if i%2==0 else 1.0
		for pair in [[0,o0,0.0],[2,o1,height],[1,o1,0.0],[0,o0,0.0],[3,o0,height],[2,o1,height]]:
			var o: Vector3=pair[1]
			s.set_normal(t.basis*o)
			s.set_uv(Vector2.ZERO)
			s.set_color(color*rib*(0.7 if pair[2]==0.0 else 1.0))
			s.add_vertex(t*(base+o*radius+Vector3.UP*pair[2]))
		var cap_n: Vector3=t.basis*Vector3.UP
		for p in [o0*radius,Vector3.ZERO,o1*radius]:
			s.set_normal(cap_n)
			s.set_uv(Vector2.ZERO)
			s.set_color(color*0.9)
			s.add_vertex(t*(base+p+Vector3.UP*height))

func shop(chunk: Vector2i,t: Transform3D,data: Dictionary,rng: RandomNumberGenerator) -> void:
	var w: float=data.w
	var d: float=data.d
	var storeys: int=data.storeys
	var hw := w*0.5
	var hd := d*0.5
	var fh := 3.2
	var body_color: Color=SHOP_PAINTS[rng.randi()%SHOP_PAINTS.size()]
	var trim := body_color.darkened(0.22)
	var top := storeys*fh+0.2
	var concrete := tool_for(chunk,"concrete")
	var plaster := tool_for(chunk,"plaster")
	var paint := tool_for(chunk,"paint")
	cube(concrete,t,Vector3(0,-0.6,0),Vector3(w+0.4,1.6,d+0.4),Color(0.66,0.65,0.60))
	wall_quad(plaster,t,Vector3(-hw,0.2,hd),Vector3(hw,0.2,hd),top,body_color)
	wall_quad(plaster,t,Vector3(hw,0.2,-hd),Vector3(-hw,0.2,-hd),top,body_color)
	wall_quad(plaster,t,Vector3(hw,0.2,hd),Vector3(hw,0.2,-hd),top,body_color)
	wall_quad(plaster,t,Vector3(-hw,0.2,-hd),Vector3(-hw,0.2,hd),top,body_color)
	# Flat roof behind a parapet, with plant on top.
	cube(concrete,t,Vector3(0,top-0.02,0),Vector3(w-0.1,0.06,d-0.1),Color(0.45,0.44,0.42))
	for edge in [[Vector3(0,top+0.28,hd),Vector3(w+0.14,0.62,0.18)],[Vector3(0,top+0.28,-hd),Vector3(w+0.14,0.62,0.18)],[Vector3(hw,top+0.28,0),Vector3(0.18,0.62,d)],[Vector3(-hw,top+0.28,0),Vector3(0.18,0.62,d)]]:
		cube(plaster,t,edge[0],edge[1],body_color.darkened(0.08))
	cube(paint,t,Vector3(rng.randf_range(-hw*0.5,hw*0.5),top+0.35,rng.randf_range(-hd*0.5,0)),Vector3(1.0,0.7,0.8),Color(0.62,0.63,0.60))
	# Glazed shopfront, awning and painted sign band.
	var g := tool_for(chunk,"glass")
	quad(g,t,Vector3(-hw+0.4,0.45,hd+0.03),Vector3(hw-0.4,0.45,hd+0.03),Vector3(hw-0.4,2.75,hd+0.03),Vector3(-hw+0.4,2.75,hd+0.03),[Vector2.ZERO,Vector2.RIGHT,Vector2.ONE,Vector2.DOWN],Color.WHITE)
	var bay := -hw+0.4
	while bay<=hw-0.3:
		cube(paint,t,Vector3(bay,1.6,hd+0.06),Vector3(0.1,2.35,0.07),Color(0.2,0.2,0.21))
		bay+=(w-0.8)/maxf(1.0,floorf((w-0.8)/2.6))
	cube(paint,t,Vector3(0,0.42,hd+0.06),Vector3(w-0.7,0.08,0.07),Color(0.2,0.2,0.21))
	var sign_color: Color=SIGN_PAINTS[rng.randi()%SIGN_PAINTS.size()]
	cube(paint,t,Vector3(0,3.02,hd+0.1),Vector3(w-0.2,0.5,0.1),sign_color)
	var awn := tool_for(chunk,"iron")
	var ad := 2.7
	var arch: Array=[Vector2(0,0),Vector2(w,0),Vector2(w,ad),Vector2(0,ad)]
	quad(awn,t,Vector3(-hw,2.82,hd+ad),Vector3(hw,2.82,hd+ad),Vector3(hw,3.08,hd),Vector3(-hw,3.08,hd),arch,Color(0.72,0.72,0.70))
	quad(paint,t,Vector3(hw,2.8,hd+ad),Vector3(-hw,2.8,hd+ad),Vector3(-hw,3.06,hd),Vector3(hw,3.06,hd),[Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO],Color(0.3,0.3,0.29))
	var post := -hw+0.25
	while post<=hw-0.2:
		cube(paint,t,Vector3(post,1.45,hd+ad-0.12),Vector3(0.1,2.75,0.1),Color(0.44,0.45,0.44))
		post+=maxf(2.8,(w-0.5)/maxf(1.0,floorf((w-0.5)/3.6)))
	# Upper floors: repeating windows and a slab line.
	for floor_index in range(1,storeys):
		var y: float=floor_index*fh+0.2
		cube(paint,t,Vector3(0,y-0.03,hd+0.05),Vector3(w+0.05,0.14,0.1),trim)
		var x := -hw+1.5
		while x<hw-1.0:
			window(chunk,t,0,x,hd,y+0.85,1.5,1.45,trim,false)
			x+=2.8
		x=-hw+1.5
		while x<hw-1.0:
			window(chunk,t,1,x,hd,y+0.85,1.3,1.4,trim,false)
			x+=3.6
	var z := -hd+1.8
	while z<hd-1.4:
		for floor_index in range(storeys):
			var y: float=floor_index*fh+0.2
			window(chunk,t,2,z,hw,y+0.9,1.2,1.35,trim,false)
			window(chunk,t,3,z,hw,y+0.9,1.2,1.35,trim,false)
		z+=3.4

func power_line(chain: PackedVector3Array) -> void:
	var height := 7.4
	for i in range(chain.size()):
		var base: Vector3=chain[i]
		var chunk := Vector2i(floori(base.x/CHUNK),floori(base.z/CHUNK))
		var ahead: Vector3=chain[mini(i+1,chain.size()-1)]-chain[maxi(i-1,0)]
		ahead.y=0
		if ahead.length_squared()<0.01: ahead=Vector3.FORWARD
		var t := Transform3D(Basis(Vector3.UP,atan2(ahead.x,ahead.z)),base)
		var wood := tool_for(chunk,"wood")
		cube(wood,t,Vector3(0,height*0.5,0),Vector3(0.2,height,0.2),Color(0.52,0.46,0.40))
		cube(wood,t,Vector3(0,height-0.5,0),Vector3(1.7,0.1,0.1),Color(0.42,0.37,0.32))
		if i==0: continue
		var from: Vector3=chain[i-1]
		var dist := from.distance_to(base)
		if dist>70.0: continue
		var wire := tool_for(chunk,"wire")
		for off in [-0.75,0.0,0.75]:
			var side: Vector3=(base-from).cross(Vector3.UP).normalized()*off
			var last: Vector3=from+side+Vector3.UP*(height-0.42)
			for k in range(1,5):
				var f := k/4.0
				var p: Vector3=from.lerp(base,f)+side+Vector3.UP*(height-0.42-sin(f*PI)*0.55)
				var d := Vector3.UP*0.022
				for q in [last-d,last+d,p+d,last-d,p+d,p-d]:
					wire.set_normal(Vector3.UP)
					wire.add_vertex(q)
				last=p

func street_lamps() -> void:
	# A few warm lamps around the village green, used only at night.
	for spot in [Vector2(-497,100),Vector2(-481,128),Vector2(-470,92),Vector2(-505,128)]:
		var lamp := OmniLight3D.new()
		lamp.light_color=Color(1.0,0.78,0.5)
		lamp.light_energy=0.0
		lamp.omni_range=15.0
		lamp.shadow_enabled=false
		lamp.distance_fade_enabled=true
		lamp.distance_fade_begin=140.0
		lamp.distance_fade_length=30.0
		lamp.position=Vector3(spot.x,world.height_at(spot.x,spot.y)+5.0,spot.y)
		add_child(lamp)
		lamps.append(lamp)

var night_level := 0.0
func on_night(level: float) -> void:
	if level<0.0: level=night_level
	night_level=level
	var lit := smoothstep(0.35,0.85,level)
	glass.emission_energy_multiplier=lit*1.35
	for lamp in lamps: lamp.light_energy=lit*1.6



