extends RefCounted
## Roads are used for long journeys; nearby goals use direct walking guidance.
var game: Node3D
var graph := AStar3D.new()
var positions: Array[Vector3] = []
var tangents: Array[Vector2] = []
var route := PackedVector3Array()
var next_point := Vector3.ZERO
var last_goal := Vector3.INF
var timer := 0.0
var road_route := false
var path := PackedVector3Array()
var segment := 0
var remaining := 0.0
var arrived := false
var rebuild_count := 0

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
		for sample_index in range(samples.size()):
			var p: Vector2=samples[sample_index]
			var tangent: Vector2=(samples[mini(sample_index+1,samples.size()-1)]-samples[maxi(0,sample_index-1)]).normalized()
			var key := Vector2i(roundi(p[0]*10),roundi(p[1]*10))
			if not ids.has(key):
				var at := Vector3(p[0],game.ground(p[0],p[1])+0.35,p[1])
				ids[key]=positions.size()
				positions.append(at)
				tangents.append(tangent)
				graph.add_point(ids[key],at)
				var cell := Vector2i(floori(at.x/10.0),floori(at.z/10.0))
				for ox in range(-1,2):
					for oz in range(-1,2):
						for other in cells.get(cell+Vector2i(ox,oz),[]):
							var gap: float=positions[other].distance_to(at)
							# Junctions may fall between 7m samples; avoid shortcuts across parallel streets.
							if gap<1.8 or (gap<5.0 and absf(tangent.dot(tangents[other]))<0.85): graph.connect_points(ids[key],other,true)
				if not cells.has(cell): cells[cell]=[]
				cells[cell].append(ids[key])
			var current: int=ids[key]
			if previous>=0 and previous!=current: graph.connect_points(previous,current,true)
			previous=current

func update(dt: float,force := false) -> void:
	timer=maxf(0,timer-dt)
	var goal: Vector3=game.story.target()
	var start: Vector3=game.player.position
	var off_route := INF
	for i in range(maxi(0,segment-1),path.size()-1):
		off_route=minf(off_route,flat(start).distance_to(Geometry2D.get_closest_point_to_segment(flat(start),flat(path[i]),flat(path[i+1]))))
	if force or goal.distance_to(last_goal)>8.0 or path.size()<2 or (timer<=0 and off_route>18):
		rebuild_count+=1
		timer=2.0
		last_goal=goal
		segment=0
		path=PackedVector3Array([start,goal])
		road_route=false
		if start.distance_to(goal)>100.0 and not positions.is_empty():
			var a := graph.get_closest_point(start)
			var b := graph.get_closest_point(goal)
			var road_path := graph.get_point_path(a,b)
			if road_path.size()>1 and road_path[0].distance_to(start)<100 and road_path[road_path.size()-1].distance_to(goal)<100:
				path=PackedVector3Array([start])
				path.append_array(road_path)
				path.append(goal)
				road_route=true
	# Advance along this path rather than repeatedly snapping to the nearest road.
	while segment<path.size()-2:
		var a := flat(path[segment])
		var b := flat(path[segment+1])
		var delta := b-a
		var t := (flat(start)-a).dot(delta)/maxf(delta.length_squared(),0.001)
		if t>=1.0 or flat(start).distance_to(b)<3.5: segment+=1
		else: break
	path[path.size()-1]=goal
	route=PackedVector3Array([start])
	for i in range(segment+1,path.size()): route.append(path[i])
	remaining=0
	for i in range(route.size()-1): remaining+=flat(route[i]).distance_to(flat(route[i+1]))
	arrived=flat(start).distance_to(flat(goal))<(9.0 if arrived else 6.0)
	var lookahead := 14.0 if game.driving==null else 28.0
	next_point=goal
	for i in range(route.size()-1):
		var length := flat(route[i]).distance_to(flat(route[i+1]))
		if length>=lookahead:
			next_point=route[i].lerp(route[i+1],lookahead/maxf(length,0.001))
			break
		lookahead-=length

func flat(point: Vector3) -> Vector2:
	return Vector2(point.x,point.z)

func distance() -> float:
	return remaining

func bearing() -> float:
	var delta: Vector3=next_point-game.player.position
	return atan2(-delta.x,-delta.z)

func active() -> bool:
	return Preferences.navigation and (game.story.stage<game.story.COMPLETE_STAGE or game.story.tracked_place!="")
