extends Control
## North-up local map. Reuses the island atlas and redraws at 10Hz; no extra viewport.
var game: Node3D
var content: Control
var clip: Control
var font: Font=preload("res://assets/fonts/NotoSansThai.ttf")
var roads: Array[Dictionary] = []
var timer := 0.0
const MAP_SIZE := 176.0
const GOLD := Color("dbbd7d")
const PAPER := Color("e9e5d9")

class MapContent extends Control:
	var minimap: Control
	func _draw() -> void:
		minimap.draw_local_map(self)

func _ready() -> void:
	size=Vector2(196,224)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	font.fallbacks=[ThemeDB.fallback_font]
	clip=Control.new()
	clip.position=Vector2(10,10)
	clip.size=Vector2.ONE*MAP_SIZE
	clip.clip_contents=true
	clip.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(clip)
	content=MapContent.new()
	content.minimap=self
	content.size=clip.size
	content.mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip.add_child(content)
	for road in game.world.geography.roads:
		var points := PackedVector2Array()
		for point in road.points: points.append(Vector2(point[0],point[1]))
		if points.size()<2: continue
		var bounds := Rect2(points[0],Vector2.ZERO)
		for point in points: bounds=bounds.expand(point)
		roads.append({"points":points,"bounds":bounds.grow(1.0),"major":road.type in ["secondary","tertiary"]})

func radius() -> float:
	return 220.0 if game.driving else 115.0

func map_point(world: Vector2) -> Vector2:
	return Vector2.ONE*MAP_SIZE*0.5+(world-Vector2(game.player.position.x,game.player.position.z))*(MAP_SIZE/(radius()*2.0))

func player_direction() -> Vector2:
	if game.driving:
		var forward: Vector3=game.driving.forward()
		return Vector2(forward.x,forward.z).normalized()
	return Vector2(-sin(game.player.rotation.y),-cos(game.player.rotation.y))

func goal_marker(world: Vector2) -> Dictionary:
	var point := map_point(world)
	var center := Vector2.ONE*MAP_SIZE*0.5
	var area := Rect2(Vector2.ONE*12,Vector2.ONE*(MAP_SIZE-24))
	var inside := area.has_point(point)
	var direction: Vector2=(point-center).normalized()
	if not inside:
		var extent: float=MAP_SIZE*0.5-12
		var length: float=extent/maxf(absf(direction.x),absf(direction.y))
		point=center+direction*length
	return {"point":point,"inside":inside,"direction":direction}

func _process(dt: float) -> void:
	position=Vector2(24,236 if game.field_hud.mobile else 108)
	visible=not game.blocked()
	if not visible: return
	timer-=dt
	if timer<=0:
		timer=0.1
		queue_redraw()
		content.queue_redraw()

func _draw() -> void:
	draw_style_box(preload("res://scripts/ui_style.gd").panel(Color(0.035,0.07,0.09,0.94),10),Rect2(Vector2.ZERO,size))
	draw_string(font,Vector2(12,211),game.story.l("MINIMAP · M / MAP","มินิแมป · M / แผนที่"),HORIZONTAL_ALIGNMENT_LEFT,-1,12,PAPER)

func draw_local_map(canvas: Control) -> void:
	var scale: float=MAP_SIZE/(radius()*2.0)
	var center := Vector2.ONE*MAP_SIZE*0.5
	var player := Vector2(game.player.position.x,game.player.position.z)
	canvas.draw_rect(Rect2(Vector2.ZERO,Vector2.ONE*MAP_SIZE),Color("26434c"))
	canvas.draw_texture_rect(game.world.map_texture,Rect2(center-(player+Vector2.ONE*1440.0)*scale,Vector2.ONE*2880.0*scale),false,Color(0.85,0.9,0.86))
	var world_area := Rect2(player-Vector2.ONE*radius(),Vector2.ONE*radius()*2.0)
	for road in roads:
		if not road.bounds.intersects(world_area): continue
		var points := PackedVector2Array()
		for point in road.points: points.append(map_point(point))
		canvas.draw_polyline(points,Color(0.86,0.85,0.74,0.78),2 if road.major else 1,true)
	if game.navigation.active():
		var line := PackedVector2Array()
		for point: Vector3 in game.navigation.route: line.append(map_point(Vector2(point.x,point.z)))
		if line.size()>1:
			canvas.draw_polyline(line,Color("102f36"),6,true)
			canvas.draw_polyline(line,GOLD,2.5,true)
		var target: Vector3=game.story.target()
		var marker := goal_marker(Vector2(target.x,target.z))
		var at: Vector2=marker.point
		if marker.inside:
			canvas.draw_circle(at,6,Color("14272e"))
			canvas.draw_arc(at,4,0,TAU,20,GOLD,2,true)
		else:
			var direction: Vector2=marker.direction
			var side := Vector2(-direction.y,direction.x)
			canvas.draw_colored_polygon(PackedVector2Array([at+direction*5,at-direction*4+side*4,at-direction*4-side*4]),GOLD)
	var restaurant_at: Vector2=map_point(preload("res://scripts/elluk_restaurant.gd").SITE)
	if Rect2(Vector2.ONE*5,Vector2.ONE*(MAP_SIZE-10)).has_point(restaurant_at): canvas.draw_circle(restaurant_at,3,GOLD)
	var spa_at: Vector2=map_point(preload("res://scripts/sunshine_spa.gd").SITE)
	if Rect2(Vector2.ONE*5,Vector2.ONE*(MAP_SIZE-10)).has_point(spa_at):
		canvas.draw_rect(Rect2(spa_at-Vector2.ONE*3,Vector2.ONE*6),Color("9ad1bc"))
	for site in [game.landmarks.PORT,game.landmarks.BAR]:
		var landmark_at: Vector2=map_point(site)
		if Rect2(Vector2.ONE*5,Vector2.ONE*(MAP_SIZE-10)).has_point(landmark_at): canvas.draw_circle(landmark_at,3,Color("dda76c"))
	for npc in game.villagers:
		if not npc.get("active",true): continue
		var at: Vector2=map_point(Vector2(npc.body.position.x,npc.body.position.z))
		if Rect2(Vector2.ONE*3,Vector2.ONE*(MAP_SIZE-6)).has_point(at): canvas.draw_circle(at,1.7,Color("9ad1bc"))
	var forward := player_direction()
	var side := Vector2(-forward.y,forward.x)
	canvas.draw_circle(center,10,Color(0.03,0.09,0.12,0.7))
	canvas.draw_colored_polygon(PackedVector2Array([center+forward*8,center-forward*5+side*5,center-forward*5-side*5]),PAPER)
	canvas.draw_circle(Vector2(MAP_SIZE-15,15),11,Color(0.03,0.09,0.12,0.85))
	canvas.draw_string(font,Vector2(MAP_SIZE-20,20),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,12,GOLD)
