extends Node3D
## Small real-time opening: boarding, flight, and arrival. No video downloads.
var screen := "menu"
var clock := 0.0
var intro_time := 0.0
var loading := false
var camera: Camera3D
var plane: Node3D
var apron: Node3D
var cabin: Node3D
var clouds: Node3D
var sea: MeshInstance3D
var distant_island: MeshInstance3D
var island: Node3D
var island_environment: WorldEnvironment
var front_environment: WorldEnvironment
var island_env_resource: Environment
var front_env_resource: Environment
var traveler: Node3D
var front_sun: DirectionalLight3D
var boarding: Node3D
var view: Control
var ambience: AudioStreamPlayer
const SHOTS := [7.5,16.0,25.0]
const CAPTIONS := [
	["One bag. A letter from Malia. A place you've never called home.","กระเป๋าหนึ่งใบ จดหมายจากมาเลีย และเกาะที่ยังไม่เคยเรียกว่าบ้าน"],
	["She wrote: ‘The storm has passed. Come when you're ready. We'll keep a place for you.’","เธอเขียนว่า ‘พายุผ่านไปแล้ว ถ้าพร้อมเมื่อไรก็มา เราจะรอเธออยู่ที่นี่’"],
	["Below the clouds: Efate. Somewhere along that coast, a new beginning.","ใต้หมู่เมฆคือเอฟาเต ที่ไหนสักแห่งริมฝั่งนั้น ชีวิตบทใหม่กำลังรออยู่"]
]

func _ready() -> void:
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	build_scene()
	var layer := CanvasLayer.new()
	add_child(layer)
	view=preload("res://scripts/front_view.gd").new()
	view.front=self
	layer.add_child(view)
	set_intro_pose(0.0)

func material(color: Color,roughness := 0.6) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color=color
	mat.roughness=roughness
	return mat

func box(parent: Node3D,at: Vector3,dimensions: Vector3,color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size=dimensions
	mesh.material=material(color)
	node.mesh=mesh
	node.position=at
	parent.add_child(node)
	return node

func bounds(root: Node3D) -> AABB:
	var result := AABB()
	var found := false
	for mesh: MeshInstance3D in root.find_children("*","MeshInstance3D",true,false):
		var transform := Transform3D.IDENTITY
		var cursor: Node3D=mesh
		while cursor!=root:
			transform=cursor.transform*transform
			cursor=cursor.get_parent()
		var aabb: AABB=transform*mesh.get_aabb()
		result=result.merge(aabb) if found else aabb
		found=true
	return result

func build_scene() -> void:
	var env := WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_SKY
	var sky := Sky.new()
	var atmosphere := ShaderMaterial.new()
	atmosphere.shader=preload("res://shaders/sky.gdshader")
	atmosphere.set_shader_parameter("panorama",preload("res://assets/environment/tropical_sky.hdr"))
	sky.sky_material=atmosphere
	env.environment.sky=sky
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_SKY
	env.environment.ambient_light_energy=0.35
	env.environment.tonemap_mode=Environment.TONE_MAPPER_ACES
	env.environment.tonemap_exposure=0.8
	add_child(env)
	front_environment=env
	front_env_resource=env.environment
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-27,-38,0)
	sun.light_color=Color("fff0d0")
	sun.light_energy=0.8
	sun.shadow_enabled=true
	sun.directional_shadow_max_distance=85
	add_child(sun)
	front_sun=sun
	camera=Camera3D.new()
	camera.fov=48
	camera.far=4000
	add_child(camera)
	camera.current=true
	plane=Node3D.new()
	add_child(plane)
	var model: Node3D=preload("res://assets/models/aircraft/Cesium_Air.glb").instantiate()
	plane.add_child(model)
	# Keep the asset's metre units. Its longest horizontal axis is the wingspan,
	# not the fuselage. Centre only after applying the display heading.
	model.rotation.y=PI/2
	var bound := bounds(plane)
	model.position=Vector3(-bound.get_center().x,-bound.position.y,-bound.get_center().z)
	for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		for i in range(mesh.mesh.get_surface_count()):
			var mat=mesh.get_active_material(i)
			if mat is StandardMaterial3D:
				mat=mat.duplicate()
				mat.roughness=maxf(mat.roughness,0.3)
				mat.albedo_color=Color(0.78,0.78,0.78)
				mesh.set_surface_override_material(i,mat)
	apron=Node3D.new()
	add_child(apron)
	var floor=box(apron,Vector3(0,-0.1,0),Vector3(250,0.2,250),Color.WHITE)
	var tarmac := material(Color("b9b9ac"),0.95)
	tarmac.albedo_texture=preload("res://assets/environment/asphalt_02_Diffuse.jpg")
	tarmac.uv1_scale=Vector3(35,35,35)
	floor.material_override=tarmac
	for i in range(14): box(apron,Vector3(-18,0.025,-65+i*10),Vector3(0.3,0.03,5),Color("e6d3a2"))
	var apron_props: Node3D=preload("res://assets/models/aircraft/airport_apron_props.glb").instantiate()
	apron.add_child(apron_props)
	boarding=preload("res://scripts/boarding_sequence.gd").new()
	boarding.name="Boarding"
	apron.add_child(boarding)
	boarding.build(plane)
	# A separate compact interior shot sculpted in Blender; its window is a real opening, not a still image.
	cabin=preload("res://assets/models/aircraft/aircraft_cabin.glb").instantiate()
	cabin.name="Cabin"
	add_child(cabin)
	for mesh: MeshInstance3D in cabin.find_children("*","MeshInstance3D",true,false):
		for i in range(mesh.mesh.get_surface_count()):
			var mat=mesh.get_active_material(i)
			if mat is StandardMaterial3D:
				mat=mat.duplicate()
				mat.cull_mode=BaseMaterial3D.CULL_DISABLED
				mesh.set_surface_override_material(i,mat)
	clouds=Node3D.new()
	add_child(clouds)
	var cloud_mat := material(Color("e6e7e2"),1)
	for i in range(25):
		var cloud := MeshInstance3D.new()
		var puff := SphereMesh.new()
		puff.radial_segments=16
		puff.rings=8
		puff.material=cloud_mat
		cloud.mesh=puff
		cloud.position=Vector3(-80.0+(i%5)*38.0,-10.0+(i%3)*4.0,-90.0+(i/5)*42.0)
		cloud.scale=Vector3(15+(i%4)*5,4+(i%3),10+(i%5)*3)
		clouds.add_child(cloud)
	sea=box(self,Vector3(0,-55,0),Vector3(3500,0.5,3500),Color("247b89"))
	var water := material(Color("194d62"),0.48)
	water.metallic=0.0
	water.normal_enabled=true
	water.normal_texture=preload("res://assets/baked/water_normal.png")
	water.uv1_scale=Vector3(80,80,80)
	sea.material_override=water
	distant_island=MeshInstance3D.new()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var coast: Array=preload("res://scripts/tropical_world.gd").COAST
	for ring in range(3):
		var inner: float=ring/3.0
		var outer: float=(ring+1)/3.0
		for i in range(coast.size()):
			var a: Vector2=coast[i]
			var b: Vector2=coast[(i+1)%coast.size()]
			for vertex: Vector2 in [a*inner,a*outer,b*outer,a*inner,b*outer,b*inner]:
				var radius: float=vertex.length()
				surface.set_color(Color("b7b498") if radius>0.86 else Color("586b44"))
				surface.set_uv(vertex*0.45+Vector2.ONE*0.5)
				surface.add_vertex(Vector3(vertex.x*145,18*pow(maxf(0,1-radius),1.3),-vertex.y*165))
	surface.generate_normals()
	distant_island.mesh=surface.commit()
	var land := material(Color.WHITE,0.96)
	land.vertex_color_use_as_albedo=true
	land.cull_mode=BaseMaterial3D.CULL_DISABLED
	land.albedo_texture=preload("res://assets/baked/terrain_macro.png")
	distant_island.material_override=land
	distant_island.position=Vector3(15,-51,-210)
	add_child(distant_island)
	ambience=AudioStreamPlayer.new()
	add_child(ambience)
	var audio := AudioStreamWAV.new()
	audio.format=AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate=22050
	var samples := PackedByteArray()
	samples.resize(22050*2)
	for i in range(22050):
		var value: float=(sin(TAU*70*i/22050.0)*0.45+sin(TAU*113*i/22050.0)*0.2)*0.08
		samples.encode_s16(i*2,int(value*32767))
	audio.data=samples
	audio.loop_mode=AudioStreamWAV.LOOP_FORWARD
	audio.loop_end=22050
	ambience.stream=audio
	traveler=preload("res://scripts/real_people.gd").new().create(1,1.75)
	add_child(traveler)
	traveler.rotation.y=0
	# Reuse the game's real terrain for the arrival shot, without a second simultaneous environment.
	front_environment.environment=null
	island=preload("res://scripts/tropical_world.gd").new()
	add_child(island)
	island.build()
	island.auto_quality=false
	island.tier=island.detect_tier() if Preferences.quality<0 else Preferences.quality
	island.apply_tier()
	island_environment=island.find_child("WorldEnvironment",true,false)
	if island_environment==null:
		for node in island.get_children():
			if node is WorldEnvironment: island_environment=node; break
	island_env_resource=island.environment
	island_environment.environment=null
	front_environment.environment=front_env_resource
	island.visible=false

func start_new_game() -> void:
	screen="intro"
	intro_time=0.0
	Preferences.launch="new"
	ambience.play()
	set_intro_pose(0.0)

func window_panel(z: float) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(64):
		var a: float=i*TAU/64
		var b: float=(i+1)*TAU/64
		var points: Array[Vector3]=[]
		for angle in [a,b]:
			var direction := Vector2(cos(angle),sin(angle))
			var inner := Vector2(signf(direction.x)*0.26,signf(direction.y)*0.27)+direction*0.17
			var outer := direction/maxf(absf(direction.x)/0.575,absf(direction.y)/0.7)
			points.append(Vector3(-1.72,1.65+inner.y,z+inner.x))
			points.append(Vector3(-1.73,1.65+outer.y,z+outer.x))
		for index in [0,1,2,2,1,3]: surface.add_vertex(points[index])
	surface.generate_normals()
	var panel := MeshInstance3D.new()
	panel.mesh=surface.commit()
	var mat := material(Color("b8b6aa"),0.72)
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	panel.material_override=mat
	cabin.add_child(panel)

func continue_game() -> void:
	Preferences.launch="continue"
	arrive()

func arrive() -> void:
	if loading: return
	loading=true
	screen="loading"
	ambience.stop()
	ResourceLoader.load_threaded_request("res://scenes/island.tscn")

func shot_index() -> int:
	return 0 if intro_time<SHOTS[0] else (1 if intro_time<SHOTS[1] else 2)

func set_intro_pose(at: float) -> void:
	intro_time=at
	var shot := shot_index() if screen=="intro" else 0
	apron.visible=shot==0
	cabin.visible=shot==1
	clouds.visible=false
	sea.visible=shot>0
	distant_island.visible=false
	traveler.visible=shot==0 and screen=="intro"
	island.visible=shot==2
	front_sun.visible=shot!=2
	island_environment.environment=island_env_resource if shot==2 else null
	front_environment.environment=null if shot==2 else front_env_resource
	plane.visible=shot!=1
	if shot==0:
		plane.position=Vector3.ZERO
		plane.rotation=Vector3.ZERO
		var framing: Dictionary=boarding.camera_pose(at)
		camera.position=framing.position if screen=="intro" else Vector3(-23,6.2,25)
		camera.look_at(framing.target if screen=="intro" else Vector3(0,2.5,0))
		var pose: Dictionary=boarding.pose(at)
		traveler.position=pose.position
		traveler.rotation.y=pose.yaw
		traveler.visible=screen=="intro"
		var animation: AnimationPlayer=traveler.find_child("AnimationPlayer",true,false)
		if animation:
			if animation.current_animation!=pose.clip: animation.play(pose.clip)
			animation.seek(fmod(pose.animation_time,animation.get_animation(pose.clip).length),true)
	elif shot==1:
		camera.position=Vector3(-0.2,1.65,0.75)
		camera.look_at(Vector3(-9,1.48,0.75))
		clouds.position.z=fmod((at-SHOTS[0])*3.0,40.0)
	else:
		plane.position=Vector3(-585,190,300)
		plane.rotation.z=sin(at*0.25)*0.05
		camera.position=plane.position+Vector3(-25,12,28)
		camera.look_at(plane.position+Vector3(2,-4,-3))
		island.update_daylight(9.4,true)
		island.update_view(camera.position,9.4,0)
		sea.visible=false
		clouds.position.z=fmod(at*3.0,40.0)

func _process(dt: float) -> void:
	clock+=dt
	if screen=="intro":
		set_intro_pose(intro_time+dt)
		if intro_time>=SHOTS[2]: arrive()
	elif screen=="menu":
		camera.position=Vector3(-23+sin(clock*0.05)*1.5,6.2,25)
		camera.look_at(Vector3(0,2.5,0))
	if loading and ResourceLoader.load_threaded_get_status("res://scenes/island.tscn")==ResourceLoader.THREAD_LOAD_LOADED:
		get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get("res://scenes/island.tscn"))
