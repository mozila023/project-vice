extends Control
## Resolution-independent landscape HUD and multitouch controls.
var game: Node3D
var mobile := OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
var move_vector := Vector2.ZERO
var firing := false
var aiming := false
var running := false
var fingers := {}
var stick_origin := Vector2.ZERO
var stick_tip := Vector2.ZERO
var font: Font
const WHITE := Color("edf5ef")
const GOLD := Color("f4d79a")
const INK := Color(0.025,0.075,0.085,0.78)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	font=ThemeDB.fallback_font
	get_tree().root.focus_exited.connect(release_all)

func _process(_dt: float) -> void:
	queue_redraw()

func text(at: Vector2, value: String, size_px := 16, color := WHITE) -> void:
	draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px,color)

func buttons() -> Dictionary:
	var w := size.x
	var h := size.y
	var values := {"pause":Rect2(w-72,22,50,44),"map":Rect2(w-138,22,54,44)}
	if game.paused:
		values["save"]=Rect2(w/2-145,h/2+30,130,54)
		values["load"]=Rect2(w/2+15,h/2+30,130,54)
		values["resume"]=Rect2(w/2-95,h/2+100,190,54)
	elif not game.blocked():
		values.merge({"fire":Rect2(w-132,h-183,94,94),"jump":Rect2(w-112,h-285,66,66),"aim":Rect2(w-236,h-120,66,66),"reload":Rect2(w-220,h-230,66,66),"use":Rect2(w-315,h-175,66,66),"run":Rect2(218,h-128,62,62)})
	return values

func _draw() -> void:
	if not is_instance_valid(game) or game.player==null: return
	var w := size.x
	var h := size.y
	draw_style_box(panel_style(),Rect2(22,22,310,105))
	text(Vector2(38,48),"EFATE / AFTERLIGHT",21)
	text(Vector2(38,72),"VANUATU  /  FIELD OPERATIONS",11,GOLD)
	text(Vector2(38,100),"HP %03d   ST %03d   FOOD %03d" % [game.health,game.stamina,game.food],15)
	text(Vector2(38,119),"CARBINE  %s / %d" % ["RELOAD" if game.reload_time>0 else str(game.ammo),game.reserve],13)
	text(Vector2(24,156),"SIGNAL RESTORED" if game.signal_restored else "RESTORE THE HILLTOP RADIO",15,GOLD)
	text(Vector2(24,179),"%d m  /  %d infected neutralized" % [Vector2(game.player.position.x,game.player.position.z).length(),game.kills],13)
	if not game.blocked():
		var c := size/2
		for offset in [Vector2(-8,0),Vector2(5,0),Vector2(0,-8),Vector2(0,5)]:
			draw_line(c+offset,c+offset+(Vector2(3,0) if offset.x!=0 else Vector2(0,3)),WHITE,1.5,true)
		for item in game.supplies:
			if item.position.distance_to(game.player.position)<4:
				text(Vector2(w/2-135,h-205 if mobile else h-80),"SUPPLIES NEARBY / "+("USE" if mobile else "[E] COLLECT"),16,GOLD)
				break
	if not mobile:
		text(Vector2(24,h-28),"WASD move   Shift sprint   Space jump   RMB aim   R reload   E search   M map   Esc pause   F7 touch preview",13)
	if game.panel=="map": draw_map()
	if game.panel=="pack":
		draw_style_box(panel_style(),Rect2(w/2-220,h/2-110,440,240))
		text(Vector2(w/2-185,h/2-60),"FIELD PACK",24,GOLD)
		text(Vector2(w/2-185,h/2-10),"Carbine: %d / %d rounds" % [game.ammo,game.reserve],20)
		text(Vector2(w/2-185,h/2+32),"Food: %d   /   TAB close" % game.food,18)
	if game.paused:
		draw_rect(Rect2(Vector2.ZERO,size),Color(0.01,0.035,0.04,0.48))
		draw_style_box(panel_style(),Rect2(w/2-220,h/2-110,440,290))
		text(Vector2(w/2-65,h/2-53),"PAUSED",28,GOLD)
		text(Vector2(w/2-145,h/2-15),"F5 Save   /   F9 Load   /   Esc Resume",15)
	if mobile or game.paused:
		for key in buttons():
			if not mobile and key in ["pause","map"]: continue
			var rect: Rect2=buttons()[key]
			var pressed: bool = (key=="fire" and firing) or (key=="aim" and aiming) or (key=="run" and running)
			draw_style_box(button_style(pressed),rect)
			var label: String={"pause":"II","map":"MAP","fire":"FIRE","jump":"JUMP","aim":"AIM","reload":"R","use":"USE","run":"RUN","save":"SAVE","load":"LOAD","resume":"RESUME"}[key]
			text(rect.get_center()+Vector2(-font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x/2,5),label,15)
		if not game.blocked() and mobile:
			var origin := stick_origin if not move_vector.is_zero_approx() else Vector2(115,h-125)
			draw_circle(origin,69,Color(0.02,0.07,0.08,0.38))
			draw_arc(origin,69,0,TAU,48,Color(0.85,0.95,0.91,0.55),2,true)
			draw_circle(origin+move_vector*48,25,Color(0.82,0.92,0.87,0.55))
			text(Vector2(w/2-80,h-25),"DRAG RIGHT TO LOOK",12)

func panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color=INK
	s.corner_radius_top_left=8
	s.corner_radius_bottom_right=8
	return s

func button_style(active: bool) -> StyleBoxFlat:
	var s := panel_style()
	s.bg_color=Color(0.26,0.50,0.45,0.8) if active else Color(0.03,0.10,0.12,0.5)
	s.set_corner_radius_all(24)
	s.set_border_width_all(1)
	s.border_color=Color(0.8,0.94,0.9,0.48)
	return s

func draw_map() -> void:
	var height := minf(size.y-100,600)
	var width := height*2400/2800
	var rect := Rect2((size-Vector2(width,height))/2,Vector2(width,height))
	draw_rect(Rect2(rect.position-Vector2(18,34),rect.size+Vector2(36,68)),INK)
	draw_texture_rect(game.world.map_texture,rect,false)
	text(rect.position+Vector2(0,-10),"EFATE / N ↑",18,GOLD)
	var p: Vector3=game.player.position
	var marker := rect.position+Vector2(p.x/2400+0.5,p.z/2800+0.5)*rect.size
	draw_circle(marker,5,WHITE)
	draw_circle(rect.position+rect.size*0.5,5,GOLD)
	text(rect.position+Vector2(0,height+22),"WHITE: YOU   GOLD: RADIO   /   M or MAP close",12)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode==KEY_F7:
		mobile=not mobile
		release_all()
		Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if mobile else Input.MOUSE_MODE_CAPTURED
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
		get_viewport().set_input_as_handled()

func activate(key: String, pressed: bool) -> void:
	match key:
		"fire": firing=pressed
		"aim": aiming=pressed
		"jump":
			if pressed and not game.blocked(): Input.action_press("jump")
			else: Input.action_release("jump")
		"run":
			if pressed: running=not running
		"reload":
			if pressed and game.ammo<30 and game.reserve>0 and game.reload_time<=0: game.reload_time=2.1
		"use":
			if pressed: game.collect()
		"pause", "resume":
			if pressed:
				game.paused=not game.paused
				game.panel=""
				release_all()
		"map":
			if pressed:
				game.panel="" if game.panel=="map" else "map"
				release_all()
		"save":
			if pressed: game.save_game()
		"load":
			if pressed: game.load_game()

func release_all() -> void:
	fingers.clear()
	move_vector=Vector2.ZERO
	firing=false
	aiming=false
	running=false
	Input.action_release("jump")
