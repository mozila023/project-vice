extends RefCounted
## Roads are used for long journeys; nearby goals use direct walking guidance.
var game: Node3D
var graph := AStar3D.new()
var positions: Array[Vector3] = []
var route := PackedVector3Array()
var next_point := Vector3.ZERO
var last_goal := Vector3.INF
var timer := 0.0
var road_route := false

func build(owner_game: Node3D) -> void:
	game=owner_game
	var ids := {}
	var cells := {}
	for road in game.world.geography.roads:
		if road.type=="runway": continue
		var previous := -1
		var samples: Array[Vector2]=[]
		for segment in range(road.points.size()-1):
			var a := Vector2(road.points[segment][0],road.points[segment][1])
			var b := Vector2(road.points[segment+1][0],road.points[segment+1][1])
			var count := maxi(1,ceili(a.distance_to(b)/7.0))
			for step in range(count+1): samples.append(a.lerp(b,float(step)/count))
		for p in samples:
			var key := Vector2i(roundi(p[0]*10),roundi(p[1]*10))
			if not ids.has(key):
				var at := Vector3(p[0],game.ground(p[0],p[1])+0.35,p[1])
				ids[key]=positions.size()
				positions.append(at)
				graph.add_point(ids[key],at)
				var cell := Vector2i(floori(at.x/10.0),floori(at.z/10.0))
				for ox in range(-1,2):
					for oz in range(-1,2):
						for other in cells.get(cell+Vector2i(ox,oz),[]):
							if positions[other].distance_to(at)<8.5: graph.connect_points(ids[key],other,true)
				if not cells.has(cell): cells[cell]=[]
				cells[cell].append(ids[key])
			var current: int=ids[key]
			if previous>=0 and previous!=current: graph.connect_points(previous,current,true)
			previous=current

func update(dt: float,force := false) -> void:
	timer-=dt
	var goal: Vector3=game.story.target()
	if not force and timer>0 and goal.distance_to(last_goal)<8.0: return
	timer=1.0
	last_goal=goal
	var start: Vector3=game.player.position
	route=PackedVector3Array([start,goal])
	road_route=false
	if start.distance_to(goal)>100.0 and not positions.is_empty():
		var a := graph.get_closest_point(start)
		var b := graph.get_closest_point(goal)
		var path := graph.get_point_path(a,b)
		if path.size()>1 and path[0].distance_to(start)<100.0 and path[path.size()-1].distance_to(goal)<100.0:
			route=PackedVector3Array([start])
			route.append_array(path)
			route.append(goal)
			road_route=true
	next_point=goal
	for i in range(1,route.size()):
		if Vector2(route[i].x-start.x,route[i].z-start.z).length()>10.0:
			next_point=route[i]
			break

func distance() -> float:
	return Vector2(game.player.position.x-last_goal.x,game.player.position.z-last_goal.z).length()

func bearing() -> float:
	var delta: Vector3=next_point-game.player.position
	return atan2(-delta.x,-delta.z)

func active() -> bool:
	return Preferences.navigation and (game.story.stage<6 or game.story.tracked_place!="")
