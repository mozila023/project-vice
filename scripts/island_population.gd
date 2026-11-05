extends RefCounted
## Residents have homes and working hours. Only nearby residents consume animation/physics time.
const ZONES := [["Mele",-489,141],["Port Vila",-254,438],["Sunshine",-230,432],["Ifira Port",-290,520],["Pango",-374,643],["Eton",1059,488],["Port Havannah",-462,-533],["Emua",106,-685],["Mangaliliu",-849,-135],["East coast",915,106]]
var game: Node3D
var records: Array[Dictionary] = []
var timer := 0.0
func build(owner_game: Node3D) -> void:
	game=owner_game
	var names := ["Maya","Jonas","Lina","David","Ana","Peter","Sera","Thomas","Rose","Ben","Mary","Paul","Tavi","Rita","Joseph","Elise","Noah","Lea","Sam","Nora","Joel","Mila","Daniel","Grace","Eli","Sara","Tom","Eva","Lucas","Nina"]
	for zone in range(ZONES.size()):
		var info: Array=ZONES[zone]
		for i in range(3):
			var at := Vector3(info[1],0,info[2])
			var id: int=game.navigation.graph.get_closest_point(at)
			var points: Array[Vector3] = []
			for leg in range(5):
				var p: Vector3=game.navigation.graph.get_point_position(id)
				p+=Vector3(2.6 if i%2==0 else -2.6,0,0)
				p.y=game.world.surface_height_at(p.x,p.z)+.1
				points.append(p)
				var links: PackedInt64Array=game.navigation.graph.get_point_connections(id)
				if links.size()>0: id=links[(i+leg)%links.size()]
			records.append({"name":names[zone*3+i],"region":info[0],"at":at,"points":points,"start":6.0+i*.5,"end":19.0+i*.5})
	# Workers and evening guests use clear aisles on the raised Blender decks.
	for i in range(9,12):
		var points: Array[Vector3] = []
		for z in [11.0,13.5]: points.append(game.landmarks.port.to_global(Vector3(13+(i-9)*2.7,.1,z)))
		records[i].points=points
	for i in range(12,15):
		var points: Array[Vector3] = []
		for z in [1.8,4.8]: points.append(game.landmarks.bar.to_global(Vector3((i-13)*2.1,.1,z)))
		records[i].points=points
	# A small night watch; ordinary residents go home. Bar neighbours gather only in the evening.
	records[4].start=20.0; records[4].end=6.0
	for i in range(12,15): records[i].start=16.0; records[i].end=23.0
	for i in range(9,12): records[i].start=7.0; records[i].end=18.0
	for i in range(12):
		var body := CharacterBody3D.new()
		game.add_child(body)
		game.capsule(body)
		var visual: Node3D=game.people.create(i,1.68+(i%3)*.05)
		body.add_child(visual)
		visual.rotation.y=PI
		game.villagers.append({"body":body,"visual":visual,"name":"","points":[],"target":0,"wait":0.0,"speed":1.05+(i%3)*.1,"check_at":Vector3.ZERO,"check_time":0.0,"active":false,"record":-1,"region":""})
	refresh()
func awake(record: Dictionary) -> bool:
	var hour: float=game.day_time
	return (hour>=record.start or hour<record.end) if record.start>record.end else (hour>=record.start and hour<record.end)
func update(dt: float) -> void:
	timer-=dt
	if timer<=0:
		timer=1.0
		refresh()
func refresh() -> void:
	var desired: Array[int] = []
	for i in range(records.size()):
		var record: Dictionary=records[i]
		if awake(record) and Vector2(record.at.x,record.at.z).distance_to(Vector2(game.player.position.x,game.player.position.z))<230: desired.append(i)
	desired.sort_custom(func(a: int,b: int): return records[a].at.distance_squared_to(game.player.position)<records[b].at.distance_squared_to(game.player.position))
	if desired.size()>12: desired.resize(12)
	for npc in game.villagers:
		if npc.get("guide",false): continue
		if npc.record not in desired:
			npc.active=false
			npc.body.hide()
			npc.body.collision_layer=0
			npc.body.collision_mask=0
			npc.body.position=Vector3(0,-1000,0)
			npc.record=-1
	for id in desired:
		var occupied := false
		for npc in game.villagers:
			if npc.get("record",-1)==id: occupied=true
		if occupied: continue
		for npc in game.villagers:
			if npc.get("guide",false) or npc.active: continue
			var record: Dictionary=records[id]
			npc.record=id; npc.active=true; npc.name=record.name; npc.region=record.region
			npc.points=record.points; npc.target=id%npc.points.size(); npc.wait=1.0
			npc.body.position=npc.points[npc.target]
			npc.check_at=npc.body.position; npc.check_time=0.0
			npc.body.collision_layer=2
			npc.body.collision_mask=game.VILLAGER_MASK
			npc.body.show()
			break
func region_for(name: String) -> String:
	for record in records:
		if record.name==name: return record.region
	return ""
