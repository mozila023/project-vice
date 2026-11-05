extends Control
var game: Node3D
var mobile := OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
var move_vector := Vector2.ZERO
var running := false
var fingers := {}
var stick_origin := Vector2.ZERO
var font: Font
const WHITE := Color("eef4e8")
const GOLD := Color("f5d6a2")
const INK := Color(0.02,0.08,0.09,0.80)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	font=ThemeDB.fallback_font
	font=preload("res://assets/fonts/NotoSansThai.ttf")
	font.fallbacks=[ThemeDB.fallback_font]

func _process(_dt: float) -> void:
	queue_redraw()

func text(at: Vector2,value: String,pixels := 16,color := WHITE) -> void:
	value=preload("res://scripts/island_locale.gd").translate(value,game.story.language)
	draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,color)

func l(en: String,th: String) -> String:
	return game.story.l(en,th)

func paragraph(at: Vector2,value: String,width: float,pixels := 16,color := WHITE) -> void:
	var layout := TextParagraph.new()
	layout.width=width
	layout.break_flags=TextServer.BREAK_MANDATORY|TextServer.BREAK_WORD_BOUND
	layout.add_string(preload("res://scripts/island_locale.gd").translate(value,game.story.language),font,pixels)
	layout.draw(get_canvas_item(),at,color)

func card(rect: Rect2, color := INK) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color=color
	style.set_corner_radius_all(10)
	draw_style_box(style,rect)

func buttons() -> Dictionary:
	var w := size.x
	var h := size.y
	var values := {"pause":Rect2(w-70,20,50,46),"map":Rect2(w-158,20,80,46),"pack":Rect2(w-246,20,80,46),"journal":Rect2(w-350,20,96,46),"language":Rect2(w-438,20,80,46)}
	if game.paused:
		values.merge({"save":Rect2(w/2-150,h/2+25,140,54),"load":Rect2(w/2+10,h/2+25,140,54),"resume":Rect2(w/2-100,h/2+100,200,54)})
	elif game.panel=="talk":
		values.merge({"story":Rect2(w/2-290,h/2+28,580,45),"sell":Rect2(w/2-290,h/2+80,282,45),"meal":Rect2(w/2+8,h/2+80,282,45),"chat":Rect2(w/2-290,h/2+132,380,45),"close":Rect2(w/2+105,h/2+132,185,45)})
	elif game.panel in ["journal","island"]:
		values.merge({"journal":Rect2(w/2-330,h/2-200,150,40),"island":Rect2(w/2-170,h/2-200,170,40),"mode":Rect2(w/2+10,h/2-200,320,40),"track_story":Rect2(w/2-20,h/2+205,225,40),"close":Rect2(w/2+220,h/2+205,110,40)},true)
		if game.panel=="island":
			for i in range(4): values["place_"+str(i)]=Rect2(w/2+220,h/2-123+i*77,108,36)
	elif game.panel!="": values["close"]=Rect2(w/2-70,h-85,140,48)
	elif mobile:
		values.merge({"fish":Rect2(w-138,h-180,96,96),"use":Rect2(w-246,h-140,82,82),"eat":Rect2(w-125,h-285,66,66),"jump":Rect2(w-235,h-240,66,66),"run":Rect2(215,h-120,64,64)})
	return values

func _draw() -> void:
	if not is_instance_valid(game) or game.player==null: return
	var w := size.x
	var h := size.y
	card(Rect2(20,20,320,142))
	text(Vector2(36,48),"EFATE / ISLAND LIFE",21)
	text(Vector2(36,70),l("VANUATU · DAY %02d  %02d:%02d","วานูอาตู · วันที่ %02d  %02d:%02d") % [game.days,int(game.day_time),int(fmod(game.day_time,1)*60)],12,GOLD)
	var stats := [["HEALTH",game.health,Color("c98978")],["FOOD",game.food,Color("c8c391")],["WATER",game.thirst,Color("83c4cf")],["ENERGY",game.energy,Color("a6bf87")]]
	for i in range(stats.size()):
		text(Vector2(36,91+i*19),stats[i][0],10)
		draw_rect(Rect2(103,82+i*19,220,6),Color(0.4,0.5,0.4,0.4))
		draw_rect(Rect2(103,82+i*19,220*stats[i][1]/100.0,6),stats[i][2])
	card(Rect2(20,174,320,130),Color(0.03,0.1,0.10,0.78))
	text(Vector2(36,199),game.story.tracker_title(),17,GOLD)
	paragraph(Vector2(36,209),game.story.tracker_task(),286,14)
	text(Vector2(36,282),game.story.progress(),13,GOLD)
	if not game.blocked():
		var context: String=game.nearby_context()
		if not context.is_empty():
			card(Rect2(w/2-240,h-226,480,38))
			text(Vector2(w/2-222,h-201),("USE · " if mobile else "[E] ")+context,14,GOLD)
		if game.fishing_state!="":
			card(Rect2(w/2-215,h-178,430,55))
			text(Vector2(w/2-195,h-145),"A BITE!  REEL NOW" if game.fishing_state=="bite" else "FISHING / Watch the float...",20,GOLD)
			if game.fishing_state=="bite": draw_rect(Rect2(w/2-195,h-135,390*game.fishing_timer/2.8,4),GOLD)
		if game.notice_time>0:
			card(Rect2(355,85,w-380,74))
			paragraph(Vector2(371,97),game.notice,w-412,15)
		card(Rect2(16,h-72,810,60),Color(0.025,0.08,0.09,0.7))
		text(Vector2(24,h-24),l("FISH %d   COOKED %d   COCONUT %d   WOOD %d   /   %d VATU","ปลา %d   ปลาย่าง %d   มะพร้าว %d   ไม้ %d   /   %d วาตู") % [game.fish,game.cooked_fish,game.coconuts,game.wood,game.coins],13)
		if not mobile:
			var hint: String="W gas · S brake / reverse · A D steer · Space handbrake · E get out · M map · Esc pause" if game.driving else "WASD walk · Shift run · E interact / drive · F cast / cancel · Q eat · Tab pack · M map · Esc pause · F7 touch preview"
			if game.story.language=="th": hint="W เร่ง · S เบรก/ถอย · A D เลี้ยว · Space เบรกมือ · E ลงรถ · J ภารกิจ · L ภาษา" if game.driving else "WASD เดิน · Shift วิ่ง · E ใช้/ขับรถ · F ตกปลา · Q กิน · J ภารกิจ · M แผนที่ · L ภาษา"
			text(Vector2(24,h-48),hint,12)
		if game.driving:
			card(Rect2(w-170,h-92,150,72))
			text(Vector2(w-154,h-48),"%d" % int(absf(game.driving.speed)*3.6),34,GOLD)
			text(Vector2(w-88,h-48),"km/h",14)
			text(Vector2(w-154,h-30),"R" if game.driving.speed<-0.5 else "D",12)
	if game.panel=="map": draw_map()
	elif game.panel in ["journal","island"]: draw_journal()
	elif game.panel=="pack":
		card(Rect2(w/2-250,h/2-150,500,310))
		text(Vector2(w/2-220,h/2-105),"YOUR ISLAND PACK",24,GOLD)
		var rows := [l("Fresh fish: %d     Grilled fish: %d","ปลาสด: %d     ปลาย่าง: %d") % [game.fish,game.cooked_fish],l("Coconuts: %d     Driftwood: %d","มะพร้าว: %d     ไม้ลอยน้ำ: %d") % [game.coconuts,game.wood],l("Vatu: %d     Friendship: %d","วาตู: %d     มิตรภาพ: %d") % [game.coins,game.friendship],l("Cook fish at the beach fire with driftwood.","ย่างปลาที่กองไฟริมชายหาดโดยใช้ไม้เป็นเชื้อเพลิง"),l("Eat grilled fish or coconuts. Drink at the well.","กินปลาย่างหรือมะพร้าว และดื่มน้ำที่บ่อ"),l("F5 save · F9 load · Tab close","F5 บันทึก · F9 โหลด · Tab ปิด")]
		for i in range(rows.size()): text(Vector2(w/2-220,h/2-62+i*31),rows[i],16)
	elif game.panel=="talk":
		card(Rect2(w/2-320,h/2-200,640,395),Color(0.02,0.08,0.09,0.97))
		text(Vector2(w/2-290,h/2-163),game.active_villager+" / "+game.story.title(),21,GOLD)
		paragraph(Vector2(w/2-290,h/2-148),game.story.dialogue() if game.active_villager.begins_with("Malia") else l("Welcome, neighbour. Ask Malia about our shared meal.\nBefore exploring village land, greet your hosts and ask permission.\nYou can trade here, or explore the coast at your own pace.","ยินดีต้อนรับ ลองถามมาเลียเรื่องมื้ออาหารของหมู่บ้านนะ\nก่อนสำรวจพื้นที่ชุมชน ควรทักทายและขออนุญาตเจ้าบ้าน\nจะแวะแลกของที่นี่ หรือออกเดินเล่นเลียบชายฝั่งก็ได้"),580,17)
		text(Vector2(w/2-290,h/2+10),l("Your fish: %d  /  Your vatu: %d","ปลาที่มี: %d  /  เงิน: %d วาตู") % [game.fish,game.coins],15)
	if game.paused:
		draw_rect(Rect2(Vector2.ZERO,size),Color(0.01,0.04,0.04,0.4))
		card(Rect2(w/2-245,h/2-145,490,330))
		text(Vector2(w/2-100,h/2-88),"ISLAND AT REST",25,GOLD)
		text(Vector2(w/2-160,h/2-43),"Save your day, load, or return to the coast.",15)
	for key in buttons():
		if not mobile and not game.blocked() and not key in ["journal","language"]: continue
		var rect: Rect2=buttons()[key]
		card(rect,Color(0.05,0.17,0.17,0.85))
		var label: String={"pause":"II","map":"MAP","pack":"BAG","fish":"REEL" if game.fishing_state=="bite" else "FISH","use":"USE","eat":"EAT","jump":"JUMP","run":"WALK" if running else "RUN","save":"SAVE","load":"LOAD","resume":"RESUME","sell":"TRADE 3 FISH  →  45 VATU","meal":"BUY A MEAL  /  8 VATU","chat":"TALK ABOUT THE ISLAND","close":"CLOSE","journal":"JOURNAL","island":l("ISLAND NOTES","บันทึกเกาะ"),"story":"STORY","language":"TH / EN","mode":l("RELAXED" if game.story.relaxed else "SURVIVAL","เดินเล่นสบาย ๆ" if game.story.relaxed else "เอาชีวิตรอด")}.get(key,l("TRACK","นำทาง"))
		label=preload("res://scripts/island_locale.gd").translate(label,game.story.language)
		if key=="track_story": label=l("TRACK STORY","นำทางตามภารกิจ")
		text(rect.get_center()+Vector2(-font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x/2,5),label,14)
	if mobile and not game.blocked():
		var origin := stick_origin if not move_vector.is_zero_approx() else Vector2(112,h-130)
		draw_circle(origin,68,Color(0.02,0.08,0.09,0.4))
		draw_arc(origin,68,0,TAU,40,Color(0.9,0.96,0.9,0.5),2,true)
		draw_circle(origin+move_vector*48,26,Color(0.88,0.94,0.84,0.6))

func draw_journal() -> void:
	var c := size/2
	card(Rect2(c-Vector2(355,255),Vector2(710,510)),Color(0.02,0.08,0.09,0.97))
	text(c+Vector2(-330,-218),l("EFATE / COASTS & CONNECTIONS","เอฟาเต / สายใยริมฝั่งทะเล"),23,GOLD)
	if game.panel=="island":
		for i in range(game.story.PLACES.size()):
			var place: Dictionary=game.story.PLACES[i]
			var y: float=-132+i*77
			text(c+Vector2(-330,y),l(place.id,place.th)+(" ✓" if place.id in game.story.discovered else ""),18,GOLD)
			paragraph(c+Vector2(-330,y+8),l(place.en,place.fact_th),525,14)
	else:
		text(c+Vector2(-330,-128),game.story.title(),22,GOLD)
		paragraph(c+Vector2(-330,-112),game.story.dialogue(),655,16)
		paragraph(c+Vector2(-330,-12),game.story.task(),655,17,GOLD)
		text(c+Vector2(-330,61),game.story.progress(),16,GOLD)
		paragraph(c+Vector2(-330,83),l("Optional story · no time limit. Chapter rewards: fish +20 vatu; cooking +25; wood +30; homecoming +100.\nRelaxed mode pauses hunger and thirst. Switch modes anytime.","เนื้อเรื่องเป็นทางเลือก ไม่มีเวลาบังคับ รางวัล: ส่งปลา +20 วาตู ทำอาหาร +25 ส่งไม้ +30 กลับบ้าน +100\nโหมดเดินเล่นหยุดความหิวและกระหาย สลับโหมดได้ทุกเมื่อ"),650,14)
	paragraph(c+Vector2(-330,159),l("Real place notes: Vanuatu Tourism Office. Characters, storm and missions are fictional. The map is simplified at 1:20.","ข้อมูลสถานที่: สำนักงานการท่องเที่ยววานูอาตู ตัวละคร พายุ และภารกิจเป็นเรื่องแต่ง แผนที่ย่อส่วน 1:20"),655,12)
	text(c+Vector2(-330,231),l("J journal · L TH/EN · M map · F5 save","J ภารกิจ · L TH/EN · M แผนที่ · F5 บันทึก"),13)

func draw_map() -> void:
	var height := minf(size.y-150,550)
	var width := height
	var rect := Rect2((size-Vector2(width,height))/2,Vector2(width,height))
	card(Rect2(rect.position-Vector2(100,38),rect.size+Vector2(200,78)))
	draw_texture_rect(game.world.map_texture,rect,false)
	text(rect.position+Vector2(-75,-12),l("EFATE / NORTH ↑","เอฟาเต / ทิศเหนือ ↑"),21,GOLD)
	var p: Vector3=game.player.position
	draw_circle(rect.position+Vector2(p.x/2880+0.5,p.z/2880+0.5)*rect.size,5,WHITE)
	var goal: Vector3=game.story.target()
	var goal_point: Vector2=rect.position+Vector2(goal.x/2880+0.5,goal.z/2880+0.5)*rect.size
	draw_arc(goal_point,9,0,TAU,24,GOLD,3,true)
	text(goal_point+Vector2(10,-9),l("GOAL","จุดหมาย"),13,GOLD)
	for entry in game.world.geography.get("places",[]):
		if not entry.name in ["Port Vila","Mele","Eton","Emua","Mangaliliu","Port Havannah","Pango"]: continue
		var point: Vector2=rect.position+(Vector2(entry.position[0],entry.position[1])/Vector2(2880,2880)+Vector2.ONE*0.5)*rect.size
		draw_circle(point,3,GOLD)
		text(point+Vector2(7,0),entry.name,13)
	text(rect.position+Vector2(-75,height+24),"© OpenStreetMap contributors · ODbL · 1:20",11)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_F7:
		mobile=not mobile
		release_all()
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if mobile else Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		for key in buttons():
			if not mobile and not game.blocked() and not key in ["journal","language"]: continue
			if buttons()[key].has_point(event.position):
				activate(key,true)
				get_viewport().set_input_as_handled()
				return
	if event is InputEventScreenTouch:
		mobile=true
		if event.pressed:
			for key in buttons():
				if buttons()[key].has_point(event.position):
					fingers[event.index]=key
					activate(key,true)
					get_viewport().set_input_as_handled()
					return
			if game.blocked(): return
			if event.position.x<size.x*0.42 and not "move" in fingers.values():
				fingers[event.index]="move"
				stick_origin=event.position
				move_vector=Vector2.ZERO
			else: fingers[event.index]="look"
		else:
			var role: String=fingers.get(event.index,"")
			if role=="move": move_vector=Vector2.ZERO
			activate(role,false)
			fingers.erase(event.index)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and fingers.has(event.index):
		var role: String=fingers[event.index]
		if role=="move": move_vector=((event.position-stick_origin)/65).limit_length()
		elif role=="look" and not game.blocked():
			game.yaw-=event.relative.x*0.004
			game.pitch=clampf(game.pitch-event.relative.y*0.004,-0.95,0.65)
			game.look_timer=1.5
		get_viewport().set_input_as_handled()

func activate(key: String,pressed: bool) -> void:
	if not pressed:
		if key=="jump": Input.action_release("jump")
		return
	match key:
		"language": game.story.language="en" if game.story.language=="th" else "th"
		"journal", "island": game.panel="" if game.panel==key else key; release_all()
		"mode": game.story.relaxed=not game.story.relaxed
		"track_story": game.story.tracked_place=""; game.panel="map"
		"fish":
			if not game.blocked(): game.cast_line()
		"use":
			if not game.blocked(): game.interact()
		"eat":
			if not game.blocked(): game.eat()
		"jump":
			if not game.blocked(): Input.action_press("jump")
		"run": running=not running
		"pause", "resume": game.paused=not game.paused; game.panel=""; release_all()
		"map": game.panel="" if game.panel=="map" else "map"; release_all()
		"pack": game.panel="" if game.panel=="pack" else "pack"; release_all()
		"close": game.panel=""; release_all()
		"save": game.save_game()
		"load": game.load_game()
		"sell", "meal", "chat", "story": game.trade(key)
		_:
			if key.begins_with("place_"):
				var place: Dictionary=game.story.PLACES[int(key.trim_prefix("place_"))]
				game.story.tracked_place=place.id
				game.panel="map"
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if game.blocked() or mobile else Input.MOUSE_MODE_CAPTURED

func release_all() -> void:
	fingers.clear()
	move_vector=Vector2.ZERO
	running=false
	Input.action_release("jump")
