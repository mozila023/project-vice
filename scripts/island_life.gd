extends Node3D
## Peaceful island survival: fishing, food, village life and exploration.
var world: Node3D
var settlement: Node3D
var sunshine: Node3D
var restaurant: Node3D
var hotel: Node3D
var luna: CharacterBody3D
var guide=preload("res://scripts/luna_guide.gd").new()
var resting := false
const REAL_DAY_SECONDS := 3600.0
var player: CharacterBody3D
var foot_contact=preload("res://scripts/foot_contact.gd").new()
var visual: Node3D
var pivot: Node3D
var camera: Camera3D
var field_hud: Control
var audio: Node3D
var villagers: Array[Dictionary] = []
var traffic: Array[Dictionary] = []
var cars: Array[CharacterBody3D] = []
var driving: CharacterBody3D
var look_timer := 0.0
var story=preload("res://scripts/island_story.gd").new()
var navigation=preload("res://scripts/island_navigation.gd").new()
var people=preload("res://scripts/real_people.gd").new()
var resources: Array[Dictionary] = []
var boats: Array[Node3D] = []
var health := 100.0
var stamina := 100.0
var sprint_locked := false
var locomotion_state := "idle"
var locomotion_speed := 0.0
var food := 85.0
var thirst := 90.0
var energy := 100.0
var fish := 0
var cooked_fish := 0
var coconuts := 0
var wood := 3
var coins := 20
var friendship := 0
var delivered_fish := 0
var paused := false
var panel := ""
var yaw := -2.58
var pitch := -0.10
var elapsed := 0.0
var day_time := 8.0
var days := 1
var notice := "Welcome to Efate. Meet the villagers and cast a line from the shore."
var notice_time := 12.0
var fishing_state := ""
var fishing_timer := 0.0
var cast_origin := Vector3.ZERO
var fishing_spot := Vector3.ZERO
var fire_light: OmniLight3D
var bobber: Node3D
var bobber_ring: MeshInstance3D
var line: MeshInstance3D
var rod: Node3D
var rod_tip: Node3D
var reel_crank: Node3D
var cast_anim := 0.0
var well_position := Vector3.ZERO
var camp_position := Vector3.ZERO
var shelter_position := Vector3.ZERO
var village_center := Vector3(-489,0,141)
var spawn := Vector3(-229.08243,5,433.20744)
var rng := RandomNumberGenerator.new()
var model_cache := {}
var active_villager := ""
var traffic_curve: Curve3D
var last_fish_button := false
var materials := {}
var smoothed_meshes := {}
var props=preload("res://scripts/props.gd").new()
var prop_physics=preload("res://scripts/prop_physics.gd").new()
const ACTORS := ["villager-man","villager-woman","villager-man","villager-woman"]
const CAR_SCRIPT := preload("res://scripts/car.gd")
## Everyone collides with the world and with cars. Villagers walk around each other by steering, not by blocking.
const PLAYER_MASK := CAR_SCRIPT.LAYER_WORLD|CAR_SCRIPT.LAYER_TERRAIN|CAR_SCRIPT.LAYER_PEOPLE|CAR_SCRIPT.LAYER_CARS|CAR_SCRIPT.LAYER_TREES
const VILLAGER_MASK := CAR_SCRIPT.LAYER_WORLD|CAR_SCRIPT.LAYER_TERRAIN|CAR_SCRIPT.LAYER_CARS|CAR_SCRIPT.LAYER_TREES
## Parked cars free to drive: [near x, near z, model], at real settlements around the island.
const PARKING := [[-505.0,128.0,"sedan"],[-470.0,170.0,"hatchback-sports"],[-254.0,438.0,"taxi"],[-290.0,290.0,"suv"],[-248.0,621.0,"van"],[106.0,-685.0,"truck"],[915.0,106.0,"suv"],[-849.0,-135.0,"sedan"]]

func ground(x: float,z: float) -> float:
	return world.height_at(x,z)

func _ready() -> void:
	story.game=self
	story.language=Preferences.language
	story.relaxed=Preferences.relaxed
	rng.seed=745
	for action in ["forward","back","left","right","sprint","jump"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	var keys := {"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"sprint":KEY_SHIFT,"jump":KEY_SPACE}
	for action in keys:
		var key := InputEventKey.new()
		key.physical_keycode=keys[action]
		InputMap.action_add_event(action,key)
	world=preload("res://scripts/tropical_world.gd").new()
	add_child(world)
	var t0 := Time.get_ticks_msec(); print("PROFILE start ",t0); world.build(); print("PROFILE world ",Time.get_ticks_msec()-t0)
	settlement=preload("res://scripts/settlement.gd").new()
	settlement.world=world
	add_child(settlement)
	settlement.build()
	sunshine=preload("res://scripts/sunshine_spa.gd").new()
	sunshine.world=world
	add_child(sunshine)
	sunshine.build()
	restaurant=preload("res://scripts/elluk_restaurant.gd").new()
	restaurant.world=world
	add_child(restaurant)
	restaurant.build()
	hotel=preload("res://scripts/seaside_inn.gd").new()
	hotel.world=world
	add_child(hotel)
	hotel.build()
	print("PROFILE town ",Time.get_ticks_msec()-t0); build_player(); build_life(); print("PROFILE life ",Time.get_ticks_msec()-t0)
	audio=preload("res://scripts/island_audio.gd").new()
	audio.game=self
	add_child(audio)
	navigation.build(self)
	guide.build(self)
	navigation.update(0,true)
	apply_preferences()
	tell(story.l("Welcome to Sunshine. Your friend Luna is waiting outside to show you food and a place to sleep.","ยินดีต้อนรับสู่ Sunshine! Luna เพื่อนสาวรออยู่หน้าร้าน ไปคุยให้เธอพาไปรู้จักร้านอาหารและที่พักได้เลย"))
	var layer := CanvasLayer.new()
	add_child(layer)
	field_hud=preload("res://scripts/life_hud.gd").new()
	field_hud.game=self
	layer.add_child(field_hud)
	# Browsers refuse pointer lock without a click: on the web it is requested on the first click instead.
	if not OS.has_feature("web"): Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if field_hud.mobile else Input.MOUSE_MODE_CAPTURED
	get_tree().root.focus_exited.connect(on_focus_lost)
	if Preferences.launch=="continue":
		load_game()
		Preferences.launch="new"
		apply_preferences()

func apply_preferences() -> void:
	story.language=Preferences.language
	story.relaxed=Preferences.relaxed
	world.auto_quality=Preferences.quality<0
	world.tier=world.detect_tier() if Preferences.quality<0 else Preferences.quality
	world.apply_tier()

func switch_language() -> void:
	story.language="en" if story.language=="th" else "th"
	Preferences.language=story.language
	Preferences.save()
	if panel=="talk" and is_instance_valid(audio): audio.speak_dialogue_open(active_villager)

func material(key: String,color: Color) -> StandardMaterial3D:
	if materials.has(key): return materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=0.85
	materials[key]=m
	return m

func model(path: String,target_height: float) -> Node3D:
	if not model_cache.has(path): model_cache[path]=load(path)
	var root: Node3D=model_cache[path].instantiate()
	var bounds := AABB()
	var found := false
	for mesh in root.find_children("*","MeshInstance3D",true,false):
		var transform := Transform3D.IDENTITY
		var cursor: Node3D=mesh
		while cursor!=root:
			transform=cursor.transform*transform
			cursor=cursor.get_parent()
		var aabb: AABB=transform*mesh.get_aabb()
		bounds=bounds.merge(aabb) if found else aabb
		found=true
		mesh.visibility_range_end=110
		smooth_shading(mesh)
	if bounds.size.y>0.001:
		root.scale=Vector3.ONE*(target_height/bounds.size.y)
	return root

## The villager models are flat-shaded. Averaging normals across shared positions turns the
## facets into rounded forms; the result is cached so each source mesh is only processed once.
func smooth_shading(node: MeshInstance3D) -> void:
	var source: Mesh=node.mesh
	if source==null: return
	if smoothed_meshes.has(source):
		node.mesh=smoothed_meshes[source]
		return
	var result := ArrayMesh.new()
	for surface in range(source.get_surface_count()):
		var arrays: Array=source.surface_get_arrays(surface)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		var totals := {}
		for i in range(vertices.size()):
			var key := Vector3i(vertices[i]*2000.0)
			totals[key]=totals.get(key,Vector3.ZERO)+normals[i]
		for i in range(vertices.size()):
			normals[i]=(totals[Vector3i(vertices[i]*2000.0)] as Vector3).normalized()
		arrays[Mesh.ARRAY_NORMAL]=normals
		arrays[Mesh.ARRAY_TANGENT]=null
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var surface_material: Material=source.surface_get_material(surface)
		if surface_material is StandardMaterial3D:
			surface_material=surface_material.duplicate()
			surface_material.roughness=0.72
			surface_material.metallic=0.0
			surface_material.metallic_specular=0.3
		result.surface_set_material(surface,surface_material)
	smoothed_meshes[source]=result
	node.mesh=result

func capsule(body: CharacterBody3D) -> void:
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height=1.74
	shape.radius=0.3
	collision.shape=shape
	collision.position.y=0.87
	body.add_child(collision)
	body.collision_layer=CAR_SCRIPT.LAYER_PEOPLE
	body.floor_snap_length=0.85
	body.floor_max_angle=deg_to_rad(50)
	body.floor_constant_speed=true
	body.floor_stop_on_slope=true

func build_player() -> void:
	player=CharacterBody3D.new()
	player.name="IslandResident"
	add_child(player)
	spawn.y=ground(spawn.x,spawn.z)+0.05
	player.position=spawn
	player.rotation.y=PI
	capsule(player)
	player.collision_mask=PLAYER_MASK
	visual=people.create(1,1.75)
	player.add_child(visual)
	visual.rotation.y=PI
	pivot=Node3D.new()
	add_child(pivot)
	var arm := SpringArm3D.new()
	pivot.add_child(arm)
	arm.spring_length=5.5
	arm.margin=0.25
	arm.add_excluded_object(player.get_rid())
	arm.collision_mask=CAR_SCRIPT.LAYER_WORLD|CAR_SCRIPT.LAYER_TERRAIN
	camera=Camera3D.new()
	arm.add_child(camera)
	camera.current=true
	# A tight depth range keeps roads and roofs free of z-fighting on 24-bit mobile depth buffers.
	camera.near=0.25
	camera.far=7000
	camera.fov=66
	build_fishing_gear()

func rod_part(parent: Node3D,mesh: Mesh,mat: Material,at: Vector3,rot := Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh=mesh
	node.material_override=mat
	node.position=at
	node.rotation=rot
	parent.add_child(node)
	return node

func build_fishing_gear() -> void:
	rod=Node3D.new()
	rod.name="FishingRod"
	player.add_child(rod)
	rod.position=Vector3(0.02,1.08,-0.24)
	rod.rotation=Vector3(-0.78,0.0,0.0)
	rod.visible=false
	var cork_mat := material("rod_cork",Color("c69c6d"))
	var dark_mat := material("rod_dark",Color("26292c"))
	var metal_mat := material("rod_metal",Color("b7c0c4"))
	metal_mat.metallic=0.65
	metal_mat.roughness=0.32
	var blank_mat := material("rod",Color("5c4228"))
	blank_mat.roughness=0.45
	var tip_mat := material("rod_tip_wrap",Color("d65238"))
	# Cork butt grip, reel seat and foregrip held by both hands.
	var grip := CylinderMesh.new()
	grip.top_radius=0.017; grip.bottom_radius=0.019; grip.height=0.38; grip.radial_segments=10
	rod_part(rod,grip,cork_mat,Vector3(0,0.04,0))
	var butt := SphereMesh.new()
	butt.radius=0.021; butt.height=0.042; butt.radial_segments=10; butt.rings=5
	rod_part(rod,butt,dark_mat,Vector3(0,-0.15,0))
	var seat := CylinderMesh.new()
	seat.top_radius=0.016; seat.bottom_radius=0.017; seat.height=0.12; seat.radial_segments=10
	rod_part(rod,seat,dark_mat,Vector3(0,0.28,0))
	var fore := CylinderMesh.new()
	fore.top_radius=0.014; fore.bottom_radius=0.016; fore.height=0.11; fore.radial_segments=10
	rod_part(rod,fore,cork_mat,Vector3(0,0.39,0))
	# Spinning reel mounted beneath the reel seat.
	var stem := BoxMesh.new()
	stem.size=Vector3(0.012,0.04,0.055)
	rod_part(rod,stem,metal_mat,Vector3(0,0.27,0.035))
	var spool := CylinderMesh.new()
	spool.top_radius=0.028; spool.bottom_radius=0.030; spool.height=0.065; spool.radial_segments=12
	rod_part(rod,spool,dark_mat,Vector3(0,0.27,0.072),Vector3(0.22,0,0))
	var spool_trim := CylinderMesh.new()
	spool_trim.top_radius=0.031; spool_trim.bottom_radius=0.031; spool_trim.height=0.028; spool_trim.radial_segments=12
	rod_part(rod,spool_trim,metal_mat,Vector3(0,0.28,0.075),Vector3(0.22,0,0))
	reel_crank=Node3D.new()
	reel_crank.position=Vector3(0.032,0.265,0.068)
	rod.add_child(reel_crank)
	var crank_arm := BoxMesh.new()
	crank_arm.size=Vector3(0.018,0.008,0.055)
	rod_part(reel_crank,crank_arm,metal_mat,Vector3(0.008,0,0.022))
	var knob := CylinderMesh.new()
	knob.top_radius=0.008; knob.bottom_radius=0.008; knob.height=0.024; knob.radial_segments=8
	rod_part(reel_crank,knob,dark_mat,Vector3(0.02,0,0.046),Vector3(0,0,PI*0.5))
	# Three-section tapered rod blank with subtle forward curve and 4 line guides.
	var sections := [
		[0.013,0.0095,0.75,Vector3(0,0.81,0.0),0.0],
		[0.0095,0.006,0.72,Vector3(0,1.53,0.022),0.06],
		[0.006,0.0028,0.68,Vector3(0,2.21,0.088),0.13],
	]
	for seg in sections:
		var blank := CylinderMesh.new()
		blank.bottom_radius=seg[0]; blank.top_radius=seg[1]; blank.height=seg[2]; blank.radial_segments=8
		rod_part(rod,blank,blank_mat,seg[3],Vector3(seg[4],0,0))
	var tip_wrap := CylinderMesh.new()
	tip_wrap.bottom_radius=0.004; tip_wrap.top_radius=0.0032; tip_wrap.height=0.09; tip_wrap.radial_segments=8
	rod_part(rod,tip_wrap,tip_mat,Vector3(0,2.50,0.125),Vector3(0.13,0,0))
	for g in [[0.65,0.018,0.016],[1.15,0.020,0.013],[1.72,0.045,0.010],[2.25,0.102,0.008]]:
		var ring := TorusMesh.new()
		ring.outer_radius=g[2]; ring.inner_radius=g[2]*0.65; ring.rings=8; ring.ring_segments=6
		rod_part(rod,ring,metal_mat,Vector3(0,g[0],g[1]),Vector3(PI*0.5,0,0))
	rod_tip=Node3D.new()
	rod_tip.name="RodTip"
	rod_tip.position=Vector3(0,2.54,0.135)
	rod.add_child(rod_tip)
	# Two-tone red & white fishing float with antenna and water ripple ring.
	bobber=Node3D.new()
	bobber.name="Bobber"
	add_child(bobber)
	bobber.visible=false
	var float_red := material("float_red",Color("dc3b2a"))
	var float_white := material("float_white",Color("f4f1e6"))
	var top_half := SphereMesh.new()
	top_half.radius=0.065; top_half.height=0.11; top_half.radial_segments=10; top_half.rings=5
	rod_part(bobber,top_half,float_red,Vector3(0,0.035,0))
	var bot_half := SphereMesh.new()
	bot_half.radius=0.062; bot_half.height=0.10; bot_half.radial_segments=10; bot_half.rings=5
	rod_part(bobber,bot_half,float_white,Vector3(0,-0.025,0))
	var antenna := CylinderMesh.new()
	antenna.top_radius=0.005; antenna.bottom_radius=0.008; antenna.height=0.14; antenna.radial_segments=6
	rod_part(bobber,antenna,float_red,Vector3(0,0.12,0))
	var ripple_mesh := TorusMesh.new()
	ripple_mesh.inner_radius=0.11; ripple_mesh.outer_radius=0.14; ripple_mesh.rings=12; ripple_mesh.ring_segments=6
	var ripple_mat := StandardMaterial3D.new()
	ripple_mat.albedo_color=Color(0.88,0.95,0.98,0.55)
	ripple_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	ripple_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	materials["ripple"]=ripple_mat
	bobber_ring=rod_part(bobber,ripple_mesh,ripple_mat,Vector3(0,-0.02,0))
	var line_mat := material("line",Color("e8e7d5"))
	line_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	line=MeshInstance3D.new()
	line.material_override=line_mat
	add_child(line)

func play_animation(actor: Node3D,clip: String,speed := 1.0) -> void:
	var animator := actor.find_child("AnimationPlayer",true,false) as AnimationPlayer
	if animator==null: return
	if not animator.has_animation(clip):
		var suffix: String = {"idle":"Idle","walk":"Walk","sprint":"Run","holding-both":"Standing"}.get(clip,"Idle")
		for candidate in animator.get_animation_list():
			if candidate.ends_with("_"+suffix): clip=candidate; break
	if animator.has_animation(clip):
		if animator.current_animation!=clip:
			animator.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
			animator.play(clip,0.18)
		animator.speed_scale=speed

func build_life() -> void:
	well_position=Vector3(-475,ground(-475,110),110)
	camp_position=Vector3(-500,ground(-500,136),136)
	shelter_position=Vector3(-455,ground(-455,130),130)
	# Blender-authored communal well, cooking campfire circle and sheltered bamboo sleeping pavilion.
	var well: Node3D=preload("res://assets/models/props/village_well.glb").instantiate()
	add_child(well)
	well.position=well_position
	prop_physics.ground_on(well,"village_well",world)
	prop_physics.add(well,"village_well")
	var fire_pit: Node3D=preload("res://assets/models/props/campfire_pit.glb").instantiate()
	add_child(fire_pit)
	fire_pit.position=camp_position
	prop_physics.ground_on(fire_pit,"campfire_pit",world)
	prop_physics.add(fire_pit,"campfire_pit")
	var shelter: Node3D=preload("res://assets/models/props/island_shelter.glb").instantiate()
	add_child(shelter)
	shelter.position=shelter_position
	prop_physics.ground_on(shelter,"island_shelter",world)
	prop_physics.add(shelter,"island_shelter")
	build_fire()
	var names := ["Malia / Fisher","Jonas / Market","Lina","David","Ana","Peter","Sera","Thomas","Rose","Ben","Mary","Paul"]
	for i in range(12):
		var body := CharacterBody3D.new()
		body.name="Villager_%02d"%i
		add_child(body)
		capsule(body)
		body.collision_mask=VILLAGER_MASK
		var appearance := people.create(i,rng.randf_range(1.6,1.85))
		body.add_child(appearance)
		appearance.rotation.y=PI
		var points: Array[Vector3]=[]
		if i==0:
			# The fisher works around the cooking fire.
			for p in [Vector2(-496,128),Vector2(-493,141),Vector2(-503,146)]: points.append(Vector3(p.x,ground(p.x,p.y)+0.2,p.y))
		else:
			# Each villager keeps their own line across the green, so they rarely meet head on.
			var side := -1.0 if i%2==0 else 1.0
			var x: float=-489.0+side*(2.0+(i%4)*2.0)
			var offset: float=(i%5)*3.0
			for z in [66.0,86.0,106.0,126.0,136.0]:
				points.append(Vector3(x,ground(x,z+offset)+0.15,z+offset))
			if i%3==0: points.reverse()
		body.position=points[i%points.size()]
		villagers.append({"body":body,"visual":appearance,"name":names[i],"points":points,"target":(i+1)%points.size(),"wait":rng.randf_range(0,4),"speed":rng.randf_range(0.8,1.3),"check_at":body.position,"check_time":0.0})
	traffic_curve=Curve3D.new()
	for p in world.geography.get("traffic_route",[]):
		traffic_curve.add_point(Vector3(p[0],maxf(0.75,ground(p[0],p[1])+0.2),p[1]))
	traffic_curve.bake_interval=1.5
	for i in range(4):
		var car: CharacterBody3D=spawn_car(["sedan","van","suv","truck"][i])
		traffic.append({"node":car,"progress":12.0+i*36,"direction":1.0 if i%2==0 else -1.0,"speed":4.0+i*0.6,"lane":1.0 if i%2==0 else -1.0})
	update_traffic(0.0)
	for entry in traffic: entry.node.settle(0.0,true)
	for spot in PARKING: park_car(spot[0],spot[1],spot[2])
	var beach_x := -540.0
	for i in range(2):
		var boat: Node3D=props.boat(i==0)
		add_child(boat)
		boat.position=Vector3(beach_x-i*10,0,165+i*9)
		boat.rotation.y=0.8+i*0.5
		boats.append(boat)
	var coconut_scene: PackedScene=preload("res://assets/models/props/coconut.glb")
	var driftwood_scene: PackedScene=preload("res://assets/models/props/driftwood.glb")
	for i in range(18):
		var x := -490+rng.randf_range(-12,35)
		var z := rng.randf_range(95,150)
		if ground(x,z)<1 or inside_building(x,z): continue
		var coconut: Node3D=coconut_scene.instantiate()
		add_child(coconut)
		coconut.position=Vector3(x,ground(x,z),z)
		coconut.rotation.y=rng.randf()*TAU
		prop_physics.ground_on(coconut,"coconut",world)
		resources.append({"node":coconut,"kind":"coconut","id":i,"collected":false})
	for i in range(8):
		var node: Node3D=driftwood_scene.instantiate()
		add_child(node)
		var x := rng.randf_range(-505,-485)
		var z := rng.randf_range(120,145)
		while inside_building(x,z):
			x=rng.randf_range(-505,-485)
			z=rng.randf_range(120,145)
		node.position=Vector3(x,ground(x,z),z)
		node.rotation.y=rng.randf()*TAU
		prop_physics.ground_on(node,"driftwood",world)
		resources.append({"node":node,"kind":"wood","id":100+i,"collected":false})

func spawn_car(kind: String) -> CharacterBody3D:
	var car: CharacterBody3D=CAR_SCRIPT.new()
	add_child(car)
	car.setup(kind,world,cars.size())
	cars.append(car)
	return car

## Pulls a car up at the side of the mapped road nearest to a place, clear of buildings, poles and other cars.
func park_car(near_x: float,near_z: float,kind: String) -> void:
	var near := Vector2(near_x,near_z)
	var best := 1e9
	var best_at := Vector2.ZERO
	var best_yaw := 0.0
	for road in world.geography.roads:
		if road.type=="runway": continue
		var half: float=world.road_half(road.type)
		var pts: Array=road.points
		for i in range(pts.size()-1):
			var a := Vector2(pts[i][0],pts[i][1])
			var b := Vector2(pts[i+1][0],pts[i+1][1])
			if a.distance_to(near)>140.0 and b.distance_to(near)>140.0: continue
			var length: float=a.distance_to(b)
			if length<0.01: continue
			var dir: Vector2=(b-a)/length
			var along := 0.0
			while along<length:
				var at: Vector2=a+dir*along
				along+=4.0
				for side in [-1.0,1.0]:
					var spot: Vector2=at+Vector2(-dir.y,dir.x)*side*(half+1.6)
					var distance: float=spot.distance_to(near)
					if distance<best and parking_clear(spot):
						best=distance
						best_at=spot
						best_yaw=atan2(dir.x,dir.y)
	if best>=1e9: return
	var car := spawn_car(kind)
	car.position=Vector3(best_at.x,0,best_at.y)
	car.rotation.y=best_yaw
	car.settle(0.0,true)

func parking_clear(spot: Vector2) -> bool:
	if ground(spot.x,spot.y)<1.2 or inside_building(spot.x,spot.y): return false
	if spot.distance_to(Vector2(spawn.x,spawn.z))<7.0: return false
	for keep in world.KEEP_CLEAR:
		if spot.distance_to(keep)<7.0: return false
	for car in cars:
		if spot.distance_to(Vector2(car.position.x,car.position.z))<8.0: return false
	for chain in world.baked.poles:
		for pole: Vector3 in chain:
			if absf(pole.x-spot.x)<4.0 and absf(pole.z-spot.y)<4.0: return false
	return true

func nearest_car() -> CharacterBody3D:
	var found: CharacterBody3D=null
	var best := 1e9
	for car in cars:
		if absf(car.speed)>3.0: continue
		var distance: float=car.position.distance_to(player.position)
		if distance<car.half_length+1.6 and distance<best:
			best=distance
			found=car
	return found

func enter_car(car: CharacterBody3D) -> void:
	if absf(car.speed)>3.0:
		tell("Wait for the car to stop before getting in.")
		return
	cancel_fishing()
	# A passing car stops being traffic once someone takes the wheel.
	for i in range(traffic.size()-1,-1,-1):
		if traffic[i].node==car: traffic.remove_at(i)
	driving=car
	player.visible=false
	player.collision_layer=0
	player.collision_mask=0
	player.velocity=Vector3.ZERO
	camera.get_parent().spring_length=8.0
	look_timer=0.0
	if is_instance_valid(audio): audio.play_sfx("car_door",1.0,-2.0)
	tell("W accelerate · S brake / reverse · A D steer · Space handbrake · E get out")

func leave_car(forced := false) -> bool:
	if driving==null: return true
	if not forced and absf(driving.speed)>3.0:
		tell("Slow down before getting out.")
		return false
	var f: Vector3=driving.forward()
	var left := Vector3(f.z,0,-f.x)
	var reach: float=driving.half_width+0.9
	var at := Vector3.INF
	for offset: Vector3 in [left*reach,-left*reach,-f*(driving.half_length+1.0),f*(driving.half_length+1.0)]:
		var spot: Vector3=driving.position+offset
		if ground(spot.x,spot.z)>-0.3 and standing_room(spot):
			at=spot
			break
	if at==Vector3.INF:
		if not forced:
			tell("No room to open the door here.")
			return false
		at=driving.position
	driving.speed=0.0
	driving.velocity=Vector3.ZERO
	driving=null
	player.global_position=Vector3(at.x,ground(at.x,at.z)+0.3,at.z)
	player.visible=true
	player.collision_layer=CAR_SCRIPT.LAYER_PEOPLE
	player.collision_mask=PLAYER_MASK
	camera.get_parent().spring_length=5.5
	if not forced and is_instance_valid(audio): audio.play_sfx("car_door",0.92,-2.5)
	return true

func standing_room(spot: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := CapsuleShape3D.new()
	shape.height=1.75
	shape.radius=0.3
	query.shape=shape
	query.transform=Transform3D(Basis.IDENTITY,Vector3(spot.x,ground(spot.x,spot.z)+1.05,spot.z))
	query.collision_mask=CAR_SCRIPT.LAYER_WORLD|CAR_SCRIPT.LAYER_CARS|CAR_SCRIPT.LAYER_TREES
	return get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func update_driving(dt: float,input: Vector2) -> void:
	driving.drive(dt,-input.y,input.x,Input.is_action_pressed("jump"))
	player.global_position=driving.position
	if driving.bumped: tell("Crunch! Watch the road.")
	# The camera swings back behind the car unless the player has just looked around.
	look_timer=maxf(0.0,look_timer-dt)
	if look_timer<=0.0 and absf(driving.speed)>1.0:
		var f: Vector3=driving.forward()
		yaw=lerp_angle(yaw,atan2(-f.x,-f.z),clampf(dt*2.5,0.0,1.0))

func inside_building(x: float,z: float) -> bool:
	for b in world.baked.buildings:
		if Vector2(b.x,b.z).distance_to(Vector2(x,z))<maxf(b.w,b.d)*0.5+6.0: return true
	return false

## Beach cooking fire: soft flame sprites, drifting smoke and a flickering light after dark.
func build_fire() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0,Color(1,1,1,1))
	gradient.set_color(1,Color(1,1,1,0))
	var sprite := GradientTexture2D.new()
	sprite.gradient=gradient
	sprite.fill=GradientTexture2D.FILL_RADIAL
	sprite.fill_from=Vector2(0.5,0.5)
	sprite.fill_to=Vector2(1.0,0.5)
	sprite.width=64
	sprite.height=64
	for smoke in [false,true]:
		var quad_mesh := QuadMesh.new()
		quad_mesh.size=Vector2(0.75,0.75) if smoke else Vector2(0.42,0.42)
		var look := StandardMaterial3D.new()
		look.albedo_texture=sprite
		look.vertex_color_use_as_albedo=true
		look.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
		look.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		look.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		look.blend_mode=BaseMaterial3D.BLEND_MODE_MIX if smoke else BaseMaterial3D.BLEND_MODE_ADD
		quad_mesh.material=look
		var emitter := CPUParticles3D.new()
		emitter.mesh=quad_mesh
		emitter.amount=7 if smoke else 16
		emitter.lifetime=3.2 if smoke else 0.75
		emitter.emission_shape=CPUParticles3D.EMISSION_SHAPE_SPHERE
		emitter.emission_sphere_radius=0.16
		emitter.direction=Vector3.UP
		emitter.spread=9
		emitter.gravity=Vector3(0.12,0.3,0) if smoke else Vector3(0,0.55,0)
		emitter.initial_velocity_min=0.35 if smoke else 0.5
		emitter.initial_velocity_max=0.6 if smoke else 1.0
		var fade_out := Gradient.new()
		if smoke:
			fade_out.set_color(0,Color(0.5,0.48,0.46,0.0))
			fade_out.set_color(1,Color(0.5,0.48,0.46,0.0))
			fade_out.add_point(0.2,Color(0.5,0.48,0.46,0.2))
		else:
			fade_out.set_color(0,Color(1.0,0.72,0.25,0.95))
			fade_out.set_color(1,Color(0.9,0.2,0.03,0.0))
		emitter.color_ramp=fade_out
		emitter.visibility_range_end=70.0
		add_child(emitter)
		emitter.position=camp_position+Vector3.UP*(0.8 if smoke else 0.28)
	fire_light=OmniLight3D.new()
	fire_light.light_color=Color(1.0,0.56,0.22)
	fire_light.omni_range=7.5
	fire_light.shadow_enabled=false
	fire_light.distance_fade_enabled=true
	fire_light.distance_fade_begin=70.0
	fire_light.distance_fade_length=20.0
	add_child(fire_light)
	fire_light.position=camp_position+Vector3.UP*0.75

func sync_daylight(force := false) -> void:
	world.update_daylight(day_time,force)

func sync_view() -> void:
	world.update_view(camera.global_position,day_time,0.0)

var _pf := 0
func _process(dt: float) -> void:
	_pf+=1
	if _pf<=4: print("PROFILE frame ",_pf," at ",Time.get_ticks_msec())
	world.update_view(camera.global_position,day_time,dt)
	fire_light.light_energy=(1.5+sin(Time.get_ticks_msec()*0.013)*0.25+sin(Time.get_ticks_msec()*0.031)*0.2)*lerpf(0.35,1.0,world.settlement_night())

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE:
				if panel!="": panel=""
				else: paused=not paused
				field_hud.release_all()
			KEY_M: panel="" if panel=="map" else "map"; field_hud.release_all()
			KEY_TAB: panel="" if panel in ["pack","journal","island","map"] else "pack"; field_hud.release_all()
			KEY_E:
				if not blocked(): interact()
			KEY_F:
				if not blocked(): cast_line()
			KEY_Q:
				if not blocked(): eat()
			KEY_F5: save_game()
			KEY_F9: load_game()
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if blocked() or field_hud.mobile else Input.MOUSE_MODE_CAPTURED
	# Browsers only grant pointer lock on a user gesture, so (re)capture the mouse on click.
	if event is InputEventMouseButton and event.pressed and not blocked() and not field_hud.mobile:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and not blocked() and not field_hud.mobile:
		yaw-=event.relative.x*0.003*Preferences.sensitivity
		pitch=clampf(pitch-event.relative.y*0.003*Preferences.sensitivity,-0.95,0.65)
		look_timer=1.5

func blocked() -> bool:
	return paused or panel!="" or resting

func on_focus_lost() -> void:
	if field_hud: field_hud.release_all()
	paused=true
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func _physics_process(dt: float) -> void:
	if not is_instance_valid(field_hud): return
	if not blocked():
		elapsed+=dt
		notice_time=maxf(0,notice_time-dt)
		advance_hours(dt*24.0/REAL_DAY_SECONDS)
		var input := Input.get_vector("left","right","forward","back")
		if field_hud.mobile: input=(input+field_hud.move_vector).limit_length()
		var moving := input.length()>0.1 and driving==null
		var wants_sprint: bool=Input.is_action_pressed("sprint") or field_hud.running
		if stamina<=0.1: sprint_locked=true
		if not wants_sprint and stamina>=20.0: sprint_locked=false
		var sprint: bool=wants_sprint and not sprint_locked and stamina>0.1 and energy>0 and moving and fishing_state==""
		locomotion_speed=0.0
		if driving:
			update_driving(dt,input)
		else:
			var speed := 7.0 if sprint else 4.0
			if fishing_state!="": speed=1.0
			var direction := Basis(Vector3.UP,yaw)*Vector3(input.x,0,input.y)
			var jumping: bool=player.is_on_floor() and Input.is_action_just_pressed("jump")
			player.velocity.x=direction.x*speed
			player.velocity.z=direction.z*speed
			player.velocity.y-=20*dt
			if player.is_on_floor(): player.velocity.y=6.5 if jumping else -2.5
			player.move_and_slide()
			var actual: Vector3=player.get_real_velocity()
			locomotion_speed=Vector2(actual.x,actual.z).length()
			if not jumping and player.velocity.y<=0.0: player.apply_floor_snap()
			if moving and fishing_state=="": player.rotation.y=lerp_angle(player.rotation.y,yaw-atan2(input.x,-input.y),dt*12)
			foot_contact.update(player,visual,world,dt)
		world.update_tree_collision(player.position)
		stamina=clampf(stamina+(-17 if sprint and locomotion_speed>0.3 else 13)*dt,0,100)
		food=maxf(0,food-dt*0.045) if not story.relaxed else food
		thirst=maxf(0,thirst-dt*(0.09 if sprint else 0.055)) if not story.relaxed else thirst
		energy=maxf(0,energy-dt*0.025) if not story.relaxed else energy
		if not story.relaxed and (food<=0 or thirst<=0): health=maxf(0,health-dt*0.8)
		elif food>60 and thirst>60: health=minf(100,health+dt*0.15)
		if player.position.y<-1.8: health=maxf(0,health-dt*10)
		if health<=0:
			leave_car(true)
			player.position=spawn
			player.velocity=Vector3.ZERO
			health=75; food=50; thirst=50; energy=60
			cancel_fishing()
			tell("The villagers helped you back to your shelter. Eat and drink before exploring.")
		var travelling: bool=moving and locomotion_speed>0.15
		locomotion_state="holding-both" if fishing_state!="" else ("sprint" if sprint and travelling else ("walk" if travelling else "idle"))
		var anim_speed := clampf(locomotion_speed/(6.4 if locomotion_state=="sprint" else 3.1),0.6,1.5) if travelling else 1.0
		play_animation(visual,locomotion_state,anim_speed)
		update_fishing(dt)
		update_villagers(dt)
		update_traffic(dt)
		story.update()
		navigation.update(dt)
		for i in range(boats.size()):
			boats[i].position.y=sin(elapsed*0.8+i)*0.04-0.24
			boats[i].rotation.z=sin(elapsed*0.7+i)*0.015
	pivot.position=player.position+Vector3(0,1.4,0)
	pivot.rotation=Vector3(pitch,yaw,0)

func update_villagers(dt: float) -> void:
	for npc in villagers:
		if npc.get("guide",false):
			guide.update(dt)
			continue
		var body: CharacterBody3D=npc.body
		if body.position.distance_to(player.position)<3.0 or npc.wait>0:
			npc.wait=maxf(0,npc.wait-dt)
			body.velocity.x=0; body.velocity.z=0
			play_animation(npc.visual,"idle")
			npc.check_at=body.position
			npc.check_time=0.0
		else:
			var goal: Vector3=npc.points[npc.target]
			var delta := goal-body.position
			delta.y=0
			if delta.length()<1.2:
				npc.target=(npc.target+1)%npc.points.size()
				npc.wait=rng.randf_range(1.0,3.5)
			var heading: Vector3=delta.normalized()
			# Step around neighbours: ease away from anyone close and always pass on the right.
			for other in villagers:
				if other==npc: continue
				var away: Vector3=body.position-other.body.position
				away.y=0
				var gap: float=away.length()
				if gap<2.4 and gap>0.01:
					var pressure: float=(2.4-gap)/2.4
					heading+=away/gap*pressure*1.4
					if heading.dot(-away)>0.0: heading+=Vector3(heading.z,0,-heading.x)*pressure*1.2
			heading=heading.normalized()
			body.velocity.x=heading.x*npc.speed
			body.velocity.z=heading.z*npc.speed
			if heading.length()>0.1: body.rotation.y=lerp_angle(body.rotation.y,atan2(-heading.x,-heading.z),dt*4)
			play_animation(npc.visual,"walk",npc.speed/1.25)
			# Blocked by something for two seconds: give up on this leg and head for the next point.
			npc.check_time+=dt
			if npc.check_time>=2.0:
				if body.position.distance_to(npc.check_at)<0.5:
					npc.target=(npc.target+1)%npc.points.size()
					npc.wait=rng.randf_range(0.3,1.2)
				npc.check_at=body.position
				npc.check_time=0.0
		body.velocity.y=-8
		body.move_and_slide()
		body.apply_floor_snap()
		foot_contact.update(body,npc.visual,world,dt,body.position.distance_squared_to(player.position)<1600.0)

func update_traffic(dt: float) -> void:
	var length := traffic_curve.get_baked_length()
	if length<1: return
	for car in traffic:
		var node: CharacterBody3D=car.node
		var center := traffic_curve.sample_baked(car.progress,true)
		var tangent: Vector3=traffic_curve.sample_baked(minf(car.progress+1.0,length),true)-traffic_curve.sample_baked(maxf(car.progress-1.0,0.0),true)
		tangent.y=0
		tangent=tangent.normalized()
		var direction: Vector3=tangent*car.direction
		var stop: bool=blocked_ahead(node,direction)
		for other in traffic:
			if other==car: continue
			if other.direction==car.direction and (other.progress-car.progress)*car.direction>0 and absf(other.progress-car.progress)<11: stop=true
		if not stop: car.progress+=car.direction*car.speed*dt
		if car.progress>length-1: car.progress=length-1; car.direction=-1.0
		elif car.progress<1: car.progress=1; car.direction=1.0
		# The right-hand lane, eased across at each end of the route so the turn is a U-turn, not a jump.
		car.lane=move_toward(car.lane,car.direction,dt*0.45)
		node.follow(center+tangent.cross(Vector3.UP)*car.lane*1.45,atan2(direction.x,direction.z),0.0 if stop else car.speed,dt)

## True if the player or another car is in this car's lane within braking distance.
func blocked_ahead(node: CharacterBody3D,direction: Vector3) -> bool:
	if direction.length_squared()<0.5: return false
	var targets: Array[Vector3]=[player.position]
	for npc in villagers: targets.append(npc.body.position)
	for other in cars:
		if other!=node: targets.append(other.position)
	for at in targets:
		var offset: Vector3=at-node.position
		offset.y=0
		var along: float=offset.dot(direction)
		if along>0.0 and along<node.half_length+6.0 and absf(offset.dot(Vector3(direction.z,0,-direction.x)))<1.9: return true
	return false

func tell(value: String) -> void:
	notice=value
	notice_time=8
	if is_instance_valid(audio): audio.on_notice(value)

func fishing_water() -> Vector3:
	var origin := player.position
	for r in [6.0,9.0,12.0,15.0,4.0]:
		for step in [0,1,-1,2,-2,3,-3,4,-4,5,-5,6]:
			var angle: float=yaw+step*TAU/12.0
			var point: Vector3=origin+Vector3(-sin(angle),0,-cos(angle))*r
			if ground(point.x,point.z)<-0.45: return Vector3(point.x,0.03,point.z)
	return Vector3.INF

func cast_line() -> void:
	if blocked(): return
	if driving: tell("Get out of the car before casting."); return
	if fishing_state=="bite": reel(); return
	if fishing_state!="":
		cancel_fishing()
		if is_instance_valid(audio): audio.play_sfx("ui_close",1.1,-4.0)
		tell("Line reeled in.")
		return
	var point := fishing_water()
	if point==Vector3.INF:
		tell("Walk to the shoreline or the jetty before casting.")
		return
	fishing_spot=point
	cast_origin=player.position
	fishing_state="waiting"
	fishing_timer=rng.randf_range(3.0,6.5)
	cast_anim=0.38
	var to_water: Vector3=point-player.position
	player.rotation.y=atan2(-to_water.x,-to_water.z)
	bobber.position=point
	bobber.visible=true
	rod.visible=true
	if is_instance_valid(audio):
		audio.play_sfx("cast",1.0,-1.5)
		audio.play_sfx("splash",1.0,-3.5)
	tell("Line cast. Watch the float. Press E / REEL when a fish bites.")

func update_fishing(dt: float) -> void:
	if fishing_state=="": return
	if player.position.distance_to(cast_origin)>2.5:
		cancel_fishing(); tell("You moved too far from your fishing line."); return
	fishing_timer-=dt
	cast_anim=maxf(0.0,cast_anim-dt)
	var to_water: Vector3=fishing_spot-player.position
	player.rotation.y=lerp_angle(player.rotation.y,atan2(-to_water.x,-to_water.z),clampf(dt*8.0,0.0,1.0))
	var bite := fishing_state=="bite"
	# Rod cast whip & fish-bite tug animation.
	var cast_swing: float=sin(cast_anim/0.38*PI)*0.45 if cast_anim>0.0 else 0.0
	var bite_tug: float=(0.18+sin(elapsed*18.0)*0.09+cos(elapsed*29.0)*0.04) if bite else sin(elapsed*2.2)*0.018
	rod.rotation=Vector3(-0.78-bite_tug+cast_swing,sin(elapsed*7.5)*0.03 if bite else 0.0,0.0)
	if is_instance_valid(reel_crank): reel_crank.rotation.x=fmod(elapsed*(14.0 if bite else 1.5),TAU)
	# Float bobbing, bite plunge and expanding water ripple ring.
	var bob_y: float=0.04+sin(elapsed*3.2)*0.022-(0.08+absf(sin(elapsed*16.0))*0.06 if bite else 0.0)
	var plunge_xz := Vector2(sin(elapsed*14.0),cos(elapsed*19.0))*(0.06 if bite else 0.008)
	bobber.position=Vector3(fishing_spot.x+plunge_xz.x,bob_y,fishing_spot.z+plunge_xz.y)
	bobber.rotation=Vector3(sin(elapsed*(13.0 if bite else 2.5))*(0.28 if bite else 0.06),0,cos(elapsed*(11.0 if bite else 2.1))*(0.28 if bite else 0.06))
	if is_instance_valid(bobber_ring):
		var pulse: float=fmod(elapsed*(2.6 if bite else 0.9),1.0)
		var ring_s: float=lerpf(0.7,2.4 if bite else 1.45,pulse)
		bobber_ring.scale=Vector3(ring_s,1.0,ring_s)
		bobber_ring.position.y=-bob_y+0.015
	# Smooth catenary fishing line from the rod tip to the bobber top.
	var tip_pos: Vector3=rod_tip.global_position if is_instance_valid(rod_tip) else (rod.global_position+Vector3.UP*1.0)
	var end_pos: Vector3=bobber.global_position+Vector3.UP*0.09
	var sag: float=0.12 if bite else 0.55
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var segments := 12
	for i in range(segments+1):
		var u: float=float(i)/float(segments)
		var pt: Vector3=tip_pos.lerp(end_pos,u)
		pt.y-=sin(u*PI)*sag
		if bite: pt.y+=sin(u*TAU*2.0+elapsed*28.0)*0.015
		mesh.surface_add_vertex(pt)
	mesh.surface_end()
	line.mesh=mesh
	if fishing_timer<=0:
		if fishing_state=="waiting":
			fishing_state="bite"
			fishing_splash(fishing_spot)
			fishing_timer=2.8
			if is_instance_valid(audio):
				audio.play_sfx("bite",1.0,-1.0)
				audio.play_sfx("splash",0.92,-2.0)
			tell("A BITE! Press E / REEL now.")
		else:
			cancel_fishing()
			tell("The fish escaped. Cast again when you are ready.")

func reel() -> void:
	if fishing_state!="bite": return
	fish+=1
	fishing_splash(fishing_spot)
	cancel_fishing()
	if is_instance_valid(audio):
		audio.play_sfx("catch",1.0,-1.0)
		audio.play_sfx("splash",1.08,-1.5)
	tell("Fish caught! Cook it at the beach fire or trade with a villager.")

func fishing_splash(at: Vector3) -> void:
	var splash: Node3D=load("res://assets/models/island_refined/fishing_splash.glb").instantiate()
	add_child(splash)
	splash.position=Vector3(at.x,0.025,at.z)
	for mesh: MeshInstance3D in splash.find_children("*","MeshInstance3D",true,false):
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var animation: AnimationPlayer=splash.find_child("AnimationPlayer",true,false)
	if animation and not animation.get_animation_list().is_empty():
		var clip: String=animation.get_animation_list()[0]
		animation.get_animation(clip).loop_mode=Animation.LOOP_NONE
		animation.play(clip)
	get_tree().create_timer(1.0).timeout.connect(splash.queue_free)

func cancel_fishing() -> void:
	fishing_state=""
	fishing_timer=0
	if is_instance_valid(bobber): bobber.visible=false
	if is_instance_valid(rod): rod.visible=false
	if is_instance_valid(line): line.mesh=null

func nearby_context() -> String:
	if is_instance_valid(luna) and player.position.distance_to(luna.position)<3: return story.l("TALK TO LUNA","คุยกับ Luna")
	if restaurant_inside(): return story.l("PAD THAI · EAT / SELL INGREDIENTS","PAD THAI · กินข้าว / ขายวัตถุดิบ")
	if hotel.contains(player.position): return story.l("SEASIDE INN · SLEEP UNTIL MORNING","SEASIDE INN · นอนพักถึงเช้า")
	if driving: return "GET OUT" if absf(driving.speed)<=3.0 else ""
	if fishing_state=="bite": return "REEL IN THE FISH"
	if player.position.distance_to(camp_position)<3.5: return "COOK FISH / 1 raw fish + 1 driftwood"
	if player.position.distance_to(well_position)<3.5: return "DRINK / REFILL AT THE WELL"
	if player.position.distance_to(shelter_position)<3.5: return "REST AT YOUR SHELTER"
	for npc in villagers:
		if npc.body.position.distance_to(player.position)<3: return "TALK / "+npc.name
	for item in resources:
		if not item.collected and item.node.position.distance_to(player.position)<2.5: return "COLLECT "+item.kind.to_upper()
	if nearest_car(): return "DRIVE THIS CAR"
	return ""

func interact() -> void:
	if blocked(): return
	if driving: leave_car(); return
	if fishing_state=="bite": reel(); return
	if is_instance_valid(luna) and player.position.distance_to(luna.position)<3:
		active_villager="Luna"
		panel="talk"
		field_hud.release_all()
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		return
	if restaurant_inside():
		panel="restaurant"
		field_hud.release_all()
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		return
	if hotel.contains(player.position):
		panel="hotel"
		field_hud.release_all()
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		return
	if player.position.distance_to(camp_position)<3.5:
		if fish>0 and wood>0:
			fish-=1; wood-=1; cooked_fish+=1
			if is_instance_valid(audio): audio.play_sfx("cook",1.0,-1.0)
			tell("Grilled fish ready. Press Q / EAT to eat it.")
			story.event("cook")
		else: tell("Cooking needs one raw fish and one piece of driftwood.")
		return
	if player.position.distance_to(well_position)<3.5:
		thirst=100
		if is_instance_valid(audio): audio.play_sfx("drink",1.0,-1.5)
		tell("Fresh water. Your thirst is restored.")
		return
	if player.position.distance_to(shelter_position)<3.5:
		energy=100; health=minf(100,health+25); food=maxf(5,food-12); thirst=maxf(5,thirst-15)
		day_time+=8
		if day_time>=24: day_time-=24; days+=1
		if is_instance_valid(audio): audio.play_sfx("rest",1.0,-1.5)
		tell("You rested for eight hours. A new day on the island."); return
	for npc in villagers:
		if npc.body.position.distance_to(player.position)<3:
			active_villager=npc.name
			panel="talk"
			field_hud.release_all()
			Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
			return
	for item in resources:
		if not item.collected and item.node.position.distance_to(player.position)<2.5:
			item.collected=true
			item.node.visible=false
			if item.kind=="coconut": coconuts+=1
			else: wood+=1
			if is_instance_valid(audio): audio.play_sfx("pickup",1.08 if item.kind=="coconut" else 0.92,-2.0)
			tell("Collected "+item.kind+".")
			return
	var car := nearest_car()
	if car: enter_car(car); return
	if fishing_state!="": cast_line()
	else: tell("Explore the beach, meet a villager, or press F to fish beside the water.")

func eat() -> void:
	if cooked_fish>0:
		cooked_fish-=1; food=minf(100,food+38); health=minf(100,health+6)
		if is_instance_valid(audio): audio.play_sfx("eat",1.0,-1.5)
		tell("You ate grilled fish. Hunger restored.")
	elif coconuts>0:
		coconuts-=1; food=minf(100,food+15); thirst=minf(100,thirst+25)
		if is_instance_valid(audio): audio.play_sfx("eat",1.08,-1.5)
		tell("Fresh coconut: food and water restored.")
	else: tell("No prepared food. Catch a fish and cook it, or gather coconuts.")

func trade(option: String) -> void:
	if panel!="talk": return
	if active_villager=="Luna":
		if option=="story": story.talk()
		panel=""
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if field_hud.mobile else Input.MOUSE_MODE_CAPTURED
		return
	match option:
		"sell":
			if fish>=3:
				fish-=3; coins+=45; friendship+=1; delivered_fish+=3
				tell("Thank you! Three fresh fish traded for 45 vatu. Friendship +1.")
				story.event("trade")
			else: tell("Bring three fresh fish to trade at the village.")
		"meal":
			if coins>=8:
				coins-=8; food=minf(100,food+35); thirst=minf(100,thirst+15)
				tell("A home-cooked meal shared with your neighbours.")
			else: tell("A village meal costs 8 vatu.")
		"chat":
			tell("The Efate coast connects Port Vila, Mele, Eton and Undine Bay. The village needs fresh fish each day.")
		"story":
			story.talk()
			return
	panel=""
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if field_hud.mobile else Input.MOUSE_MODE_CAPTURED

func advance_hours(hours: float) -> void:
	if not is_finite(hours) or hours<0: return
	var total := day_time+hours
	days+=floori(total/24.0)
	day_time=fposmod(total,24.0)

func time_period() -> String:
	if day_time<5 or day_time>=20: return story.l("Night","กลางคืน")
	if day_time<9: return story.l("Morning","เช้า")
	if day_time<12: return story.l("Late morning","สาย")
	if day_time<17: return story.l("Afternoon","บ่าย")
	return story.l("Evening","ค่ำ")

func restaurant_inside() -> bool:
	return absf(player.position.x-restaurant.SITE.x)<7.6 and absf(player.position.z-restaurant.SITE.y)<6.3 and absf(player.position.y-restaurant.floor_height)<1.0

func service(option: String) -> void:
	if panel=="restaurant" and restaurant_inside():
		if option=="restaurant_meal":
			if coins<8: tell(story.l("A meal costs 8 vatu.","ข้าวหนึ่งมื้อราคา 8 วาตู เงินยังไม่พอ")); return
			coins-=8; food=minf(100,food+45); thirst=minf(100,thirst+20); health=minf(100,health+5)
			tell(story.l("Enjoy your Pad Thai meal!","อิ่มอร่อยที่ Pad Thai ฟื้นความหิวและกระหายแล้ว"))
		elif option.begins_with("ingredient_"):
			var item: String=option.trim_prefix("ingredient_")
			var prices := {"fish":15,"coconuts":5,"wood":4}
			if not prices.has(item): return
			if int(get(item))<=0: tell(story.l("You have none of that ingredient to sell.","ยังไม่มีวัตถุดิบชนิดนี้ให้ขาย")); return
			set(item,int(get(item))-1)
			coins+=int(prices[item])
			tell(story.l("Ingredient sold · +%d vatu","ขายวัตถุดิบแล้ว · +%d วาตู") % int(prices[item]))
		if is_instance_valid(audio): audio.play_sfx("eat" if option=="restaurant_meal" else "pickup",1.0,-2.0)
	elif panel=="hotel" and option=="sleep" and hotel.contains(player.position):
		if coins<10: tell(story.l("A room costs 10 vatu.","ค่าห้อง 10 วาตู เงินยังไม่พอ ลองขายวัตถุดิบที่ Pad Thai")); return
		coins-=10
		var hours := fposmod(8.0-day_time,24.0)
		if hours<.1: hours=24.0
		advance_hours(hours)
		energy=100; stamina=100; sprint_locked=false; health=minf(100,health+30)
		food=maxf(5,food-8); thirst=maxf(5,thirst-10)
		player.position=hotel.rest_point
		player.velocity=Vector3.ZERO
		panel=""
		resting=true
		field_hud.sleep_effect=1.0
		if is_instance_valid(audio): audio.play_sfx("rest",1.0,-2.0)
		world.update_daylight(day_time,true)
		tell(story.l("08:00 · A fresh morning at Seaside Inn.","08:00 · ตื่นรับวันใหม่ที่ Seaside Inn พร้อมพลังเต็มแล้ว"))
		get_tree().create_timer(1.2).timeout.connect(func(): resting=false)

func save_game() -> void:
	var gathered := []
	for item in resources:
		if item.collected: gathered.append(item.id)
	var data := {"version":2,"position":[player.position.x,player.position.y,player.position.z],"health":health,"food":food,"thirst":thirst,"energy":energy,"stamina":stamina,"fish":fish,"cooked_fish":cooked_fish,"coconuts":coconuts,"wood":wood,"coins":coins,"friendship":friendship,"delivered_fish":delivered_fish,"days":days,"day_time":day_time,"gathered":gathered}
	data["story"]=story.data()
	var file := FileAccess.open("user://efate_life_save.json",FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		tell("Island life saved.")
	else: tell("Save failed. Please check available storage.")

func load_game() -> void:
	if not FileAccess.file_exists("user://efate_life_save.json"): tell("No island-life save yet."); return
	var data = JSON.parse_string(FileAccess.get_file_as_string("user://efate_life_save.json"))
	if not data is Dictionary or data.get("version")!=2: tell("This save cannot be loaded."); return
	var p = data.get("position")
	if not p is Array or p.size()!=3: return
	for v in p:
		if not (v is int or v is float) or not is_finite(float(v)): return
	var loaded := Vector3(float(p[0]),float(p[1]),float(p[2]))
	if absf(loaded.x)>1400 or absf(loaded.z)>1400 or ground(loaded.x,loaded.z)<-0.4: return
	loaded.y=maxf(loaded.y,ground(loaded.x,loaded.z)+0.25)
	for key in ["health","food","thirst","energy","stamina"]:
		var value = data.get(key,100)
		if not (value is int or value is float) or not is_finite(float(value)): return
	for key in ["fish","cooked_fish","coconuts","wood","coins","friendship","delivered_fish","days","day_time"]:
		var value = data.get(key,0)
		if not (value is int or value is float) or not is_finite(float(value)): return
	for key in ["health","food","thirst","energy","stamina"]: set(key,clampf(float(data.get(key,100)),0,100))
	for key in ["fish","cooked_fish","coconuts","wood","coins","friendship","delivered_fish"]: set(key,clampi(int(data.get(key,0)),0,99999))
	days=clampi(int(data.get("days",1)),1,99999)
	day_time=clampf(float(data.get("day_time",8)),0,23.999)
	story.restore(data.get("story",{}))
	var gathered = data.get("gathered",[])
	if not gathered is Array: gathered=[]
	for item in resources:
		item.collected=item.id in gathered
		item.node.visible=not item.collected
	leave_car(true)
	player.position=loaded
	player.velocity=Vector3.ZERO
	cancel_fishing()
	tell("Welcome back to your island life.")
