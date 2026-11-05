extends Control
var game: Node3D
var mobile := OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
var move_vector := Vector2.ZERO
var running := false
var sleep_effect := 0.0
var fingers := {}
var stick_origin := Vector2.ZERO
var font: Font
var icons := {}
var settings_view: Control
var styles := {}
var smoothed_health := 100.0
var mini_map: Control
const BAR_FILL := preload("res://assets/ui/bar_fill.png")
const BAR_FRAME := preload("res://assets/ui/bar_border.png")
const WHITE := Color("eef4e8")
const GOLD := Color("f5d6a2")
const INK := Color(0.02,0.08,0.09,0.80)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	font=ThemeDB.fallback_font
	font=preload("res://assets/fonts/NotoSansThai.ttf")
	font.fallbacks=[ThemeDB.fallback_font]
	for key in ["heart-pulse","droplets","utensils","zap","compass","map-pin","plane","book-open","settings-2","backpack"]:
		icons[key]=load("res://assets/ui/icons/"+key+".svg")
	mini_map=preload("res://scripts/mini_map.gd").new()
	mini_map.game=game
	add_child(mini_map)

func _process(_dt: float) -> void:
	sleep_effect=maxf(0,sleep_effect-_dt/1.5)
	smoothed_health=lerpf(smoothed_health,game.health,clampf(_dt*7,0,1))
	if game.panel=="settings" and not is_instance_valid(settings_view):
		settings_view=preload("res://scripts/settings_panel.gd").new()
		add_child(settings_view)
		settings_view.changed.connect(game.apply_preferences)
		settings_view.closed.connect(func(): game.panel=""; settings_view.queue_free(); Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if mobile else Input.MOUSE_MODE_CAPTURED)
	elif game.panel!="settings" and is_instance_valid(settings_view): settings_view.queue_free()
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
	var key := color.to_html()
	if not styles.has(key): styles[key]=preload("res://scripts/ui_style.gd").panel(color)
	var style: StyleBoxFlat=styles[key]
	draw_style_box(style,rect)

func icon(key: String,at: Vector2,scale := 22.0,color := WHITE) -> void:
	if icons.has(key): draw_texture_rect(icons[key],Rect2(at,Vector2.ONE*scale),false,color)

func meter(rect: Rect2,value: float,color: Color) -> void:
	draw_texture_rect(BAR_FRAME,rect,false,Color(0.5,0.64,0.66,0.45))
	var inside := rect.grow(-3)
	inside.size.x=maxf(0,inside.size.x*clampf(value/100,0,1))
	if inside.size.x>0: draw_texture_rect(BAR_FILL,inside,false,color)

func buttons() -> Dictionary:
	var w := size.x
	var h := size.y
	var values := {"pause":Rect2(w-70,20,50,46),"pack":Rect2(w-178,20,100,46)}
	if not game.blocked(): values["minimap"]=Rect2(24,236 if mobile else 108,196,224)
	if game.paused:
		values.merge({"save":Rect2(w/2-150,h/2+5,140,48),"load":Rect2(w/2+10,h/2+5,140,48),"settings":Rect2(w/2-150,h/2+65,140,48),"main_menu":Rect2(w/2+10,h/2+65,140,48),"resume":Rect2(w/2-150,h/2+125,300,48)})
	elif game.panel=="talk":
		if game.active_villager=="Luna":
			values.merge({"story":Rect2(w/2-290,h/2+65,580,48),"close":Rect2(w/2+105,h/2+132,185,45)})
		else:
			values.merge({"sell":Rect2(w/2-290,h/2+80,282,45),"meal":Rect2(w/2+8,h/2+80,282,45),"chat":Rect2(w/2-290,h/2+132,380,45),"close":Rect2(w/2+105,h/2+132,185,45)})
	elif game.panel=="restaurant":
		values.merge({"restaurant_meal":Rect2(w/2-290,h/2+12,580,45),"ingredient_fish":Rect2(w/2-290,h/2+72,180,45),"ingredient_coconuts":Rect2(w/2-100,h/2+72,200,45),"ingredient_wood":Rect2(w/2+110,h/2+72,180,45),"close":Rect2(w/2+105,h/2+132,185,45)})
	elif game.panel=="hotel":
		values.merge({"sleep":Rect2(w/2-290,h/2+65,580,48),"close":Rect2(w/2+105,h/2+132,185,45)})
	elif game.panel in ["pack","journal","island","map"]:
		values={"pack":Rect2(w/2-330,h/2-200,150,40),"journal":Rect2(w/2-170,h/2-200,150,40),"island":Rect2(w/2-10,h/2-200,170,40),"map":Rect2(w/2+170,h/2-200,160,40),"close":Rect2(w/2+220,h/2+205,110,40)}
		if game.panel=="journal": values.merge({"mode":Rect2(w/2-330,h/2+205,230,40),"track_story":Rect2(w/2-90,h/2+205,295,40)})
		if game.panel=="island":
			for i in range(game.story.PLACES.size()): values["place_"+str(i)]=Rect2(w/2+220,h/2-137+i*42,108,36)
	elif game.panel=="settings": return {}
	elif game.panel!="": values["close"]=Rect2(w/2-70,h-85,140,48)
	elif mobile:
		if game.driving: values.merge({"use":Rect2(w-138,h-180,96,70),"jump":Rect2(w-246,h-180,96,70)})
		else: values.merge({"fish":Rect2(w-138,h-180,96,96),"use":Rect2(w-246,h-140,82,82),"eat":Rect2(w-125,h-285,66,66),"jump":Rect2(w-235,h-240,66,66),"run":Rect2(215,h-120,64,64)})
	return values

func _draw() -> void:
	if not is_instance_valid(game) or game.player==null: return
	var w := size.x
	var h := size.y
	if not game.blocked():
		card(Rect2(24,24,260,64),Color(0.035,0.07,0.09,0.86))
		icon("map-pin",Vector2(39,40),20,GOLD)
		text(Vector2(71,49),"EFATE / VANUATU",16)
		text(Vector2(71,70),l("DAY %02d  ·  %02d:%02d","วันที่ %02d  ·  %02d:%02d") % [game.days,int(game.day_time),int(fmod(game.day_time,1)*60)]+" · "+game.time_period(),12,GOLD)
		var vitals_y: float=108 if mobile else h-194
		card(Rect2(24,vitals_y,354,112),Color(0.035,0.07,0.09,0.9))
		icon("heart-pulse",Vector2(40,vitals_y+16),25,Color("e29689"))
		text(Vector2(78,vitals_y+36),l("HEALTH","สุขภาพ"),13)
		text(Vector2(322,vitals_y+36),str(int(game.health)),15,Color("e29689"))
		meter(Rect2(78,vitals_y+46,278,14),smoothed_health,Color("c96e61"))
		var stats := [["utensils",game.food,Color("d8bf82")],["droplets",game.thirst,Color("79bfc8")],["zap",game.energy,Color("a6bc91")]]
		for i in range(3):
			var x: float=40+i*110
			icon(stats[i][0],Vector2(x,vitals_y+75),18,stats[i][2])
			meter(Rect2(x+26,vitals_y+79,65,11),stats[i][1],stats[i][2])

		draw_navigation()
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
			var notice_y: float=270 if mobile else 98
			card(Rect2(300,notice_y,w-652,70),Color(0.035,0.07,0.09,0.88))
			paragraph(Vector2(318,notice_y+12),game.notice,w-690,14)
		card(Rect2(24,h-66,810,44),Color(0.025,0.06,0.08,0.88))
		text(Vector2(40,h-38),l("FISH %d   COOKED %d   COCONUT %d   WOOD %d   /   %d VATU","ปลา %d   ปลาย่าง %d   มะพร้าว %d   ไม้ %d   /   %d วาตู") % [game.fish,game.cooked_fish,game.coconuts,game.wood,game.coins],13)
		if not mobile:
			var hint: String="W gas · S brake / reverse · A D steer · Space handbrake · E get out · M map · Esc pause" if game.driving else "WASD walk · Shift run · E interact / drive · F cast / cancel · Q eat · Tab pack · M map · Esc pause · F7 touch preview"
			if game.story.language=="th": hint="W เร่ง · S เบรก/ถอย · A D เลี้ยว · Space เบรกมือ · E ลงรถ · Tab กระเป๋า / เมนู" if game.driving else "WASD เดิน · Shift วิ่ง · E ใช้/ขับรถ · F ตกปลา · Q กิน · Tab กระเป๋า / เมนู · M แผนที่"
			text(Vector2(32,h-76),hint,11,Color("b4c2be"))
		if game.driving:
			card(Rect2(w-170,h-92,150,72))
			text(Vector2(w-154,h-48),"%d" % int(absf(game.driving.speed)*3.6),34,GOLD)
			text(Vector2(w-88,h-48),"km/h",14)
			text(Vector2(w-154,h-30),"R" if game.driving.speed<-0.5 else "D",12)
	if game.panel in ["pack","journal","island","map"]: draw_pack_frame()
	if game.panel=="map": draw_map()
	elif game.panel in ["journal","island"]: draw_journal()
	elif game.panel=="pack":
		var c := size/2
		var items := [[l("Fresh fish","ปลาสด"),game.fish],[l("Grilled fish","ปลาย่าง"),game.cooked_fish],[l("Coconuts","มะพร้าว"),game.coconuts],[l("Driftwood","ไม้ลอยน้ำ"),game.wood],[l("Vatu","เงินวาตู"),game.coins],[l("Friendship","มิตรภาพ"),game.friendship]]
		for i in range(items.size()):
			var at := c+Vector2(-330+(i%2)*340,-135+(i/2)*85)
			card(Rect2(at,Vector2(320,72)),Color(0.06,0.16,0.17,0.9))
			text(at+Vector2(16,28),items[i][0],16)
			text(at+Vector2(16,55),str(items[i][1]),21,GOLD)
		paragraph(c+Vector2(-330,143),l("Cook fish at the beach fire with driftwood. Eat fish or coconuts; drink at a well.","ย่างปลาที่กองไฟโดยใช้ไม้ กินปลาย่างหรือมะพร้าว และดื่มน้ำจากบ่อ"),650,14)
	elif game.panel=="talk":
		card(Rect2(w/2-320,h/2-200,640,395),Color(0.02,0.08,0.09,0.97))
		text(Vector2(w/2-290,h/2-163),game.active_villager+" / "+(game.story.title() if game.active_villager=="Luna" else l("Neighbour","เพื่อนบ้าน")),21,GOLD)
		paragraph(Vector2(w/2-290,h/2-148),game.story.dialogue() if game.active_villager=="Luna" else l("Welcome, neighbour. Pad Thai buys ingredients and serves meals.\nSeaside Inn has a room when you need to rest.\nFish along the coast, explore and enjoy island life.","ยินดีต้อนรับเพื่อนบ้าน Pad Thai รับซื้อวัตถุดิบและมีข้าวให้กิน\nถ้าเหนื่อยก็แวะพักที่โรงแรม Seaside Inn ได้\nตกปลาริมชายฝั่ง ออกสำรวจ และใช้ชีวิตบนเกาะได้ตามใจนะ"),580,17)
		text(Vector2(w/2-290,h/2+10),l("Your fish: %d  /  Your vatu: %d","ปลาที่มี: %d  /  เงิน: %d วาตู") % [game.fish,game.coins],15)
	elif game.panel in ["restaurant","hotel"]:
		card(Rect2(w/2-320,h/2-200,640,395),Color(0.02,0.08,0.09,0.97))
		text(Vector2(w/2-290,h/2-163),"PAD THAI @ELLUK" if game.panel=="restaurant" else "SEASIDE INN",23,GOLD)
		var description: String=l("Meals restore hunger and thirst. Sell ingredients one at a time.\nFresh fish: 15 vatu · Coconut: 5 · Driftwood: 4\nYour stock: %d fish · %d coconuts · %d driftwood", "กินข้าวเติมความหิวและกระหาย ขายวัตถุดิบได้ครั้งละหนึ่งชิ้น\nปลาสด 15 วาตู · มะพร้าว 5 · ไม้ลอยน้ำ 4\nของที่มี: ปลา %d · มะพร้าว %d · ไม้ %d") % [game.fish,game.coconuts,game.wood] if game.panel=="restaurant" else l("Rest in your room until the next 08:00 for 10 vatu.\nEnergy and Stamina fully recover; health improves.\nA full day on the island takes one real hour.","พักในห้องถึงเช้าเวลา 08:00 ค่าห้อง 10 วาตู\nฟื้น Energy และ Stamina เต็ม พร้อมฟื้นฟูสุขภาพ\nหนึ่งวันบนเกาะเท่ากับหนึ่งชั่วโมงจริง")
		paragraph(Vector2(w/2-290,h/2-125),description,580,17)
		text(Vector2(w/2-290,h/2-20),l("Your vatu: %d","เงินที่มี: %d วาตู") % game.coins,17,GOLD)
	if game.paused:
		draw_rect(Rect2(Vector2.ZERO,size),Color(0.01,0.04,0.04,0.4))
		card(Rect2(w/2-245,h/2-145,490,350))
		text(Vector2(w/2-100,h/2-88),"ISLAND AT REST",25,GOLD)
		text(Vector2(w/2-160,h/2-43),"Save your day, load, or return to the coast.",15)
	for key in buttons():
		if key=="minimap": continue
		if not mobile and not game.blocked() and not key in ["pack","pause"]: continue
		var rect: Rect2=buttons()[key]
		card(rect,Color(0.16,0.27,0.25,0.98) if key==game.panel else Color(0.05,0.17,0.17,0.85))
		var label: String={"pause":"II","map":"MAP","pack":"BAG","fish":"REEL" if game.fishing_state=="bite" else "FISH","use":"USE","eat":"EAT","jump":"JUMP","run":"WALK" if running else "RUN","save":"SAVE","load":"LOAD","resume":"RESUME","sell":"TRADE 3 FISH  →  45 VATU","meal":"BUY A MEAL  /  8 VATU","chat":"TALK ABOUT THE ISLAND","close":"CLOSE","journal":"JOURNAL","island":l("ISLAND NOTES","บันทึกเกาะ"),"story":"STORY","mode":l("RELAXED" if game.story.relaxed else "SURVIVAL","เดินเล่นสบาย ๆ" if game.story.relaxed else "เอาชีวิตรอด")}.get(key,l("TRACK","นำทาง"))
		label=preload("res://scripts/island_locale.gd").translate(label,game.story.language)
		if key=="track_story": label=l("TRACK STORY","นำทางตามภารกิจ")
		if key=="story" and game.active_villager=="Luna": label=game.story.action_text()
		if key=="restaurant_meal": label=l("EAT A MEAL · 8 VATU","กินข้าว · 8 วาตู")
		if key=="ingredient_fish": label=l("SELL FISH · 15","ขายปลา · 15")
		if key=="ingredient_coconuts": label=l("SELL COCONUT · 5","ขายมะพร้าว · 5")
		if key=="ingredient_wood": label=l("SELL WOOD · 4","ขายไม้ · 4")
		if key=="sleep": label=l("SLEEP UNTIL 08:00 · 10 VATU","นอนถึง 08:00 · 10 วาตู")
		if key=="settings": label=l("SETTINGS","ตั้งค่า")
		if key=="main_menu": label=l("MAIN MENU","เมนูหลัก")
		if game.driving and key=="jump": label=l("BRAKE","เบรกมือ")
		if game.driving and key=="use": label=l("EXIT","ลงรถ")
		text(rect.get_center()+Vector2(-font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x/2,5),label,14)
	if mobile and not game.blocked():
		var origin := stick_origin if not move_vector.is_zero_approx() else Vector2(112,h-130)
		draw_circle(origin,68,Color(0.02,0.08,0.09,0.4))
		draw_arc(origin,68,0,TAU,40,Color(0.9,0.96,0.9,0.5),2,true)
		draw_circle(origin+move_vector*48,26,Color(0.88,0.94,0.84,0.6))

	if sleep_effect>0:
		draw_rect(Rect2(Vector2.ZERO,size),Color(0.015,0.025,0.04,sleep_effect))
		text(size/2+Vector2(-120,0),l("08:00 · A NEW MORNING","08:00 · เช้าวันใหม่"),23,Color(1,1,1,sleep_effect))

func draw_pack_frame() -> void:
	var c := size/2
	card(Rect2(c-Vector2(355,255),Vector2(710,510)),Color(0.02,0.08,0.09,0.97))
	icon("backpack",c+Vector2(-330,-240),22,GOLD)
	text(c+Vector2(-296,-218),l("YOUR ISLAND PACK","กระเป๋าและบันทึกการเดินทาง"),22,GOLD)
	text(c+Vector2(-330,231),l("Tab close · F5 save","Tab ปิด · F5 บันทึก"),13)

func draw_journal() -> void:
	var c := size/2

	if game.panel=="island":
		for i in range(game.story.PLACES.size()):
			var place: Dictionary=game.story.PLACES[i]
			var y: float=-146+i*42
			text(c+Vector2(-330,y),l(place.id,place.th)+(" ✓" if place.id in game.story.discovered else ""),18,GOLD)
			var note: String=l(place.en,place.fact_th)
			while font.get_string_size(note,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x>510: note=note.left(note.length()-2).strip_edges()+"…"
			text(c+Vector2(-330,y+24),note,12)
	else:
		text(c+Vector2(-330,-128),game.story.title(),22,GOLD)
		paragraph(c+Vector2(-330,-112),game.story.dialogue(),655,16)
		paragraph(c+Vector2(-330,-12),game.story.task(),655,17,GOLD)
		text(c+Vector2(-330,61),game.story.progress(),16,GOLD)
		paragraph(c+Vector2(-330,83),l("Luna's welcome tour: Sunshine → Pad Thai → Seaside Inn.\nMeals: 8 vatu · Rooms: 10 vatu · Full game day: 1 real hour.","ทัวร์กับ Luna: Sunshine → Pad Thai → Seaside Inn\nข้าว 8 วาตู · ห้องพัก 10 วาตู · หนึ่งวันเกมเท่ากับหนึ่งชั่วโมงจริง"),650,14)
	paragraph(c+Vector2(-330,159),l("Luna and Seaside Inn are fictional. Sunshine and Pad Thai follow supplied location references. Map scale: 1:20.","Luna และ Seaside Inn เป็นส่วนสมมติ Sunshine และ Pad Thai อ้างอิงสถานที่ที่ให้มา แผนที่ย่อส่วน 1:20"),655,12)


func draw_navigation() -> void:
	var center := Vector2(size.x/2,47)
	card(Rect2(center-Vector2(173,23),Vector2(346,46)),Color(0.035,0.07,0.09,0.84))
	var heading: float=fposmod(-game.yaw,TAU)
	for i in range(8):
		var angle: float=wrapf(i*TAU/8-heading,-PI,PI)
		if absf(angle)>1.2: continue
		var x: float=center.x+angle*125
		draw_line(Vector2(x,center.y-11),Vector2(x,center.y-5),Color("7e979d"),1)
		text(Vector2(x-8,center.y+14),["N","NE","E","SE","S","SW","W","NW"][i],11,GOLD if i%2==0 else WHITE)
	draw_colored_polygon(PackedVector2Array([center+Vector2(-4,-22),center+Vector2(4,-22),center+Vector2(0,-15)]),GOLD)
	if not game.navigation.active(): return
	var angle: float=wrapf(-game.navigation.bearing()-heading,-PI,PI)
	var compass_x: float=center.x+clampf(angle,-1.2,1.2)*125
	draw_circle(Vector2(compass_x,center.y-1),3,GOLD)
	# Fixed guidance stays readable when the camera moves behind buildings.
	var at := Vector2(236,350) if mobile else Vector2(24,344)
	card(Rect2(at,Vector2(196,84)),Color(0.035,0.07,0.09,0.93))
	var relative: float=wrapf(game.navigation.bearing()-game.yaw,-PI,PI)
	var direction := Vector2(-sin(relative),-cos(relative))
	var normal := Vector2(-direction.y,direction.x)
	var arrow := at+Vector2(25,27)
	if game.navigation.arrived:
		icon("map-pin",arrow-Vector2(11,11),22,GOLD)
	else:
		draw_colored_polygon(PackedVector2Array([arrow+direction*12,arrow-direction*8+normal*7,arrow-direction*5,arrow-direction*8-normal*7]),GOLD)
	text(at+Vector2(48,24),l("Arrived","ถึงจุดหมาย") if game.navigation.arrived else str(int(game.navigation.distance()))+l(" m"," ม."),17,GOLD)
	text(at+Vector2(48,43),l("Follow road","ตามถนน") if game.navigation.road_route else l("Head to destination","มุ่งหน้าสู่จุดหมาย"),11)
	var title: String=game.story.tracker_title()
	text(at+Vector2(12,70),title.left(24)+("…" if title.length()>24 else ""),12)

func draw_map() -> void:
	var height := minf(size.y-330,340)
	var width := height
	var rect := Rect2((size-Vector2(width,height))/2+Vector2(0,12),Vector2(width,height))

	draw_texture_rect(game.world.map_texture,rect,false)
	if game.navigation.active() and game.navigation.route.size()>1:
		var route := PackedVector2Array()
		for at: Vector3 in game.navigation.route:
			route.append(rect.position+Vector2(at.x/2880+0.5,at.z/2880+0.5)*rect.size)
		draw_polyline(route,Color("dbbd7d"),3,true)
	var p: Vector3=game.player.position
	var restaurant: Vector2=preload("res://scripts/elluk_restaurant.gd").SITE
	var restaurant_point: Vector2=rect.position+(restaurant/2880.0+Vector2.ONE*0.5)*rect.size
	draw_circle(restaurant_point,4,GOLD)
	text(restaurant_point+Vector2(8,36),"PAD THAI @ELLUK",12,GOLD)
	var inn: Vector2=rect.position+(game.hotel.SITE/2880.0+Vector2.ONE*.5)*rect.size
	draw_rect(Rect2(inn-Vector2.ONE*3,Vector2.ONE*6),Color("b9e4dc"))
	if game.story.tracked_place=="Seaside Inn": text(inn+Vector2(7,-15),"Seaside Inn",12,GOLD)
	var spa: Vector2=preload("res://scripts/sunshine_spa.gd").SITE
	var spa_point: Vector2=rect.position+(spa/2880.0+Vector2.ONE*0.5)*rect.size
	draw_rect(Rect2(spa_point-Vector2.ONE*3,Vector2.ONE*6),Color("9ad1bc"))
	text(spa_point+Vector2(8,20),"Sunshine Wellness & Spa",12,Color("9ad1bc"))
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
	text(rect.position+Vector2(-140,height+18),"© OpenStreetMap contributors · ODbL · 1:20",11)

func _input(event: InputEvent) -> void:
	if game.panel=="settings": return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_F7:
		mobile=not mobile
		release_all()
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if mobile else Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		for key in buttons():
			if not mobile and not game.blocked() and not key in ["pack","pause","minimap"]: continue
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
			game.yaw-=event.relative.x*0.004*Preferences.sensitivity
			game.pitch=clampf(game.pitch-event.relative.y*0.004*Preferences.sensitivity,-0.95,0.65)
			game.look_timer=1.5
		get_viewport().set_input_as_handled()

func activate(key: String,pressed: bool) -> void:
	if not pressed:
		if key=="jump": Input.action_release("jump")
		return
	if is_instance_valid(game.audio) and not key in ["fish","use","eat","jump"]:
		game.audio.play_sfx("ui_click",1.04,-5.5)
	match key:
		"journal", "island": game.panel=key; release_all()
		"mode": game.story.relaxed=not game.story.relaxed; Preferences.relaxed=game.story.relaxed; Preferences.save()
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
		"settings": game.paused=false; game.panel="settings"; release_all()
		"main_menu":
			release_all()
			get_tree().change_scene_to_file("res://scenes/front_end.tscn")
		"map", "minimap": game.panel="map"; release_all()
		"pack": game.panel="pack"; release_all()
		"close": game.panel=""; release_all()
		"save": game.save_game()
		"load": game.load_game()
		"sell", "meal", "chat", "story": game.trade(key)
		"restaurant_meal", "ingredient_fish", "ingredient_coconuts", "ingredient_wood", "sleep": game.service(key)
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
