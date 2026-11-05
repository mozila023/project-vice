extends Node3D
## Procedural Godot edition of the existing island survival game.
var player: CharacterBody3D
var pivot: Node3D
var camera: Camera3D
var hud: Label
var message: Label
var overlay: Label
var enemies: Array[CharacterBody3D] = []
var supplies: Array[Node3D] = []
var health := 100.0
var stamina := 100.0
var food := 100.0
var ammo := 30
var reserve := 120
var kills := 0
var reload_time := 0.0
var cooldown := 0.0
var paused := false
var panel := ""
var signal_restored := false
var yaw := 0.5
var pitch := -0.12
var elapsed := 0.0
var rng := RandomNumberGenerator.new()
var materials := {}
const SPAWN := Vector3(-245, 7, 510)
var world: Node3D
var field_hud: Control
var walking_phase := 0.0

func mat(key: String, color: Color, roughness := 0.85) -> StandardMaterial3D:
	if materials.has(key):
		return materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	materials[key] = m
	return m

func box(parent: Node3D, title: String, pos: Vector3, size: Vector3, material: Material, solid := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material
	parent.add_child(mesh)
	mesh.position = pos
	if solid:
		var body := StaticBody3D.new()
		mesh.add_child(body)
		var collision := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		collision.shape = bounds
		body.add_child(collision)
	return mesh

func ground(x: float, z: float) -> float:
	return world.height_at(x,z)

func _ready() -> void:
	rng.seed = 42
	for action in ["forward", "back", "left", "right", "sprint", "jump"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var keys := {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D, "sprint": KEY_SHIFT, "jump": KEY_SPACE}
	for action in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)
	build_world()
	build_player()
	build_ui()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if field_hud.mobile else Input.MOUSE_MODE_CAPTURED

func building_material(key: String, color: Color, metal := false) -> ShaderMaterial:
	if materials.has(key): return materials[key]
	var m := ShaderMaterial.new()
	m.shader=load("res://shaders/building.gdshader")
	m.set_shader_parameter("paint",color)
	m.set_shader_parameter("corrugated",metal)
	materials[key]=m
	return m

func build_world() -> void:
	world=preload("res://scripts/tropical_world.gd").new()
	add_child(world)
	world.build()
	var wood := building_material("wood",Color("78664d"))
	var trim := mat("trim",Color("d8d7bd"))
	var glass := mat("glass",Color("23464b"),0.18)
	for i in range(10):
		var x := -220.0+(-25.0 if i%2==0 else 25.0)
		var z := 385.0+floorf(i/2.0)*34.0
		var p := Vector3(x,ground(x,z),z)
		var wall := building_material("wall%d"%(i%3),[Color("d2cfb3"),Color("a7bdb3"),Color("b2bca3")][i%3])
		box(self,"Weatherboard home",p+Vector3(0,2,0),Vector3(10,4,12),wall,true)
		box(self,"Concrete plinth",p+Vector3(0,0.15,0),Vector3(10.5,0.3,12.6),mat("stone",Color("8a8c7b")),true)
		var roof := building_material("roof%d"%(i%2),Color("7b8c88") if i%2==0 else Color("a17b62"),true)
		for side in [-1.0,1.0]:
			var slope := box(self,"Pitched metal roof",p+Vector3(side*2.8,4.5,0),Vector3(6.1,0.13,13.4),roof)
			slope.rotation.z=-side*0.27
		for wx in [-3.1,3.1]:
			box(self,"Window frame",p+Vector3(wx,2.4,6.08),Vector3(2.3,1.75,0.13),trim)
			box(self,"Window glazing",p+Vector3(wx,2.4,6.17),Vector3(2.02,1.48,0.05),glass)
			box(self,"Window mullion",p+Vector3(wx,2.4,6.22),Vector3(0.06,1.5,0.06),trim)
			box(self,"Louver",p+Vector3(wx,2.4,6.25),Vector3(2.0,0.05,0.05),trim)
		box(self,"Timber door",p+Vector3(0,1.5,6.12),Vector3(1.65,3,0.14),wood)
		box(self,"Door handle",p+Vector3(0.55,1.5,6.24),Vector3(0.06,0.18,0.06),glass)
		box(self,"Veranda deck",p+Vector3(0,0.27,7.5),Vector3(9,0.2,3.2),wood,true)
		var awning := box(self,"Veranda roof",p+Vector3(0,3.5,7.4),Vector3(9.5,0.12,3.7),roof)
		awning.rotation.x=-0.12
		for wx in [-4.1,4.1]:
			box(self,"Veranda post",p+Vector3(wx,1.85,8.6),Vector3(0.15,3.2,0.15),trim,true)
		for step in range(3):
			box(self,"Entry step",p+Vector3(0,0.1+step*0.07,9.5-step*0.3),Vector3(2.3,0.2,0.4),wood,true)
		box(self,"Rain tank",p+Vector3(6.2,1.2,2),Vector3(1.8,2.4,2),mat("tank",Color("7e8e79")),true)
		for board in range(4):
			box(self,"Veranda floor seam",p+Vector3(0,0.38,6.6+board*0.65),Vector3(8.8,0.015,0.025),glass)
	var road_surface := SurfaceTool.new()
	road_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in range(340,585,4):
		for v in [Vector2(-225,z),Vector2(-215,z),Vector2(-225,z+4),Vector2(-215,z),Vector2(-215,z+4),Vector2(-225,z+4)]:
			road_surface.add_vertex(Vector3(v.x,ground(v.x,v.y)+0.07,v.y))
	road_surface.generate_normals()
	var road := MeshInstance3D.new()
	road.name="Settlement road"
	road.mesh=road_surface.commit()
	road.material_override=building_material("asphalt",Color("555e58"))
	add_child(road)
	for z in range(350,580,9):
		box(self,"Faded lane paint",Vector3(-220,ground(-220,z)+0.1,z),Vector3(0.1,0.012,3),mat("paint",Color("d9d2b5")))
	# Waterfront shelter and timber jetty on the original Mele Bay coast.
	var beach_x := -245.0
	while ground(beach_x,510)>0.5 and beach_x>-500: beach_x-=2
	for i in range(22):
		var x := beach_x+10-i*1.1
		box(self,"Jetty plank",Vector3(x,1.15,510),Vector3(1.02,0.18,3.5),wood,true)
		if i%4==0:
			for z in [-1.5,1.5]:
				box(self,"Jetty piling",Vector3(x,-0.2,510+z),Vector3(0.2,4,0.2),wood,true)
	var tower := Vector3(0,ground(0,0),0)
	for x in [-2.0,2.0]:
		box(self,"Radio mast",tower+Vector3(x,15,0),Vector3(0.22,30,0.22),mat("steel",Color("8b9997")),true)
	for h in range(2,30,3):
		box(self,"Tower crossbrace",tower+Vector3(0,h,0),Vector3(4.2,0.12,0.18),trim)
	box(self,"Radio antenna",tower+Vector3(0,29,0),Vector3(12,0.2,0.2),trim)
	merge_static_meshes()
	for i in range(10):
		var x := -220.0+(-9.0 if i%2==0 else 9.0)
		var z := 390.0+i*18
		var p := Vector3(x,ground(x,z)+0.35,z)
		var item := box(self,"Supply case",p,Vector3(0.8,0.55,0.6),mat("supply",Color("807954")))
		box(item,"Medical stripe",Vector3(0,0.29,0),Vector3(0.16,0.025,0.62),trim)
		supplies.append(item)
	for i in range(14):
		var enemy := CharacterBody3D.new()
		add_child(enemy)
		var x := rng.randf_range(-280,-100)
		var z := rng.randf_range(190,390)
		enemy.position=Vector3(x,ground(x,z)+0.3,z)
		add_capsule(enemy)
		humanoid(enemy,true)
		enemies.append(enemy)

func merge_static_meshes() -> void:
	var groups := {}
	for node in get_children():
		if not node is MeshInstance3D: continue
		var material: Material=node.material_override
		var key := str(material.get_instance_id())+"_"+str(floori(node.position.z/120))
		if not groups.has(key):
			var s := SurfaceTool.new()
			s.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[key]={"tool":s,"mat":material}
		groups[key].tool.append_from(node.mesh,0,node.transform)
		for child in node.get_children():
			if child is StaticBody3D: child.reparent(self,true)
		node.queue_free()
	for key in groups:
		var merged := MeshInstance3D.new()
		merged.name="VillageBatch_"+key
		merged.mesh=groups[key].tool.commit()
		merged.material_override=groups[key].mat
		merged.visibility_range_end=500
		add_child(merged)

func add_capsule(body: CharacterBody3D) -> void:
	var c := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.8
	c.shape = shape
	c.position.y = 0.9
	body.add_child(c)

func rounded(parent: Node3D, title: String, pos: Vector3, scale: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name=title
	var shape := SphereMesh.new()
	shape.radial_segments=10
	shape.rings=6
	shape.radius=0.5
	shape.height=1
	node.mesh=shape
	node.material_override=material
	parent.add_child(node)
	node.position=pos
	node.scale=scale
	return node

func humanoid(parent: Node3D, infected: bool) -> void:
	var cloth := mat("infected" if infected else "jacket",Color("697252") if infected else Color("3b5351"))
	var skin := mat("skin",Color("a88a66"))
	var dark := mat("pants",Color("39443a"))
	rounded(parent,"Torso",Vector3(0,1.2,0),Vector3(0.55,0.72,0.34),cloth)
	rounded(parent,"Head",Vector3(0,1.73,0),Vector3(0.29,0.37,0.31),skin)
	rounded(parent,"Hair",Vector3(0,1.86,0.02),Vector3(0.3,0.17,0.31),dark)
	for x in [-0.15,0.15]:
		var leg := Node3D.new()
		leg.name="LeftLeg" if x<0 else "RightLeg"
		parent.add_child(leg)
		leg.position=Vector3(x,0.86,0)
		rounded(leg,"Trouser",Vector3(0,-0.33,0),Vector3(0.22,0.72,0.25),dark)
		rounded(leg,"Boot",Vector3(0,-0.77,-0.06),Vector3(0.24,0.2,0.37),mat("boots",Color("514b3d")))
		var arm := Node3D.new()
		arm.name="LeftArm" if x<0 else "RightArm"
		parent.add_child(arm)
		arm.position=Vector3(x*2.1,1.43,0)
		rounded(arm,"Sleeve",Vector3(0,-0.13,0),Vector3(0.23,0.36,0.25),cloth)
		rounded(arm,"Forearm",Vector3(0,-0.4,-0.04),Vector3(0.15,0.31,0.17),skin)
		rounded(arm,"Hand",Vector3(0,-0.57,-0.08),Vector3(0.16,0.15,0.17),skin)
		if infected: arm.rotation.x=-0.9
	if not infected:
		rounded(parent,"Backpack",Vector3(0,1.25,0.28),Vector3(0.46,0.6,0.27),mat("pack",Color("7d7956")))
		for x in [-0.18,0.18]:
			box(parent,"Harness",Vector3(x,1.2,-0.18),Vector3(0.045,0.53,0.04),dark)
		box(parent,"Carbine",Vector3(0.35,1.08,-0.42),Vector3(0.09,0.14,0.8),mat("gun",Color("293537")))

func animate_actor(actor: Node3D, speed: float, time: float, infected := false) -> void:
	var swing := sin(time*8.0)*minf(speed/4.5,1.0)*0.48
	actor.get_node("LeftLeg").rotation.x=swing
	actor.get_node("RightLeg").rotation.x=-swing
	if not infected:
		actor.get_node("LeftArm").rotation.x=-swing*0.5
		actor.get_node("RightArm").rotation.x=-0.25+swing*0.3

func build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Survivor"
	add_child(player)
	player.position = Vector3(SPAWN.x,ground(SPAWN.x,SPAWN.z)+0.3,SPAWN.z)
	add_capsule(player)
	humanoid(player,false)
	pivot = Node3D.new()
	add_child(pivot)
	var arm := SpringArm3D.new()
	pivot.add_child(arm)
	arm.spring_length = 5.8
	arm.margin = 0.2
	arm.add_excluded_object(player.get_rid())
	camera = Camera3D.new()
	arm.add_child(camera)
	camera.current = true
	camera.fov = 65
	camera.far = 5000

func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	field_hud=preload("res://scripts/field_hud.gd").new()
	field_hud.game=self
	layer.add_child(field_hud)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE: paused = not paused; panel = ""
			KEY_TAB: panel = "" if panel == "pack" else "pack"
			KEY_M: panel = "" if panel == "map" else "map"
			KEY_R:
				if not blocked() and reload_time<=0 and ammo<30 and reserve>0: reload_time=2.1
			KEY_E:
				if not blocked(): collect()
			KEY_F5: save_game()
			KEY_F9: load_game()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if blocked() or field_hud.mobile else Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and not blocked() and not field_hud.mobile:
		yaw -= event.relative.x*0.003
		pitch = clampf(pitch-event.relative.y*0.003,-0.9,0.65)

func blocked() -> bool:
	return paused or panel != ""

func _physics_process(dt: float) -> void:
	if not blocked():
		elapsed += dt
		cooldown = maxf(0,cooldown-dt)
		if reload_time>0:
			reload_time = maxf(0,reload_time-dt)
			if reload_time==0:
				var amount := mini(30-ammo,reserve)
				ammo += amount
				reserve -= amount
		var input := Input.get_vector("left","right","forward","back")
		if field_hud.mobile: input=(input+field_hud.move_vector).limit_length()
		var direction := Basis(Vector3.UP,yaw)*Vector3(input.x,0,input.y)
		var sprint: bool = (Input.is_action_pressed("sprint") or field_hud.running) and stamina>1 and input.length()>0
		var crouch := Input.is_physical_key_pressed(KEY_C)
		var speed := 2.0 if crouch else (8.0 if sprint else 4.5)
		stamina = clampf(stamina+(-18 if sprint and not crouch else 12)*dt,0,100)
		player.velocity.x = direction.x*speed
		player.velocity.z = direction.z*speed
		player.velocity.y -= 22*dt
		if player.is_on_floor():
			player.velocity.y = 7.0 if Input.is_action_just_pressed("jump") else -0.1
		player.move_and_slide()
		player.rotation.y = yaw
		animate_actor(player,Vector2(player.velocity.x,player.velocity.z).length(),elapsed)
		food = maxf(0,food-dt*0.06)
		if food<=0: health -= dt
		if player.position.y < -2: health -= dt*15
		if field_hud.firing or (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED): fire()
		for enemy in enemies:
			var delta := player.position-enemy.position
			delta.y = 0
			var distance := delta.length()
			enemy.velocity = delta.normalized()*1.7 if distance<50 and distance>1.4 else Vector3.ZERO
			enemy.velocity.y = -8
			enemy.move_and_slide()
			animate_actor(enemy,Vector2(enemy.velocity.x,enemy.velocity.z).length(),elapsed,true)
			if distance>0.1 and distance<50: enemy.rotation.y = atan2(-delta.x,-delta.z)
			if distance<1.7 and absf(player.position.y-enemy.position.y)<2:
				var query := PhysicsRayQueryParameters3D.create(enemy.position+Vector3.UP,player.position+Vector3.UP,1,[enemy.get_rid()])
				var hit := get_world_3d().direct_space_state.intersect_ray(query)
				if hit.is_empty() or hit.collider==player: health-=8*dt
		if health<=0:
			player.position = Vector3(SPAWN.x,ground(SPAWN.x,SPAWN.z)+0.3,SPAWN.z)
			player.velocity = Vector3.ZERO
			health = 100
			food = maxf(food,50)
		if Vector2(player.position.x,player.position.z).length()<10: signal_restored=true
	pivot.position = player.position+Vector3(0,1.5,0)
	pivot.rotation = Vector3(pitch,yaw,0)
	camera.fov = lerpf(camera.fov,48.0 if (Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or field_hud.aiming) and not blocked() else 65.0,0.15)
	update_ui()

func fire() -> void:
	if cooldown>0 or reload_time>0 or ammo<=0: return
	ammo -= 1
	cooldown = 0.15
	var origin := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(origin,origin-camera.global_basis.z*100,1,[player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit.collider is CharacterBody3D and hit.collider in enemies:
		enemies.erase(hit.collider)
		hit.collider.queue_free()
		kills += 1
	var flash := OmniLight3D.new()
	player.add_child(flash)
	flash.position = Vector3(0.4,1.2,-0.8)
	flash.light_color = Color("ffd176")
	flash.light_energy = 3
	flash.omni_range = 5
	get_tree().create_timer(0.055).timeout.connect(flash.queue_free)

func collect() -> void:
	for item in supplies:
		if item.global_position.distance_to(player.position)<4:
			reserve+=30
			health=minf(100,health+20)
			food=minf(100,food+20)
			supplies.erase(item)
			item.queue_free()
			break

func update_ui() -> void:
	pass

func save_game() -> void:
	var data := {"version":1,"position":[player.position.x,player.position.y,player.position.z],"health":health,"stamina":stamina,"food":food,"ammo":ammo,"reserve":reserve,"kills":kills,"signal":signal_restored}
	var file := FileAccess.open("user://efate_save.json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(data))

func load_game() -> void:
	if not FileAccess.file_exists("user://efate_save.json"): return
	var data = JSON.parse_string(FileAccess.get_file_as_string("user://efate_save.json"))
	if not data is Dictionary or data.get("version")!=1: return
	var p = data.get("position")
	if not p is Array or p.size()!=3: return
	for value in p:
		if not (value is float or value is int) or not is_finite(float(value)): return
	var loaded := Vector3(float(p[0]),float(p[1]),float(p[2]))
	if absf(loaded.x)>1150 or absf(loaded.z)>1450 or ground(loaded.x,loaded.z)<0: return
	loaded.y = maxf(loaded.y,ground(loaded.x,loaded.z)+0.2)
	player.position = loaded
	player.velocity = Vector3.ZERO
	health=clampf(float(data.get("health",100)),1,100)
	stamina=clampf(float(data.get("stamina",100)),0,100)
	food=clampf(float(data.get("food",100)),0,100)
	ammo=clampi(int(data.get("ammo",30)),0,30)
	reserve=clampi(int(data.get("reserve",120)),0,9999)
	kills=maxi(0,int(data.get("kills",0)))
	signal_restored=bool(data.get("signal",false))
	reload_time=0
