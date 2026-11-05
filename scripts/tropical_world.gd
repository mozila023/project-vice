extends Node3D
## Efate, rendered for WebGL2 and phones: one Compatibility-renderer look on every platform,
## scaled by a quality tier. Heavy data is baked by tools/bake_world.gd so loading stays short.
const COAST := [Vector2(-.16,.92),Vector2(.12,.96),Vector2(.35,.84),Vector2(.52,.86),Vector2(.57,.65),Vector2(.72,.52),Vector2(.73,.29),Vector2(.94,.02),Vector2(.88,-.36),Vector2(.69,-.48),Vector2(.74,-.77),Vector2(.47,-.9),Vector2(.06,-.96),Vector2(-.06,-.85),Vector2(-.28,-.91),Vector2(-.41,-.71),Vector2(-.55,-.78),Vector2(-.49,-.55),Vector2(-.29,-.42),Vector2(-.36,-.21),Vector2(-.58,-.18),Vector2(-.78,-.32),Vector2(-.91,-.25),Vector2(-.78,.01),Vector2(-.79,.27),Vector2(-.68,.43),Vector2(-.65,.66),Vector2(-.43,.82),Vector2(-.27,.77)]
const TOWN := Vector2(-489,141)
const GRID_STEP := 12.0
const GRID_N := 243
const GRID_MIN := -1452.0
const BAKED := "res://assets/baked/"
## Gameplay spots: well, cooking fire, shelter, spawn. Nothing is placed on these.
const KEEP_CLEAR := [Vector2(-475,110),Vector2(-500,136),Vector2(-455,130),Vector2(-514,144)]
## low, medium, high
const TIERS := [
	{"scale":0.72,"shadow":55.0,"splits":false,"msaa":0,"glow":false,"near":85.0,"palm":55.0,"trees":0.55,"ground":1,"far_terrain":420.0,"buildings":420.0},
	{"scale":0.88,"shadow":80.0,"splits":false,"msaa":1,"glow":false,"near":130.0,"palm":80.0,"trees":0.8,"ground":2,"far_terrain":560.0,"buildings":560.0},
	{"scale":1.0,"shadow":120.0,"splits":true,"msaa":2,"glow":true,"near":190.0,"palm":115.0,"trees":1.0,"ground":3,"far_terrain":760.0,"buildings":800.0},
]
const MSAA_LEVELS := [Viewport.MSAA_DISABLED,Viewport.MSAA_2X,Viewport.MSAA_4X]
## Half width of the tarmac in metres for each mapped road class.
const ROAD_HALF := {"runway":9.0,"secondary":3.5,"tertiary":3.1,"unclassified":2.7,"residential":2.4,"service":1.9,"track":1.6}
const ROAD_SHOULDER := 1.1
const ROAD_STEP := 3.5

var noise := FastNoiseLite.new()
var rng := RandomNumberGenerator.new()
var geography := {}
var coast_field := PackedFloat32Array()
var coast_world := PackedVector2Array()
var heights := PackedFloat32Array()
var baked := {}
var surface := PackedByteArray()
var road_paths: Array[PackedVector3Array] = []
var map_texture: Texture2D
var terrain_material: ShaderMaterial
var water_material: ShaderMaterial
var sky_material: ShaderMaterial
var card_near: ShaderMaterial
var card_far: ShaderMaterial
var palm_frond: ShaderMaterial
var environment: Environment
var sun: DirectionalLight3D
var fill: DirectionalLight3D
var sea: MeshInstance3D
var ground_cover: Node3D
var tree_nodes: Array[Dictionary] = []
var range_nodes: Array[Dictionary] = []
var night_listeners: Array[Callable] = []
var tier := 2
var last_hour := -99.0
var last_view := Vector3(1e9,0,0)
var perf_time := 0.0
var perf_frames := 0
var perf_grace := 6.0
var auto_quality := true
var tree_count := 0
var triangle_count := 0

func _init() -> void:
	noise.seed=1847
	noise.frequency=0.0035
	noise.fractal_octaves=4
	for p in COAST: coast_world.append(Vector2(p.x*940,-p.y*1050))
	rng.seed=4702
	geography=JSON.parse_string(FileAccess.get_file_as_string("res://assets/geography/efate-game-map.json"))
	coast_field=FileAccess.get_file_as_bytes("res://assets/geography/coast-distance.bin").to_float32_array()

func coast_distance(p: Vector2) -> float:
	var uv := ((p+Vector2(1440,1440))/12).clamp(Vector2.ZERO,Vector2(239.999,239.999))
	var x := floori(uv.x)
	var z := floori(uv.y)
	var a := lerpf(coast_field[z*241+x],coast_field[z*241+x+1],uv.x-x)
	var b := lerpf(coast_field[(z+1)*241+x],coast_field[(z+1)*241+x+1],uv.x-x)
	return lerpf(a,b,uv.y-z)

## Source terrain function, used only while baking.
func raw_height(x: float,z: float) -> float:
	var p := Vector2(x,z)
	var edge := coast_distance(p)
	if edge<0: return -0.5-minf(-edge*0.1,32)
	var radius := Vector2(x/900.0,z/1100.0).length()
	var hill := pow(maxf(0,1-radius),1.55)*185
	var detail := noise.get_noise_2d(x,z)*33+absf(noise.get_noise_2d(x+710,z-150))*22
	var town_flat := smoothstep(115.0,235.0,p.distance_to(TOWN))
	var inland := 3.5+maxf(0,hill+detail)*town_flat
	var shelf := lerpf(-0.45,3.1,smoothstep(0.0,32.0,edge))
	return shelf+maxf(0,inland-3.1)*smoothstep(32.0,180.0,edge)

## Exact surface of the rendered terrain mesh, so anything placed on it sits flush.
func height_at(x: float,z: float) -> float:
	if heights.is_empty(): return raw_height(x,z)
	var u := clampf((x-GRID_MIN)/GRID_STEP,0.0,GRID_N-1.001)
	var v := clampf((z-GRID_MIN)/GRID_STEP,0.0,GRID_N-1.001)
	var ix := int(u)
	var iz := int(v)
	var fx := u-ix
	var fz := v-iz
	var k := iz*GRID_N+ix
	var a := heights[k]
	var b := heights[k+1]
	var c := heights[k+GRID_N]
	var d := heights[k+GRID_N+1]
	if fx+fz<=1.0: return a+(b-a)*fx+(c-a)*fz
	return d+(c-d)*(1.0-fx)+(b-d)*(1.0-fz)

## Elevation in one byte: fine steps around sea level for the shoreline, wide range offshore.
func encode_elevation(h: float) -> float:
	if h>=0.0: return 0.5+minf(h,8.0)/16.0
	return 0.5-0.5*sqrt(minf(-h,33.0)/33.0)

func surface_class(x: float,z: float) -> int:
	var cell := 2880.0/720
	var ix := int((x+1440.0)/cell)
	var iz := int((z+1440.0)/cell)
	if ix<0 or iz<0 or ix>=720 or iz>=720 or surface.is_empty(): return 0
	return surface[iz*720+ix]

func build() -> void:
	name="TropicalEnvironment"
	var t0 := Time.get_ticks_msec()
	baked=bytes_to_var(FileAccess.get_file_as_bytes(BAKED+"world.dat"))
	heights=baked.heights
	surface=baked.surface
	map_texture=load(BAKED+"terrain_macro.png")
	tier=detect_tier()
	create_lighting()
	create_materials()
	create_terrain()
	create_roads()
	create_ocean()
	create_vegetation()
	create_rocks()
	index_trunks()
	index_roads()
	ground_cover=preload("res://scripts/ground_cover.gd").new()
	ground_cover.world=self
	add_child(ground_cover)
	apply_tier()

func detect_tier() -> int:
	var result := 2
	if OS.has_feature("web") or OS.has_feature("mobile"): result=1
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"): result=0
	if OS.has_feature("web") and DisplayServer.is_touchscreen_available(): result=0
	if OS.has_feature("web"):
		# ?quality=low|medium|high pins the tier for testing or on request.
		var wanted=JavaScriptBridge.eval("new URLSearchParams(location.search).get('quality')||''",true)
		var index := ["low","medium","high"].find(str(wanted))
		if index>=0:
			auto_quality=false
			result=index
	return result

func apply_tier() -> void:
	var q: Dictionary=TIERS[tier]
	var view := get_viewport()
	view.scaling_3d_scale=q.scale
	view.msaa_3d=MSAA_LEVELS[q.msaa]
	sun.directional_shadow_max_distance=q.shadow
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if q.splits else DirectionalLight3D.SHADOW_ORTHOGONAL
	environment.glow_enabled=q.glow
	environment.adjustment_enabled=q.glow
	card_near.set_shader_parameter("near_range",q.near)
	card_far.set_shader_parameter("near_range",q.near)
	card_far.set_shader_parameter("palm_range",q.palm)
	for entry in tree_nodes:
		entry.mm.visible_instance_count=maxi(1,int(entry.count*q.trees))
	for entry in range_nodes:
		match entry.kind:
			"tree": entry.node.visibility_range_end=q.near+175.0
			"palm": entry.node.visibility_range_end=q.palm+40.0
			"terrain_hi": entry.node.visibility_range_end=q.far_terrain
			"terrain_lo": entry.node.visibility_range_begin=q.far_terrain
			"rock": entry.node.visibility_range_end=q.near+120.0
	terrain_material.shader=load("res://shaders/island_terrain_low.gdshader" if tier==0 else "res://shaders/island_terrain.gdshader")
	water_material.set_shader_parameter("detail",0.0 if tier==0 else 1.0)
	if ground_cover: ground_cover.set_radius(q.ground)
	for listener in night_listeners: listener.call(-1.0)

func building_range() -> float:
	return TIERS[tier].buildings

## Called every frame with the camera position.
func update_view(view: Vector3,hour: float,dt: float) -> void:
	sea.position=Vector3(snappedf(view.x,16.0),0,snappedf(view.z,16.0))
	if view.distance_squared_to(last_view)>1.0:
		last_view=view
		card_near.set_shader_parameter("view_pos",view)
		card_far.set_shader_parameter("view_pos",view)
		ground_cover.material.set_shader_parameter("view_pos",view)
	ground_cover.update(view)
	update_daylight(hour)
	if auto_quality and tier>0:
		perf_grace-=dt
		if perf_grace<=0.0:
			perf_time+=dt
			perf_frames+=1
			if perf_time>=4.0:
				if perf_frames/perf_time<27.0:
					tier-=1
					apply_tier()
					perf_grace=6.0
				perf_time=0.0
				perf_frames=0

func create_lighting() -> void:
	var world := WorldEnvironment.new()
	environment=Environment.new()
	var sky := Sky.new()
	sky_material=ShaderMaterial.new()
	sky_material.shader=load("res://shaders/sky.gdshader")
	sky_material.set_shader_parameter("panorama",load("res://assets/environment/tropical_sky.hdr"))
	sky.sky_material=sky_material
	sky.radiance_size=Sky.RADIANCE_SIZE_64
	sky.process_mode=Sky.PROCESS_MODE_QUALITY
	environment.background_mode=Environment.BG_SKY
	environment.sky=sky
	environment.sky_rotation.y=1.4
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
	environment.reflected_light_source=Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode=Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure=1.0
	environment.tonemap_white=7.0
	environment.fog_enabled=true
	environment.fog_mode=Environment.FOG_MODE_EXPONENTIAL
	environment.fog_density=0.00032
	environment.fog_sky_affect=0.0
	environment.fog_sun_scatter=0.15
	environment.glow_intensity=0.35
	environment.glow_strength=0.9
	environment.glow_bloom=0.02
	environment.glow_hdr_threshold=1.2
	environment.glow_blend_mode=Environment.GLOW_BLEND_MODE_SOFTLIGHT
	environment.adjustment_saturation=0.97
	environment.adjustment_contrast=1.04
	world.environment=environment
	add_child(world)
	sun=DirectionalLight3D.new()
	sun.name="TropicalSun"
	sun.shadow_enabled=true
	sun.shadow_opacity=0.86
	sun.shadow_blur=2.0
	sun.shadow_normal_bias=1.4
	# Shadows melt away with distance and across cascades rather than ending at a visible line.
	sun.directional_shadow_blend_splits=true
	sun.directional_shadow_fade_start=0.7
	add_child(sun)
	# Sky and ground bounce: this renderer has no global illumination, so unlit walls would otherwise go near black.
	fill=DirectionalLight3D.new()
	fill.name="BounceFill"
	fill.shadow_enabled=false
	fill.light_specular=0.0
	fill.sky_mode=DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	add_child(fill)

## Solar path for Efate (17.7 S): rises in the east, passes to the north.
func update_daylight(hour: float,force := false) -> void:
	if not force and absf(hour-last_hour)<0.02: return
	var radiance_changed := absf(hour-last_hour)>=0.12 or force
	var sun_angle := (hour-6.0)/12.0*PI
	var height := sin(sun_angle)
	var sun_dir := Vector3(cos(sun_angle),height*0.94,-height*0.34).normalized()
	var day := smoothstep(-0.22,0.10,height)
	var low := 1.0-smoothstep(0.02,0.45,height)
	var moon_dir := Vector3(-0.35,0.8,0.48).normalized()
	var night := 1.0-day
	var light_dir := sun_dir if height>-0.06 else moon_dir
	var up := Vector3.UP if absf(light_dir.y)<0.99 else Vector3.FORWARD
	sun.global_transform=Transform3D(Basis.looking_at(-light_dir,up),Vector3.ZERO)
	var warm := Color(1.0,0.97,0.90).lerp(Color(1.0,0.58,0.30),low)
	if height>-0.06:
		sun.light_color=warm
		sun.light_energy=lerpf(0.0,1.3,smoothstep(-0.06,0.26,height))
	else:
		sun.light_color=Color(0.55,0.68,1.0)
		sun.light_energy=0.42*smoothstep(-0.06,-0.24,height)
	var bounce := Vector3(-sun_dir.x,maxf(absf(sun_dir.y)*0.35,0.2),-sun_dir.z).normalized()
	fill.global_transform=Transform3D(Basis.looking_at(-bounce,Vector3.UP),Vector3.ZERO)
	fill.light_color=Color(0.86,0.92,0.82).lerp(Color(1.0,0.76,0.58),low)
	fill.light_energy=0.22*day
	environment.ambient_light_energy=lerpf(0.55,0.86,day)
	environment.background_energy_multiplier=1.0
	var haze := Color(0.68,0.80,0.90).lerp(Color(0.93,0.66,0.46),low*day).lerp(Color(0.025,0.04,0.075),night)
	environment.fog_light_color=haze
	environment.fog_light_energy=lerpf(0.35,1.0,day)
	if radiance_changed:
		sky_material.set_shader_parameter("day",day)
		sky_material.set_shader_parameter("dusk",low*day)
	terrain_material.set_shader_parameter("sun_strength",day)
	water_material.set_shader_parameter("sun_strength",day)
	water_material.set_shader_parameter("night",night)
	for listener in night_listeners: listener.call(night)
	last_hour=hour

func settlement_night() -> float:
	return 1.0-smoothstep(-0.22,0.10,sin((last_hour-6.0)/12.0*PI))

func tex(file: String) -> Texture2D:
	return load("res://assets/environment/"+file+".jpg")

func create_materials() -> void:
	terrain_material=ShaderMaterial.new()
	terrain_material.shader=load("res://shaders/island_terrain.gdshader")
	var maps := {"sand":"coast_sand_01","grass":"leafy_grass","rock":"rocky_terrain","forest":"forest_leaves_02"}
	for key in maps:
		terrain_material.set_shader_parameter(key+"_tex",tex(maps[key]+"_Diffuse"))
		if key!="forest": terrain_material.set_shader_parameter(key+"_normal",tex(maps[key]+"_nor_gl"))
	terrain_material.set_shader_parameter("macro_map",map_texture)
	terrain_material.set_shader_parameter("data_map",load(BAKED+"terrain_data.png"))
	terrain_material.set_shader_parameter("noise_tex",load(BAKED+"noise.png"))
	water_material=ShaderMaterial.new()
	water_material.shader=load("res://shaders/lagoon.gdshader")
	water_material.set_shader_parameter("data_map",load(BAKED+"terrain_data.png"))
	water_material.set_shader_parameter("noise_tex",load(BAKED+"noise.png"))
	water_material.set_shader_parameter("normal_tex",load(BAKED+"water_normal.png"))
	card_near=ShaderMaterial.new()
	card_near.shader=load("res://shaders/foliage.gdshader")
	card_far=ShaderMaterial.new()
	card_far.shader=load("res://shaders/foliage_far.gdshader")
	var atlas: Texture2D=load(BAKED+"foliage_trees.png")
	card_near.set_shader_parameter("atlas",atlas)
	card_far.set_shader_parameter("atlas",atlas)
	palm_frond=ShaderMaterial.new()
	palm_frond.shader=load("res://shaders/palm_frond.gdshader")
	palm_frond.set_shader_parameter("frond",load(BAKED+"palm_frond.png"))

func create_terrain() -> void:
	# Two detail levels per 240 m chunk; deep seabed that can never show is skipped.
	var n := GRID_N
	var shared_rock := false
	for cz in range(-6,6):
		for cx in range(-6,6):
			var base_x := (cx+6)*20+1
			var base_z := (cz+6)*20+1
			var highest := -1000.0
			for z in range(21):
				for x in range(21):
					highest=maxf(highest,heights[(base_z+z)*n+base_x+x])
			if highest<-7.0: continue
			var hi := chunk_mesh(base_x,base_z,1)
			var lo := chunk_mesh(base_x,base_z,4)
			for pair in [[hi,"terrain_hi"],[lo,"terrain_lo"]]:
				var node := MeshInstance3D.new()
				node.name="Terrain_%d_%d_%s" % [cx,cz,pair[1]]
				node.mesh=pair[0]
				node.material_override=terrain_material
				node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				add_child(node)
				range_nodes.append({"node":node,"kind":pair[1]})
	# One height-field body is far cheaper to create and query than per-chunk triangle meshes.
	var body := StaticBody3D.new()
	body.name="TerrainCollision"
	body.collision_layer=16
	var shape := HeightMapShape3D.new()
	shape.map_width=n
	shape.map_depth=n
	shape.map_data=heights
	var collision := CollisionShape3D.new()
	collision.shape=shape
	collision.scale=Vector3(GRID_STEP,1.0,GRID_STEP)
	body.add_child(collision)
	add_child(body)

func chunk_mesh(base_x: int,base_z: int,stride: int) -> ArrayMesh:
	var n := GRID_N
	var side := 20/stride+1
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	vertices.resize(side*side)
	normals.resize(side*side)
	for z in range(side):
		for x in range(side):
			var gx := base_x+x*stride
			var gz := base_z+z*stride
			var k := gz*n+gx
			vertices[z*side+x]=Vector3(GRID_MIN+gx*GRID_STEP,heights[k],GRID_MIN+gz*GRID_STEP)
			normals[z*side+x]=Vector3(heights[k-1]-heights[k+1],2.0*GRID_STEP,heights[k-n]-heights[k+n]).normalized()
	for z in range(side-1):
		for x in range(side-1):
			var k := z*side+x
			indices.append_array(PackedInt32Array([k,k+1,k+side,k+1,k+side+1,k+side]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

func create_ocean() -> void:
	# A single camera-centred grid out to the horizon: dense under the player, sparse at distance.
	var side := 97
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	vertices.resize(side*side)
	for z in range(side):
		for x in range(side):
			var u := (x-48)/48.0
			var v := (z-48)/48.0
			vertices[z*side+x]=Vector3(signf(u)*pow(absf(u),2.6)*7000.0+u*50.0,0,signf(v)*pow(absf(v),2.6)*7000.0+v*50.0)
	for z in range(side-1):
		for x in range(side-1):
			var k := z*side+x
			indices.append_array(PackedInt32Array([k,k+1,k+side,k+1,k+side+1,k+side]))
	var normals := PackedVector3Array()
	normals.resize(side*side)
	normals.fill(Vector3.UP)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	sea=MeshInstance3D.new()
	sea.name="Ocean"
	sea.mesh=mesh
	sea.material_override=water_material
	sea.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sea.extra_cull_margin=100.0
	add_child(sea)

func multimesh_node(mesh: Mesh,chunk: Dictionary,material: Material) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.use_custom_data=true
	mm.mesh=mesh
	mm.instance_count=chunk.count
	mm.buffer=chunk.buffer
	# Keep both near/far vegetation out of the walkable Sunshine parcel.
	for i in range(chunk.count):
		var placement := mm.get_instance_transform(i)
		var p: Vector3=chunk.centre+placement.origin
		if preload("res://scripts/sunshine_spa.gd").reserved(p.x,p.z,1.5):
			placement.basis=Basis(Vector3.ZERO,Vector3.ZERO,Vector3.ZERO)
			mm.set_instance_transform(i,placement)
	var node := MultiMeshInstance3D.new()
	node.multimesh=mm
	if material: node.material_override=material
	node.position=chunk.centre
	add_child(node)
	return node

func create_vegetation() -> void:
	var flora=preload("res://scripts/flora.gd").new()
	var cross: ArrayMesh=flora.cross_card()
	var card: ArrayMesh=flora.billboard_card()
	var palm: ArrayMesh=flora.palm_mesh()
	var bark := StandardMaterial3D.new()
	bark.albedo_texture=load(BAKED+"palm_bark.png")
	bark.roughness=0.95
	palm.surface_set_material(0,bark)
	palm.surface_set_material(1,palm_frond)
	for chunk in baked.trees:
		tree_count+=chunk.count
		var near_node := multimesh_node(cross,chunk,card_near)
		near_node.name="TreesNear"
		range_nodes.append({"node":near_node,"kind":"tree"})
		tree_nodes.append({"mm":near_node.multimesh,"count":chunk.count})
		var far_node := multimesh_node(card,chunk,card_far)
		far_node.name="TreesFar"
		far_node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tree_nodes.append({"mm":far_node.multimesh,"count":chunk.count})
	for chunk in baked.palm_far:
		tree_count+=chunk.count
		var far_node := multimesh_node(card,chunk,card_far)
		far_node.name="PalmsFar"
		far_node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for chunk in baked.palms:
		var node := multimesh_node(palm,chunk,null)
		node.name="Palms"
		range_nodes.append({"node":node,"kind":"palm"})

func create_rocks() -> void:
	var data: PackedFloat32Array=baked.rocks
	var mesh: ArrayMesh=preload("res://scripts/props.gd").new().rock_mesh()
	var material := StandardMaterial3D.new()
	material.albedo_texture=tex("rocky_terrain_Diffuse")
	material.albedo_color=Color(0.72,0.70,0.64)
	material.normal_enabled=true
	material.normal_texture=tex("rocky_terrain_nor_gl")
	material.uv1_scale=Vector3(1.4,1.4,1.4)
	material.roughness=0.95
	var groups := {}
	for i in range(0,data.size(),5):
		var key := Vector2i(floori(data[i]/240.0),floori(data[i+2]/240.0))
		if not groups.has(key): groups[key]=[]
		groups[key].append(i)
	for key in groups:
		var list: Array=groups[key]
		var mm := MultiMesh.new()
		mm.transform_format=MultiMesh.TRANSFORM_3D
		mm.mesh=mesh
		mm.instance_count=list.size()
		var centre := Vector3((key.x+0.5)*240.0,0,(key.y+0.5)*240.0)
		for j in range(list.size()):
			var i: int=list[j]
			var scale: float=data[i+3]
			var basis := Basis(Vector3.UP,data[i+4]).scaled(Vector3(scale,scale*rng.randf_range(0.55,0.9),scale*rng.randf_range(0.8,1.2)))
			mm.set_instance_transform(j,Transform3D(basis,Vector3(data[i],data[i+1]-scale*0.12,data[i+2])-centre))
		var node := MultiMeshInstance3D.new()
		node.name="Rocks"
		node.multimesh=mm
		node.material_override=material
		node.position=centre
		add_child(node)
		range_nodes.append({"node":node,"kind":"rock"})

func road_half(type: String) -> float:
	return ROAD_HALF.get(type,2.4)

const ROAD_CELL := 20.0
var road_grid := {}

func index_roads() -> void:
	for road in geography.get("roads",[]):
		var half: float=road_half(road.type)
		var pts: Array=road.points
		for i in range(pts.size()-1):
			var a := Vector2(pts[i][0],pts[i][1])
			var b := Vector2(pts[i+1][0],pts[i+1][1])
			var steps := maxi(1,ceili(a.distance_to(b)/(ROAD_CELL*0.5)))
			var seen := {}
			for k in range(steps+1):
				var p := a.lerp(b,float(k)/steps)
				var key := Vector2i(floori(p.x/ROAD_CELL),floori(p.y/ROAD_CELL))
				for oz in range(-1,2):
					for ox in range(-1,2):
						var near := key+Vector2i(ox,oz)
						if seen.has(near): continue
						seen[near]=true
						if not road_grid.has(near): road_grid[near]=[]
						road_grid[near].append([a,b,half])

## Whether a point is on the tarmac of a mapped road. Used to slow cars on rough ground.
func is_on_road(x: float,z: float) -> bool:
	var p := Vector2(x,z)
	for segment in road_grid.get(Vector2i(floori(x/ROAD_CELL),floori(z/ROAD_CELL)),[]):
		if Geometry2D.get_closest_point_to_segment(p,segment[0],segment[1]).distance_to(p)<=segment[2]+0.6: return true
	return false

## Visual thickness of the road mesh (+0.10m on tarmac, tapering across the shoulder to 0 off-road).
func road_surface_offset(x: float,z: float) -> float:
	if height_at(x,z)<0.3: return 0.0
	var p := Vector2(x,z)
	var best := 0.0
	for segment in road_grid.get(Vector2i(floori(x/ROAD_CELL),floori(z/ROAD_CELL)),[]):
		var d: float=Geometry2D.get_closest_point_to_segment(p,segment[0],segment[1]).distance_to(p)
		var half: float=segment[2]
		if d<=half+ROAD_SHOULDER:
			var w: float=1.0-smoothstep(half,half+ROAD_SHOULDER,d)
			best=maxf(best,0.10*w)
	return best

## Rendered surface height (terrain plus road mesh thickness when on a road).
func surface_height_at(x: float,z: float) -> float:
	return height_at(x,z)+road_surface_offset(x,z)

## Tree and palm trunks collide, built only around the player: thousands of them would be slow to create at load.
## They sit on their own layer so the camera arm passes through instead of jittering on every trunk.
const TREE_CELL := 60.0
const TREE_REACH := 2
const TREE_LAYER := 8
var trunk_groups := {}
var trunk_bodies := {}
var trunk_shape_tree: RID
var trunk_shape_palm: RID
var trunk_cell := Vector2i(1<<30,0)

func index_trunks() -> void:
	trunk_shape_tree=PhysicsServer3D.cylinder_shape_create()
	PhysicsServer3D.shape_set_data(trunk_shape_tree,{"radius":0.45,"height":7.0})
	trunk_shape_palm=PhysicsServer3D.cylinder_shape_create()
	PhysicsServer3D.shape_set_data(trunk_shape_palm,{"radius":0.24,"height":7.0})
	for chunk in baked.trees: group_trunks(chunk,true)
	for chunk in baked.palms: group_trunks(chunk,false)

func group_trunks(chunk: Dictionary,is_tree: bool) -> void:
	var buffer: PackedFloat32Array=chunk.buffer
	var visible_count: int=int(chunk.count*TIERS[tier].trees) if is_tree else chunk.count
	for i in range(mini(chunk.count,maxi(visible_count,1))):
		var at: int=i*16
		# Row two of the atlas holds bushes, which the player can push through.
		if is_tree and buffer[at+13]>0.5: continue
		var p: Vector3=chunk.centre+Vector3(buffer[at+3],buffer[at+7],buffer[at+11])
		if preload("res://scripts/sunshine_spa.gd").reserved(p.x,p.z,1.5): continue
		var key := Vector2i(floori(p.x/TREE_CELL),floori(p.z/TREE_CELL))
		if not trunk_groups.has(key): trunk_groups[key]=[]
		trunk_groups[key].append([p,is_tree])

func update_tree_collision(view: Vector3) -> void:
	var cell := Vector2i(floori(view.x/TREE_CELL),floori(view.z/TREE_CELL))
	if cell==trunk_cell: return
	trunk_cell=cell
	for key in trunk_bodies.keys():
		if absi(key.x-cell.x)>TREE_REACH+1 or absi(key.y-cell.y)>TREE_REACH+1:
			PhysicsServer3D.free_rid(trunk_bodies[key])
			trunk_bodies.erase(key)
	for oz in range(cell.y-TREE_REACH,cell.y+TREE_REACH+1):
		for ox in range(cell.x-TREE_REACH,cell.x+TREE_REACH+1):
			var key := Vector2i(ox,oz)
			if trunk_bodies.has(key) or not trunk_groups.has(key): continue
			var body: RID=PhysicsServer3D.body_create()
			PhysicsServer3D.body_set_mode(body,PhysicsServer3D.BODY_MODE_STATIC)
			PhysicsServer3D.body_set_space(body,get_world_3d().space)
			PhysicsServer3D.body_set_collision_layer(body,TREE_LAYER)
			PhysicsServer3D.body_set_collision_mask(body,0)
			for entry in trunk_groups[key]:
				var shape: RID=trunk_shape_tree if entry[1] else trunk_shape_palm
				PhysicsServer3D.body_add_shape(body,shape,Transform3D(Basis.IDENTITY,entry[0]+Vector3.UP*3.5))
			trunk_bodies[key]=body

func _exit_tree() -> void:
	for key in trunk_bodies: PhysicsServer3D.free_rid(trunk_bodies[key])
	trunk_bodies.clear()
	if trunk_shape_tree.is_valid(): PhysicsServer3D.free_rid(trunk_shape_tree)
	if trunk_shape_palm.is_valid(): PhysicsServer3D.free_rid(trunk_shape_palm)

func create_roads() -> void:
	var road_material := ShaderMaterial.new()
	road_material.shader=load("res://shaders/road.gdshader")
	road_material.set_shader_parameter("asphalt_tex",tex("asphalt_02_Diffuse"))
	road_material.set_shader_parameter("asphalt_normal",tex("asphalt_02_nor_gl"))
	road_material.set_shader_parameter("noise_tex",load(BAKED+"noise.png"))
	road_material.set_shader_parameter("shoulder",ROAD_SHOULDER)
	# Split by area so distant road geometry can be culled individually.
	var tools := {}
	# The map lists minor roads first, so main roads are drawn on top at every junction.
	for road in geography.get("roads",[]):
		var points := PackedVector3Array()
		for p in road.points:
			points.append(Vector3(p[0],height_at(p[0],p[1])+0.12,p[1]))
		if points.size()<2: continue
		road_paths.append(points)
		var half: float=road_half(road.type)
		var paved: float=1.0 if road.paved else 0.0
		var main_road: bool=road.type in ["secondary","runway"] and road.paved
		var marking := Color(paved,1.0 if main_road else 0.0,1.0 if road.type=="runway" else 0.0,1.0)
		var total_length := 0.0
		for i in range(points.size()-1): total_length+=Vector2(points[i].x,points[i].z).distance_to(Vector2(points[i+1].x,points[i+1].z))
		var open_ends: Array=road.get("open",[false,false])
		# Mitred offsets at each point, so bends join with no wedge-shaped gaps.
		var sides := PackedVector3Array()
		sides.resize(points.size())
		for i in range(points.size()):
			var before := Vector3(points[i].x-points[maxi(i-1,0)].x,0,points[i].z-points[maxi(i-1,0)].z).normalized()
			var after := Vector3(points[mini(i+1,points.size()-1)].x-points[i].x,0,points[mini(i+1,points.size()-1)].z-points[i].z).normalized()
			var middle := before+after
			if middle.length_squared()<0.001: middle=after if after.length_squared()>0.5 else Vector3.FORWARD
			middle=middle.normalized()
			var reference := after if after.length_squared()>0.5 else before
			sides[i]=middle.cross(Vector3.UP)/maxf(0.55,middle.dot(reference))
		var run := 0.0
		for i in range(points.size()-1):
			var a := points[i]
			var b := points[i+1]
			var flat := Vector3(b.x-a.x,0,b.z-a.z)
			if flat.length_squared()<0.01: continue
			var steps := maxi(1,ceili(flat.length()/ROAD_STEP))
			for j in range(steps):
				var f0 := float(j)/steps
				var f1 := float(j+1)/steps
				var from := a.lerp(b,f0)
				var to := a.lerp(b,f1)
				var length := from.distance_to(to)
				var key := Vector2i(floori(from.x/300.0),floori(from.z/300.0))
				# Long water crossings the bake could not carry on a causeway stay off the sea.
				if height_at(from.x,from.z)>=0.3 and height_at(to.x,to.z)>=0.3:
					if not tools.has(key): tools[key]=road_arrays()
					var fade0 := road_end_fade(run,total_length,open_ends)
					var fade1 := road_end_fade(run+length,total_length,open_ends)
					road_strip(tools[key],from,to,sides[i].lerp(sides[i+1],f0),sides[i].lerp(sides[i+1],f1),run,run+length,half,marking,fade0,fade1)
				run+=length
	for key in tools:
		var data: Dictionary=tools[key]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX]=data.vertices
		arrays[Mesh.ARRAY_NORMAL]=data.normals
		arrays[Mesh.ARRAY_TEX_UV]=data.uvs
		arrays[Mesh.ARRAY_TEX_UV2]=data.uvs2
		arrays[Mesh.ARRAY_COLOR]=data.colors
		arrays[Mesh.ARRAY_INDEX]=data.indices
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var node := MeshInstance3D.new()
		node.name="Road_%d_%d" % [key.x,key.y]
		node.mesh=mesh
		node.material_override=road_material
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# The shader fades the road out before this range; the baked map carries it beyond.
		node.visibility_range_end=900.0
		node.extra_cull_margin=2.0
		add_child(node)

func road_arrays() -> Dictionary:
	return {"vertices":PackedVector3Array(),"normals":PackedVector3Array(),"uvs":PackedVector2Array(),"uvs2":PackedVector2Array(),"colors":PackedColorArray(),"indices":PackedInt32Array()}

func road_end_fade(at: float,total: float,open_ends: Array) -> float:
	var fade := 1.0
	if open_ends[0]: fade=minf(fade,clampf(at/5.0,0.0,1.0))
	if open_ends[1]: fade=minf(fade,clampf((total-at)/5.0,0.0,1.0))
	return fade

func ground_normal(x: float,z: float) -> Vector3:
	return Vector3(height_at(x-3.0,z)-height_at(x+3.0,z),6.0,height_at(x,z-3.0)-height_at(x,z+3.0)).normalized()

func road_strip(data: Dictionary,from: Vector3,to: Vector3,side_from: Vector3,side_to: Vector3,v0: float,v1: float,half: float,marking: Color,fade0: float,fade1: float) -> void:
	# Across the road: worn shoulder, tarmac, shoulder. The shader dissolves the outer edges into the verge.
	var limit: float=half+ROAD_SHOULDER
	var offsets: Array[float]=[-limit,-half,0.0,half,limit]
	var base: int=data.vertices.size()
	for row in [[from,side_from,v0,fade0],[to,side_to,v1,fade1]]:
		var centre: Vector3=row[0]
		var normal := ground_normal(centre.x,centre.z)
		var color := marking
		# Where a road runs into the shallows it fades out across the sand instead of being cut off.
		color.a=row[3]*smoothstep(0.35,1.0,height_at(centre.x,centre.z))
		for o in offsets:
			var at: Vector3=centre+row[1]*o
			at.y=height_at(at.x,at.z)+0.1
			data.vertices.append(at)
			data.normals.append(normal)
			data.uvs.append(Vector2(o/limit,row[2]))
			data.uvs2.append(Vector2(half,0.0))
			data.colors.append(color)
	for i in range(4):
		data.indices.append_array(PackedInt32Array([base+i,base+5+i,base+i+1,base+i+1,base+5+i,base+6+i]))



