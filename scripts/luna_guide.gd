extends RefCounted
const START := preload("res://scripts/sunshine_spa.gd").SPAWN+Vector2(-1.4,-1.4)
var game: Node3D
var body: CharacterBody3D
var visual: Node3D
var route := PackedVector3Array()
var waypoint := 0
var destination := Vector3.INF
var planned_goal := Vector3.INF
var route_retry := 0.0
var waiting := false
var stuck := 0.0
var last_position := Vector3.ZERO
var turn_side := 1.0
var speech_state := false
var speech_poll := 0

func build(owner_game: Node3D) -> void:
	game=owner_game
	body=CharacterBody3D.new()
	body.name="Luna"
	game.add_child(body)
	game.capsule(body)
	body.collision_mask=game.VILLAGER_MASK
	body.position=Vector3(START.x,game.world.surface_height_at(START.x,START.y)+.05,START.y)
	visual=game.people.create(0,1.68)
	body.add_child(visual)
	visual.rotation.y=PI
	game.luna=body
	game.villagers.append({"body":body,"visual":visual,"name":"Luna","guide":true})
	last_position=body.position

func goal() -> Vector3:
	var at: Vector2=game.restaurant.SITE+Vector2(0,15.5) if game.story.stage==1 else game.hotel.ENTRANCE+Vector2(0,1.5)
	return Vector3(at.x,game.world.surface_height_at(at.x,at.y),at.y)

func make_route() -> void:
	destination=goal()
	planned_goal=destination
	route_retry=2.0
	route=PackedVector3Array()
	# Plan around actual building/cars/trunk collision, including the restaurant's rear wall.
	var grid := AStarGrid2D.new()
	var from := Vector2i(roundi(body.position.x/2),roundi(body.position.z/2))
	var to := Vector2i(roundi(destination.x/2),roundi(destination.z/2))
	# The 1:10 hotel leg bends around the harbour; a narrow rectangle would cut across water.
	var margin := 85 if game.story.stage==3 else 20
	var low := Vector2i(mini(from.x,to.x)-margin,mini(from.y,to.y)-margin)
	var high := Vector2i(maxi(from.x,to.x)+margin,maxi(from.y,to.y)+margin)
	grid.region=Rect2i(low,high-low+Vector2i.ONE)
	grid.cell_size=Vector2.ONE*2
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	var shape := CapsuleShape3D.new()
	shape.radius=.8
	shape.height=1.75
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape=shape
	query.collision_mask=1|4|8
	query.exclude=[body.get_rid()]
	var space := body.get_world_3d().direct_space_state
	for x in range(low.x,high.x+1):
		for z in range(low.y,high.y+1):
			var at := Vector3(x*2,game.world.surface_height_at(x*2,z*2),z*2)
			query.transform=Transform3D(Basis.IDENTITY,at+Vector3.UP*.94)
			if at.y<.02 or not space.intersect_shape(query,1).is_empty(): grid.set_point_solid(Vector2i(x,z))
	grid.set_point_solid(from,false)
	# A shore-side porch may cover the nearest ground cell. Choose a genuinely open public approach.
	var candidates: Array[Vector2i] = []
	for dx in range(-8,9):
		for dz in range(-8,9):
			var candidate := to+Vector2i(dx,dz)
			if grid.region.has_point(candidate) and not grid.is_point_solid(candidate): candidates.append(candidate)
	candidates.sort_custom(func(a: Vector2i,b: Vector2i): return a.distance_squared_to(to)<b.distance_squared_to(to))
	var path: Array[Vector2i] = []
	for candidate in candidates:
		path=grid.get_id_path(from,candidate)
		if path.size()>1:
			destination=Vector3(candidate.x*2,game.world.surface_height_at(candidate.x*2,candidate.y*2),candidate.y*2)
			break
	for i in range(1,path.size()):
		if i<path.size()-1 and path[i]-path[i-1]==path[i+1]-path[i]: continue
		var at := Vector3(path[i].x*2,0,path[i].y*2)
		at.y=game.world.surface_height_at(at.x,at.z)
		route.append(at)
	if path.size()>1: route.append(destination)
	waypoint=0
	stuck=0

func clear_path() -> void:
	destination=Vector3.INF
	planned_goal=Vector3.INF
	route.clear()
	waiting=false

func speak_dialogue() -> void:
	if OS.has_feature("web"):
		var text := JSON.stringify(game.story.dialogue())
		var language := "th-TH" if game.story.language=="th" else "en-AU"
		JavaScriptBridge.eval("(()=>{if(!window.speechSynthesis)return;window.speechSynthesis.cancel();const line=new SpeechSynthesisUtterance("+text+");line.lang='"+language+"';line.rate=1.03;line.pitch=1.08;window.speechSynthesis.speak(line);})()",true)

func speaking() -> bool:
	if OS.has_feature("web") and Time.get_ticks_msec()>=speech_poll:
		speech_poll=Time.get_ticks_msec()+200
		speech_state=bool(JavaScriptBridge.eval("!!(window.speechSynthesis&&window.speechSynthesis.speaking)",true))
	return speech_state

func stop_speech() -> void:
	if OS.has_feature("web"): JavaScriptBridge.eval("if(window.speechSynthesis)window.speechSynthesis.cancel()",true)
	speech_state=false

func clear_ahead(direction: Vector3) -> bool:
	var end := body.position+direction*1.3
	if game.ground(end.x,end.z)<-.3: return false
	var side := direction.cross(Vector3.UP)
	for offset in [-.30,0,.30]:
		for height in [.25,.75]:
			var from: Vector3=body.position+Vector3.UP*height+side*float(offset)
			var query := PhysicsRayQueryParameters3D.create(from,from+direction*1.3,1|4|8,[body.get_rid()])
			if not body.get_world_3d().direct_space_state.intersect_ray(query).is_empty(): return false
	return true

func update(dt: float) -> void:
	route_retry=maxf(0,route_retry-dt)
	var touring: bool=game.story.stage in [1,3]
	var gap: float=Vector2(body.position.x-game.player.position.x,body.position.z-game.player.position.z).length()
	if gap>15: waiting=true
	elif gap<10: waiting=false
	var direction := Vector3.ZERO
	if touring and not waiting:
		if (route.is_empty() and route_retry<=0) or planned_goal.distance_to(goal())>1: make_route()
		if route.is_empty():
			body.velocity=Vector3(0,-2.5,0)
			body.move_and_slide()
			game.play_animation(visual,"idle")
			return
		while waypoint<route.size()-1 and Vector2(body.position.x-route[waypoint].x,body.position.z-route[waypoint].z).length()<1.0: waypoint+=1
		if body.position.distance_to(destination)<1.4:
			if gap<8: game.story.arrive()
		else:
			direction=route[waypoint]-body.position
			direction.y=0
			direction=direction.normalized()
			if not clear_ahead(direction):
				var chosen := Vector3.ZERO
				for angle in [turn_side*.7,turn_side*1.2,-turn_side*.7,-turn_side*1.2,turn_side*1.6]:
					var option := direction.rotated(Vector3.UP,angle)
					if clear_ahead(option): chosen=option; break
				direction=chosen
			if body.position.distance_to(last_position)<.015: stuck+=dt
			else: stuck=0
			if stuck>2:
				turn_side=-turn_side
				make_route()
	last_position=body.position
	body.velocity.x=direction.x*2.0
	body.velocity.z=direction.z*2.0
	body.velocity.y-=20*dt
	if body.is_on_floor(): body.velocity.y=-2.5
	body.move_and_slide()
	body.apply_floor_snap()
	var moving: bool=Vector2(body.get_real_velocity().x,body.get_real_velocity().z).length()>.15
	if moving: body.rotation.y=lerp_angle(body.rotation.y,atan2(-direction.x,-direction.z),dt*8)
	elif gap<5:
		var delta: Vector3=game.player.position-body.position
		body.rotation.y=lerp_angle(body.rotation.y,atan2(-delta.x,-delta.z),dt*4)
	game.play_animation(visual,"walk" if moving else "idle",1.3 if moving else 1.0)
	game.foot_contact.update(body,visual,game.world,dt,gap<40)
