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

func _process(_dt: float) -> void:
	queue_redraw()

func text(at: Vector2,value: String,pixels := 16,color := WHITE) -> void:
	draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,color)

func card(rect: Rect2, color := INK) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color=color
	style.set_corner_radius_all(10)
	draw_style_box(style,rect)

func buttons() -> Dictionary:
	var w := size.x
	var h := size.y
	var values := {"pause":Rect2(w-70,20,50,46),"map":Rect2(w-138,20,58,46),"pack":Rect2(w-210,20,62,46)}
	if game.paused:
		values.merge({"save":Rect2(w/2-150,h/2+25,140,54),"load":Rect2(w/2+10,h/2+25,140,54),"resume":Rect2(w/2-100,h/2+100,200,54)})
	elif game.panel=="talk":
		values.merge({"sell":Rect2(w/2-210,h/2-10,420,50),"meal":Rect2(w/2-210,h/2+50,420,50),"chat":Rect2(w/2-210,h/2+110,260,50),"close":Rect2(w/2+65,h/2+110,145,50)})
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
	text(Vector2(36,70),"VANUATU   ·   DAY %02d   %02d:%02d" % [game.days,int(game.day_time),int(fmod(game.day_time,1)*60)],12,GOLD)
	var stats := [["HEALTH",game.health,Color("c98978")],["FOOD",game.food,Color("c8c391")],["WATER",game.thirst,Color("83c4cf")],["ENERGY",game.energy,Color("a6bf87")]]
	for i in range(stats.size()):
		text(Vector2(36,91+i*19),stats[i][0],10)
		draw_rect(Rect2(103,82+i*19,220,6),Color(0.4,0.5,0.4,0.4))
		draw_rect(Rect2(103,82+i*19,220*stats[i][1]/100.0,6),stats[i][2])
	card(Rect2(20,174,320,66),Color(0.03,0.1,0.10,0.68))
	text(Vector2(36,197),"A PLACE IN THE VILLAGE",13,GOLD)
	text(Vector2(36,220),"Catch & trade 3 fish  /  Delivered: %d" % game.delivered_fish,13)
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
			card(Rect2(355,85,w-380,48))
			text(Vector2(371,114),game.notice,12)
		card(Rect2(16,h-72,810,60),Color(0.025,0.08,0.09,0.7))
		text(Vector2(24,h-24),"FISH %d   COOKED %d   COCONUT %d   WOOD %d   /   %d VATU" % [game.fish,game.cooked_fish,game.coconuts,game.wood,game.coins],13)
		if not mobile:
			var hint: String="W gas · S brake / reverse · A D steer · Space handbrake · E get out · M map · Esc pause" if game.driving else "WASD walk · Shift run · E interact / drive · F cast / cancel · Q eat · Tab pack · M map · Esc pause · F7 touch preview"
			text(Vector2(24,h-48),hint,12)
		if game.driving:
			card(Rect2(w-170,h-92,150,72))
			text(Vector2(w-154,h-48),"%d" % int(absf(game.driving.speed)*3.6),34,GOLD)
			text(Vector2(w-88,h-48),"km/h",14)
			text(Vector2(w-154,h-30),"R" if game.driving.speed<-0.5 else "D",12)
	if game.panel=="map": draw_map()
	elif game.panel=="pack":
		card(Rect2(w/2-250,h/2-150,500,310))
		text(Vector2(w/2-220,h/2-105),"YOUR ISLAND PACK",24,GOLD)
		var rows := ["Fresh fish: %d     Grilled fish: %d" % [game.fish,game.cooked_fish],"Coconuts: %d     Driftwood: %d" % [game.coconuts,game.wood],"Vatu: %d     Friendship: %d" % [game.coins,game.friendship],"Cook fish at the beach fire with driftwood.","Eat grilled fish or coconuts. Drink at the well.","F5 save · F9 load · Tab close"]
		for i in range(rows.size()): text(Vector2(w/2-220,h/2-62+i*31),rows[i],16)
	elif game.panel=="talk":
		card(Rect2(w/2-245,h/2-155,490,340))
		text(Vector2(w/2-210,h/2-108),game.active_villager,23,GOLD)
		text(Vector2(w/2-210,h/2-73),"Welcome, neighbour. The village needs fresh fish.",16)
		text(Vector2(w/2-210,h/2-44),"Your fish: %d  /  Your vatu: %d" % [game.fish,game.coins],15)
	if game.paused:
		draw_rect(Rect2(Vector2.ZERO,size),Color(0.01,0.04,0.04,0.4))
		card(Rect2(w/2-245,h/2-145,490,330))
		text(Vector2(w/2-100,h/2-88),"ISLAND AT REST",25,GOLD)
		text(Vector2(w/2-160,h/2-43),"Save your day, load, or return to the coast.",15)
	for key in buttons():
		if not mobile and not game.blocked(): continue
		var rect: Rect2=buttons()[key]
		card(rect,Color(0.05,0.17,0.17,0.85))
		var label: String={"pause":"II","map":"MAP","pack":"BAG","fish":"REEL" if game.fishing_state=="bite" else "FISH","use":"USE","eat":"EAT","jump":"JUMP","run":"WALK" if running else "RUN","save":"SAVE","load":"LOAD","resume":"RESUME","sell":"TRADE 3 FISH  →  45 VATU","meal":"BUY A MEAL  /  8 VATU","chat":"TALK ABOUT THE ISLAND","close":"CLOSE"}[key]
		text(rect.get_center()+Vector2(-font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x/2,5),label,14)
	if mobile and not game.blocked():
		var origin := stick_origin if not move_vector.is_zero_approx() else Vector2(112,h-130)
		draw_circle(origin,68,Color(0.02,0.08,0.09,0.4))
		draw_arc(origin,68,0,TAU,40,Color(0.9,0.96,0.9,0.5),2,true)
		draw_circle(origin+move_vector*48,26,Color(0.88,0.94,0.84,0.6))

func draw_map() -> void:
	var height := minf(size.y-150,550)
	var width := height
	var rect := Rect2((size-Vector2(width,height))/2,Vector2(width,height))
	card(Rect2(rect.position-Vector2(100,38),rect.size+Vector2(200,78)))
	draw_texture_rect(game.world.map_texture,rect,false)
	text(rect.position+Vector2(-75,-12),"EFATE  /  NORTH ↑",21,GOLD)
	var p: Vector3=game.player.position
	draw_circle(rect.position+Vector2(p.x/2880+0.5,p.z/2880+0.5)*rect.size,5,WHITE)
	for entry in game.world.geography.get("places",[]):
		if not entry.name in ["Port Vila","Mele","Eton","Emua","Mangaliliu","Port Havannah","Pango"]: continue
		var point: Vector2=rect.position+(Vector2(entry.position[0],entry.position[1])/Vector2(2880,2880)+Vector2.ONE*0.5)*rect.size
		draw_circle(point,3,GOLD)
		text(point+Vector2(7,0),entry.name,13)
	text(rect.position+Vector2(-75,height+24),"© OpenStreetMap contributors · ODbL · compressed game scale",11)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_F7:
		mobile=not mobile
		release_all()
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if mobile else Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and game.blocked():
		for key in buttons():
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
		"sell", "meal", "chat": game.trade(key)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if game.blocked() or mobile else Input.MOUSE_MODE_CAPTURED

func release_all() -> void:
	fingers.clear()
	move_vector=Vector2.ZERO
	running=false
	Input.action_release("jump")
