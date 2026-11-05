extends Node3D
## Towns and villages from the baked placement list: corrugated-iron homes on concrete plinths,
## verandas, louvre windows and rain tanks, concrete shop blocks in Port Vila, power lines along the road.
const CHUNK := 180.0
var world: Node3D
var materials := {}
var tools := {}
var glass: StandardMaterial3D
var lamps: Array[OmniLight3D] = []
## Collision boxes for the parts of the building being built that stick out beyond its walls: [centre, size].
var extra_boxes: Array = []
var refined_parts: Array[Dictionary] = []
var refined_colliders: Array = []
var house_sites: Array[Dictionary] = []
var foundation_supports: Array[Dictionary] = []
var support_batches := {}
var pole_sites: Array[Vector3] = []
var wire_spans: Array[Dictionary] = []

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
	materials["pole"]=materials["wood"].duplicate()
	pbr("concrete","clean_concrete",3.0,0.9,0.0,"concrete_floor_worn_001").normal_enabled=false
	materials["concrete"].cull_mode=BaseMaterial3D.CULL_DISABLED
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
	load_refined_house()
	for data in world.baked.buildings:
		# Reserve the landmark parcel rather than placing a generic house through it.
		if (preload("res://scripts/sunshine_spa.gd").reserved(data.x,data.z,maxf(data.w,data.d)*0.7) or preload("res://scripts/elluk_restaurant.gd").reserved(data.x,data.z,maxf(data.w,data.d)*0.7) or preload("res://scripts/seaside_inn.gd").reserved(data.x,data.z,maxf(data.w,data.d)*0.7) or preload("res://scripts/island_landmarks.gd").reserved(data.x,data.z,maxf(data.w,data.d)*0.7) or preload("res://scripts/place_sites.gd").reserved(data.x,data.z,maxf(data.w,data.d)*0.7)): continue
		var rng := RandomNumberGenerator.new()
		rng.seed=data.seed
		var base: float=footing(data)
		var t := Transform3D(Basis(Vector3.UP,data.yaw),Vector3(data.x,base,data.z))
		var chunk := Vector2i(floori(data.x/CHUNK),floori(data.z/CHUNK))
		extra_boxes.clear()
		if data.style==2: shop(chunk,t,data,rng)
		else: house(chunk,t,data,rng)
		add_collider(t,data)
	for chain in world.baked.poles:
		var grounded: PackedVector3Array=chain.duplicate()
		for i in range(grounded.size()):
			var at: Vector3=grounded[i]
			# Divert the complete electrical chain around new business parcels, including its solids.
			if preload("res://scripts/island_landmarks.gd").reserved(at.x,at.z,1):
				var sites := preload("res://scripts/island_landmarks.gd")
				at.z=sites.BAR.y-12 if absf(at.z-sites.BAR.y)<11 else sites.PORT.y-22
			at.y=world.surface_height_at(at.x,at.z)
			grounded[i]=at
		for i in range(grounded.size()):
			var at: Vector3=grounded[i]
			for site in preload("res://scripts/place_sites.gd").SITES:
				if absf(at.x-site.at[0])<site.size[0]/2+2 and absf(at.z-site.at[1])<site.size[1]/2+9: at.x=site.at[0]+site.size[0]/2+3
			at.y=world.surface_height_at(at.x,at.z)
			grounded[i]=at
		power_line(grounded)
		pole_colliders(grounded)
	commit()
	commit_supports()
	street_lamps()
	world.night_listeners.append(on_night)

func footing(data: Dictionary) -> float:
	var hw: float=data.w*0.5
	var hd: float=data.d*0.5
	var basis := Basis(Vector3.UP,data.yaw)
	var origin := Vector3(data.x,0.0,data.z)
	# Keep the complete footprint above the visible surface, including its road overlay.
	var highest := -1e9
	var front_edge: float=hd if data.style==2 else data.d*0.71
	for o in [Vector3.ZERO,Vector3(-hw,0,-hd),Vector3(hw,0,-hd),Vector3(-hw,0,hd),Vector3(hw,0,hd),Vector3(-hw*0.84,0,front_edge),Vector3(hw*0.84,0,front_edge)]:
		var p: Vector3=origin+basis*o
		var h: float=world.surface_height_at(p.x,p.z)
		highest=maxf(highest,h)
	var front: Vector3=origin+basis*Vector3(0,0,hd)
	var door_min: float=world.height_at(front.x,front.z)-(0.05 if data.style==2 else 0.25)
	return maxf(highest-0.10,door_min)

func add_collider(t: Transform3D,data: Dictionary) -> void:
	var body := StaticBody3D.new()
	body.name="BuildingCollision"
	var height: float=3.2*data.storeys+1.2
	if data.style==2:
		add_box(body,Vector3(0,height*0.5,0),Vector3(data.w,height,data.d))
	# Everything built onto the house collides too: veranda, rain tank, awning posts.
	for extra in extra_boxes: add_box(body,extra[0],extra[1])
	add_child(body)
	body.global_transform=t
	house_sites.append({"body":body,"data":data,"transform":t})

func load_refined_house() -> void:
	var source: Node3D=load("res://assets/models/island_refined/coastal_house.glb").instantiate()
	for node: MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
		var local := Transform3D.IDENTITY
		var cursor: Node3D=node
		while cursor!=source:
			local=cursor.transform*local
			cursor=cursor.get_parent()
		for surface in range(node.mesh.get_surface_count()):
			var mat: Material=node.mesh.surface_get_material(surface)
			var key: String=mat.resource_name if mat else "paint"
			if not materials.has(key): key="paint"
			refined_parts.append({"mesh":node.mesh,"surface":surface,"transform":local,"key":key})
	source.free()
	refined_colliders=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/island_refined/house_colliders.json")).boxes

func refined_house(chunk: Vector2i,t: Transform3D,data: Dictionary,rng: RandomNumberGenerator) -> void:
	var scale := Vector3(data.w/8.0,1.0,data.d/10.0)
	var tint: Color=WALL_PAINTS[rng.randi()%WALL_PAINTS.size()]
	var roof: Color=ROOF_PAINTS[rng.randi()%ROOF_PAINTS.size()]
	for part in refined_parts:
		var transform: Transform3D=t*Transform3D(Basis.from_scale(scale),Vector3.ZERO)*part.transform
		var key: String=part.key
		if key=="board" and data.style==1: key="plaster"
		var source: Mesh=part.mesh
		var arrays: Array=source.surface_get_arrays(part.surface)
		var colors := PackedColorArray()
		colors.resize((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
		colors.fill(tint if key in ["board","plaster"] else (roof if key=="iron" else Color.WHITE))
		arrays[Mesh.ARRAY_COLOR]=colors
		var colored := ArrayMesh.new()
		colored.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		tool_for(chunk,key).append_from(colored,0,transform)
	for box in refined_colliders:
		var p: Array=box.center
		var s: Array=box.size
		extra_boxes.append([Vector3(p[0],p[1],p[2])*scale,Vector3(s[0],s[1],s[2])*scale])
	# Every slab needs its own ground contact, including both entrance steps.
	for slab in refined_colliders:
		if not slab.name in ["Foundation","PorchDeck","LowerStep","UpperStep"]: continue
		var slab_center := Vector3(slab.center[0],0,slab.center[2])*scale
		var slab_size := Vector3(slab.size[0],0,slab.size[2])*scale
		ground_support(chunk,t,slab_center,slab_size,0.0,slab.name)

func ground_support(chunk: Vector2i,t: Transform3D,center: Vector3,size: Vector3,top: float,label: String) -> void:
	# Sample the whole footprint; a low point can lie between corner samples.
	var bottom := top-0.18
	var nx := maxi(1,ceili(size.x))
	var nz := maxi(1,ceili(size.z))
	for ix in range(nx+1):
		for iz in range(nz+1):
			var local := center+Vector3((float(ix)/nx-.5)*size.x,0,(float(iz)/nz-.5)*size.z)
			var at: Vector3=t*local
			bottom=minf(bottom,world.surface_height_at(at.x,at.z)-t.origin.y-0.25)
	var dimensions := Vector3(size.x,top-bottom,size.z)
	var at := center+Vector3(0,(top+bottom)*0.5,0)
	# Engine-native box instances keep bases visible independently of authored wall batches.
	if not support_batches.has(chunk): support_batches[chunk]=[]
	support_batches[chunk].append(t*Transform3D(Basis.from_scale(dimensions),at))
	extra_boxes.append([at,dimensions])
	foundation_supports.append({"label":label,"transform":t,"center":center,"size":size,"bottom":bottom,"top":top})

func commit_supports() -> void:
	var box := BoxMesh.new()
	box.size=Vector3.ONE
	var material: StandardMaterial3D=materials["concrete"].duplicate()
	material.uv1_triplanar=true
	material.vertex_color_use_as_albedo=false
	material.albedo_color=Color("b7b5a7")
	box.material=material
	for chunk: Vector2i in support_batches:
		var transforms: Array=support_batches[chunk]
		var origin := Vector3((chunk.x+.5)*CHUNK,0,(chunk.y+.5)*CHUNK)
		var instances := MultiMesh.new()
		instances.transform_format=MultiMesh.TRANSFORM_3D
		instances.mesh=box
		instances.instance_count=transforms.size()
		for i in range(transforms.size()):
			var local: Transform3D=transforms[i]
			local.origin-=origin
			instances.set_instance_transform(i,local)
		var node := MultiMeshInstance3D.new()
		node.name="VisibleFoundations_%d_%d" % [chunk.x,chunk.y]
		node.multimesh=instances
		node.position=origin
		node.visibility_range_end=world.building_range()
		add_child(node)
	support_batches.clear()

func add_box(body: StaticBody3D,centre: Vector3,size: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size=size
	shape.shape=bounds
	shape.position=centre
	body.add_child(shape)

## Power poles, on the trunk layer: they stop people and cars without catching the camera.
func pole_colliders(chain: PackedVector3Array) -> void:
	var body := StaticBody3D.new()
	body.collision_layer=world.TREE_LAYER
	body.collision_mask=0
	for base in chain: add_box(body,base+Vector3.UP*3.7,Vector3(0.3,7.4,0.3))
	add_child(body)

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
		var raw: Array=s.commit_to_arrays()
		var indices: PackedInt32Array=raw[Mesh.ARRAY_INDEX] if raw[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
		# Imported meshes are indexed; hand-authored triangles appended afterward are not.
		# Include those vertices explicitly or only the imported portion reaches the renderer.
		if not indices.is_empty():
			var used := PackedByteArray()
			used.resize((raw[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
			for vertex in indices: used[vertex]=1
			var added := 0
			for vertex in range(used.size()):
				if used[vertex]==0:
					indices.append(vertex)
					added+=1
			assert(added%3==0,"Unreferenced town geometry must contain complete triangles")
			raw[Mesh.ARRAY_INDEX]=indices
		var complete := ArrayMesh.new()
		complete.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,raw)
		s=SurfaceTool.new()
		s.create_from(complete,0)
		if entry.key in ["board","plaster","iron","rust","wood","concrete","pole"]: s.generate_tangents()
		var node := MeshInstance3D.new()
		node.name="Town_%s_%d_%d" % [entry.key,entry.chunk.x,entry.chunk.y]
		var source: ArrayMesh=s.commit()
		var origin := Vector3((entry.chunk.x+.5)*CHUNK,0,(entry.chunk.y+.5)*CHUNK)
		var arrays: Array=source.surface_get_arrays(0)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		for i in range(vertices.size()): vertices[i]-=origin
		arrays[Mesh.ARRAY_VERTEX]=vertices
		var local := ArrayMesh.new()
		local.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		node.mesh=local
		node.position=origin
		node.material_override=materials[entry.key]
		node.visibility_range_end=world.building_range()
		if entry.key=="wire":
			node.visibility_range_end=world.building_range()
			node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		elif entry.key=="pole": node.visibility_range_end=world.building_range()+CHUNK*1.5
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
	# Native closed boxes keep supports, poles and shop fittings visible from every side.
	var primitive := BoxMesh.new()
	primitive.size=size
	var arrays: Array=primitive.surface_get_arrays(0)
	var colors := PackedColorArray()
	colors.resize((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
	colors.fill(color)
	arrays[Mesh.ARRAY_COLOR]=colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	s.append_from(mesh,0,t*Transform3D(Basis.IDENTITY,centre))

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
	refined_house(chunk,t,data,rng)

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
	ground_support(chunk,t,Vector3.ZERO,Vector3(w+0.4,0,d+0.4),0.2,"ShopFoundation")
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
	ground_support(chunk,t,Vector3(0,0,hd+ad*0.5),Vector3(w+0.2,0,ad),0.1,"ShopPorch")
	var arch: Array=[Vector2(0,0),Vector2(w,0),Vector2(w,ad),Vector2(0,ad)]
	quad(awn,t,Vector3(-hw,2.82,hd+ad),Vector3(hw,2.82,hd+ad),Vector3(hw,3.08,hd),Vector3(-hw,3.08,hd),arch,Color(0.72,0.72,0.70))
	quad(paint,t,Vector3(hw,2.8,hd+ad),Vector3(-hw,2.8,hd+ad),Vector3(-hw,3.06,hd),Vector3(hw,3.06,hd),[Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO],Color(0.3,0.3,0.29))
	var post := -hw+0.25
	while post<=hw-0.2:
		var post_pt: Vector3=t*Vector3(post,0,hd+ad-0.12)
		var post_ground: float=world.height_at(post_pt.x,post_pt.z)-t.origin.y
		var post_bottom: float=minf(-0.4,post_ground-0.4)
		var post_h: float=2.825-post_bottom
		cube(paint,t,Vector3(post,2.825-post_h*0.5,hd+ad-0.12),Vector3(0.1,post_h,0.1),Color(0.44,0.45,0.44))
		extra_boxes.append([Vector3(post,1.45,hd+ad-0.12),Vector3(0.2,2.75,0.2)])
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
		pole_sites.append(base)
		var chunk := Vector2i(floori(base.x/CHUNK),floori(base.z/CHUNK))
		var ahead: Vector3=chain[mini(i+1,chain.size()-1)]-chain[maxi(i-1,0)]
		ahead.y=0
		if ahead.length_squared()<0.01: ahead=Vector3.FORWARD
		var t := Transform3D(Basis(Vector3.UP,atan2(ahead.x,ahead.z)),base)
		var wood := tool_for(chunk,"pole")
		cube(wood,t,Vector3(0,height*0.5-0.4,0),Vector3(0.2,height+0.8,0.2),Color(0.52,0.46,0.40))
		cube(wood,t,Vector3(0,height-0.5,0),Vector3(1.7,0.1,0.1),Color(0.42,0.37,0.32))
		for off in [-.75,0,.75]: cube(wood,t,Vector3(off,height-.42,0),Vector3(.10,.15,.10),Color("d6d5bd"))
		if i==0: continue
		var from: Vector3=chain[i-1]
		var dist := from.distance_to(base)
		if dist>70.0: continue
		wire_spans.append({"from":from,"to":base,"chunk":chunk})
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
	for spot in [Vector2(-994,200),Vector2(-962,256),Vector2(-940,184),Vector2(-1010,256)]:
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
	if level<0.0:
		level=night_level
		for node in get_children():
			if not node is GeometryInstance3D: continue
			if String(node.name).begins_with("Town_") or String(node.name).begins_with("VisibleFoundations_"):
				node.visibility_range_end=world.building_range()+(CHUNK*1.5 if String(node.name).begins_with("Town_pole_") else 0.0)
	night_level=level
	var lit := smoothstep(0.35,0.85,level)
	glass.emission_energy_multiplier=lit*1.35
	for lamp in lamps: lamp.light_energy=lit*1.6



