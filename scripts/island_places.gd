extends Node3D
## Source-linked island inventory. Only thirteen interpreted landmarks add buildings; other pins remain pins.
var game: Node3D
var entries: Array = []
var by_id := {}
var featured := {}
var nearby: Array = []
var labels: Array[Label3D] = []
var timer := 0.0
var selected := ""
var materials=preload("res://scripts/coastal_materials.gd").new()
func _init() -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/geography/efate-places.json"))
	entries=data.entries
	for entry in entries: by_id[entry.id]=entry
func build(owner_game: Node3D) -> void:
	game=owner_game
	for site in preload("res://scripts/place_sites.gd").SITES:
		var at := Vector2(site.at[0],site.at[1])
		var node: Node3D=game.landmarks.place(site.category,at,Vector2(site.size[0],site.size[1]),site.facing,"coastal_detail")
		node.name=site.name.validate_node_name()
		materials.polish(node)
		featured[site.id]=node
		var sign := Label3D.new()
		node.add_child(sign)
		sign.text=site.name
		sign.font=load("res://assets/fonts/NotoSansThai.ttf")
		sign.position=Vector3(0,2.65,site.size[1]/2+.23)
		sign.font_size=40
		sign.pixel_size=.006
		sign.modulate=Color("f0dfb5")
		sign.outline_modulate=Color("16372f")
		sign.outline_size=8
		sign.visibility_range_end=70
		# Use the doorway/public landing as access; geographic pins remain unmodified in the atlas.
		by_id[site.id]["access"]=node.to_global(Vector3(0,0,site.size[1]/2+1))
	for i in range(8):
		var label := Label3D.new()
		add_child(label)
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.font=load("res://assets/fonts/NotoSansThai.ttf")
		label.font_size=30
		label.pixel_size=.005
		label.no_depth_test=false
		label.visibility_range_end=32
		labels.append(label)
func at(entry: Dictionary) -> Vector3:
	return Vector3(entry.at[0],game.world.surface_height_at(entry.at[0],entry.at[1]),entry.at[1])
func target(id: String) -> Vector3:
	if not by_id.has(id): return game.spawn
	var entry: Dictionary=by_id[id]
	if entry.has("access") and entry.access.y>=.05: return entry.access
	var pin := at(entry)
	# For offshore sites, guide to the closest accessible shore instead of the seabed.
	if pin.y<-.25:
		var best := Vector3.INF
		var distance := INF
		for radius in [8.0,16.0,32.0,64.0,128.0]:
			for angle in range(16):
				var candidate: Vector3=pin+Vector3(cos(angle*TAU/16)*radius,0,sin(angle*TAU/16)*radius)
				candidate.y=game.world.surface_height_at(candidate.x,candidate.z)
				if candidate.y>=.1 and candidate.distance_squared_to(pin)<distance: best=candidate; distance=candidate.distance_squared_to(pin)
			if distance<INF: return best
	return pin
func search(query: String) -> Array:
	if query.strip_edges().is_empty(): return entries
	var result: Array = []
	var wanted := query.strip_edges().to_lower()
	for entry in entries:
		if (entry.name+" "+entry.category+" "+category_label(entry.category)).to_lower().contains(wanted): result.append(entry)
	return result
func category_label(category: String) -> String:
	var names := {"airport":"สนามบิน","lagoon":"แอ่งน้ำ","river":"แม่น้ำ","culture":"วัฒนธรรม","beach":"ชายหาด","waterfall":"น้ำตก","hospital":"โรงพยาบาล","market":"ตลาด","cave":"ถ้ำ","underwater_post":"ไปรษณีย์ใต้น้ำ","museum":"พิพิธภัณฑ์","post":"ไปรษณีย์","food":"อาหาร","community":"ชุมชน","shop":"ร้านค้า","village":"หมู่บ้าน","health":"สุขภาพ","visit":"ท่องเที่ยว","school":"โรงเรียน","service":"บริการ","ferry":"ท่าเรือ"}
	return game.story.l(category,names.get(category,category))
func update(dt: float) -> void:
	timer-=dt
	if timer>0: return
	timer=1.0
	nearby.clear()
	for entry in entries:
		var point: Vector3=entry.access if entry.has("access") else at(entry)
		var distance: float=Vector2(point.x-game.player.position.x,point.z-game.player.position.z).length()
		if distance<32: nearby.append({"entry":entry,"distance":distance})
		if distance<12 and entry.id not in game.story.discovered:
			game.story.discovered.append(entry.id)
			if entry.featured: game.tell(game.story.l("Discovered: ","ค้นพบ: ")+entry.name)
	nearby.sort_custom(func(a: Dictionary,b: Dictionary): return a.distance<b.distance)
	for i in range(labels.size()):
		labels[i].visible=i<nearby.size()
		if i>=nearby.size(): continue
		var entry: Dictionary=nearby[i].entry
		labels[i].text=entry.name
		labels[i].position=(entry.access if entry.has("access") else at(entry))+Vector3.UP*2.2
func context() -> String:
	for item in nearby:
		var goal := target(item.entry.id)
		if game.player.position.distance_to(goal)<3: return game.story.l("ABOUT THIS PLACE · ","รู้จักสถานที่ · ")+item.entry.name
	return ""
func interact() -> bool:
	for item in nearby:
		if game.player.position.distance_to(target(item.entry.id))<3:
			selected=item.entry.id
			game.panel="place_info"
			return true
	return false
func description(entry: Dictionary) -> String:
	var texts := {"market":["Discover local produce and meet the people who supply the island.","รู้จักผลผลิตท้องถิ่นและผู้คนที่นำอาหารมาเลี้ยงชุมชนบนเกาะ"],"museum":["Learn about island history and cultural traditions. Ask hosts before photographing exhibits.","เรียนรู้ประวัติศาสตร์และวัฒนธรรมเกาะ ถามเจ้าบ้านก่อนถ่ายรูปสิ่งจัดแสดง"],"waterfall":["Freshwater cascades and limestone pools. Follow paths and respect local hosts.","น้ำตกน้ำจืดและแอ่งหินปูน เดินตามทางและเคารพเจ้าบ้าน"],"lagoon":["A coastal lagoon where the shoreline meets clear water.","แอ่งน้ำใกล้ชายฝั่ง จุดที่ธรรมชาติบนบกเชื่อมกับน้ำใส"],"hospital":["A mapped hospital serving the island community.","โรงพยาบาลที่ให้บริการชุมชนบนเกาะ"],"airport":["The island's air connection. The model stands at the mapped international terminal.","ประตูทางอากาศของเกาะ โมเดลตั้งอยู่ที่พิกัดอาคารผู้โดยสารระหว่างประเทศ"],"culture":["Meet your hosts and listen to stories about local customs.","ทักทายเจ้าบ้านและฟังเรื่องราวเกี่ยวกับวิถีชีวิตท้องถิ่น"]}
	var text: Array=texts.get(entry.category,["Explore this mapped place and greet its neighbours.","สำรวจสถานที่บนแผนที่และทำความรู้จักเพื่อนบ้านบริเวณนี้"])
	return game.story.l(text[0],text[1])+"\n"+game.story.l("Location: ","พิกัด: ")+"%.6f, %.6f" % [entry.latitude,entry.longitude]+"\n"+game.story.l("Architecture is interpreted; the map pin follows the location source.","อาคารเป็นแบบตีความ ตำแหน่งหมุดอิงข้อมูลสถานที่")
