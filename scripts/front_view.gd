extends Control
const AERIAL := preload("res://assets/menu/efate_aerial.png")
var front: Node3D
var font: Font=preload("res://assets/fonts/NotoSansThai.ttf")
var actions: Control
var last_screen := ""
var last_language := ""
var settings: Control
var shade: GradientTexture2D
const GOLD := Color("dbbd7d")
const PAPER := Color("e9e5d9")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme=preload("res://scripts/ui_style.gd").theme()
	font.fallbacks=[ThemeDB.fallback_font]
	shade=GradientTexture2D.new()
	shade.gradient=Gradient.new()
	shade.gradient.set_color(0,Color(0.025,0.06,0.075,0.98))
	shade.gradient.set_color(1,Color(0.025,0.06,0.075,0.0))
	shade.width=512
	rebuild()

func button(label: String,at: Vector2,width: float,callback: Callable,primary := false) -> Button:
	var result := Button.new()
	result.text=label
	result.position=at
	result.size=Vector2(width,56)
	if primary:
		result.add_theme_stylebox_override("normal",preload("res://scripts/ui_style.gd").panel(GOLD,7))
		result.add_theme_color_override("font_color",Color("14272e"))
	actions.add_child(result)
	result.pressed.connect(callback)
	return result

func rebuild() -> void:
	last_screen=front.screen
	last_language=Preferences.language
	if is_instance_valid(actions):
		remove_child(actions)
		actions.queue_free()
	actions=Control.new()
	actions.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	actions.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(actions)
	match front.screen:
		"menu":
			var y: float=size.y*0.54
			button(Preferences.l("NEW GAME","เริ่มเกมใหม่"),Vector2(64,y),310,front.start_new_game,true)
			if FileAccess.file_exists("user://efate_life_save.json"):
				button(Preferences.l("CONTINUE","เล่นต่อจากบันทึก"),Vector2(64,y+68),310,front.continue_game)
				y+=68
			button(Preferences.l("SETTINGS","ตั้งค่า"),Vector2(64,y+68),310,func(): front.screen="settings")
		"settings":
			settings=preload("res://scripts/settings_panel.gd").new()
			actions.add_child(settings)
			settings.closed.connect(func(): front.screen="menu")
func text(at: Vector2,value: String,pixels := 18,color := PAPER) -> void:
	draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,pixels,color)

func paragraph(at: Vector2,value: String,width: float,pixels := 20,color := PAPER) -> void:
	var layout := TextParagraph.new()
	layout.width=width
	layout.add_string(value,font,pixels)
	layout.draw(get_canvas_item(),at,color)

func _process(_dt: float) -> void:
	if last_screen!=front.screen or (last_language!=Preferences.language and front.screen!="settings"): rebuild()
	queue_redraw()

func _notification(what: int) -> void:
	if what==NOTIFICATION_RESIZED and is_instance_valid(front) and is_node_ready(): rebuild()

func _draw() -> void:
	if not is_instance_valid(front): return
	var w := size.x
	var h := size.y
	var scale_factor: float=maxf(w/AERIAL.get_width(),h/AERIAL.get_height())*(1.035+sin(front.clock*.035)*.015)
	var image_size: Vector2=AERIAL.get_size()*scale_factor
	draw_texture_rect(AERIAL,Rect2((size-image_size)/2,image_size),false)
	if front.screen=="menu":
		draw_texture_rect(shade,Rect2(0,0,w*0.85,h),false)
		text(Vector2(64,h*0.19),"AN EFATE ISLAND STORY",14,GOLD)
		text(Vector2(59,h*0.31),"VANUATU",62)
		text(Vector2(58,h*0.44),"VICE",90)
		paragraph(Vector2(66,h*0.46),Preferences.l("A new coast. A slower life. Your own way home.","ฝั่งทะเลใหม่ ชีวิตที่ช้าลง และเส้นทางกลับบ้านของคุณ"),540,17,Color("becbc8"))
		text(Vector2(64,h-48),Preferences.l("EXPLORE · CONNECT · BELONG","สำรวจ · พบผู้คน · ค้นพบบ้าน"),13,GOLD)
		text(Vector2(w-335,h-32),"EFATE / SOUTH PACIFIC",12)
	elif front.screen=="settings":
		draw_rect(Rect2(Vector2.ZERO,size),Color(0.02,0.05,0.065,0.7))
	elif front.screen=="loading":
		draw_rect(Rect2(Vector2.ZERO,size),Color("101e25"))
		text(Vector2(w/2-135,h/2),Preferences.l("ARRIVING IN EFATE…","กำลังเดินทางถึงเอฟาเต…"),25,GOLD)
		text(Vector2(w/2-180,h/2+42),Preferences.l("Preparing your first morning on the island.","เตรียมเช้าวันแรกของคุณบนเกาะ"),16)
