extends Control
signal closed
signal changed
var return_label := ""
var content: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build()

func label_at(value: String,at: Vector2,width := 250) -> Label:
	var label := Label.new()
	label.text=value
	label.position=at
	label.size=Vector2(width,36)
	content.add_child(label)
	return label

func build() -> void:
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	theme=preload("res://scripts/ui_style.gd").theme()
	content=Panel.new()
	content.add_theme_stylebox_override("panel",preload("res://scripts/ui_style.gd").panel(Color("101e25"),16))
	content.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	content.position=Vector2(-330,-264)
	content.size=Vector2(660,528)
	add_child(content)
	label_at(Preferences.l("SETTINGS","ตั้งค่า"),Vector2(32,24)).add_theme_font_size_override("font_size",28)
	label_at(Preferences.l("Make the island feel right for you.","ปรับเกาะนี้ให้เป็นจังหวะของคุณ"),Vector2(32,65),590).add_theme_color_override("font_color",Color("91a7ac"))
	var language := OptionButton.new()
	language.add_item("ไทย / TH")
	language.add_item("English / EN")
	language.select(1 if Preferences.language=="en" else 0)
	row(Preferences.l("Language","ภาษา"),language,120)
	language.item_selected.connect(func(i): Preferences.language="en" if i==1 else "th"; commit(); build())
	var quality := OptionButton.new()
	for name in [Preferences.l("Auto / recommended","อัตโนมัติ / แนะนำ"),Preferences.l("Low / mobile","ต่ำ / มือถือ"),Preferences.l("Balanced","สมดุล"),Preferences.l("High","สูง")]: quality.add_item(name)
	quality.select(Preferences.quality+1)
	row(Preferences.l("Graphics","คุณภาพภาพ"),quality,174)
	quality.item_selected.connect(func(i): Preferences.quality=i-1; commit())
	var volume := HSlider.new()
	volume.min_value=0
	volume.max_value=100
	volume.step=5
	volume.value=Preferences.volume*100
	row(Preferences.l("Master volume","ระดับเสียง"),volume,228)
	volume.value_changed.connect(func(value): Preferences.volume=value/100; Preferences.apply_audio())
	volume.drag_ended.connect(func(_value): commit())
	var sensitivity := HSlider.new()
	sensitivity.min_value=50
	sensitivity.max_value=150
	sensitivity.step=10
	sensitivity.value=Preferences.sensitivity*100
	row(Preferences.l("Look sensitivity","ความไวการมอง"),sensitivity,282)
	sensitivity.value_changed.connect(func(value): Preferences.sensitivity=value/100)
	sensitivity.drag_ended.connect(func(_value): commit())
	var mode := CheckButton.new()
	mode.text=Preferences.l("Relaxed / no hunger decay","เดินเล่น / ไม่ลดความหิว")
	mode.button_pressed=Preferences.relaxed
	row(Preferences.l("Play style","รูปแบบการเล่น"),mode,336)
	mode.toggled.connect(func(value): Preferences.relaxed=value; commit())
	var navigation := CheckButton.new()
	navigation.text=Preferences.l("Quest guidance","ตัวนำทางภารกิจ")
	navigation.button_pressed=Preferences.navigation
	row(Preferences.l("Navigation","การนำทาง"),navigation,390)
	navigation.toggled.connect(func(value): Preferences.navigation=value; commit())
	var back := Button.new()
	back.text=Preferences.l("SAVE & BACK","บันทึกและกลับ")
	back.position=Vector2(352,456)
	back.size=Vector2(276,46)
	content.add_child(back)
	back.pressed.connect(func(): commit(); closed.emit())

func row(title: String,control: Control,y: float) -> void:
	label_at(title,Vector2(32,y),270)
	control.position=Vector2(302,y)
	control.size=Vector2(326,40)
	content.add_child(control)

func commit() -> void:
	Preferences.save()
	changed.emit()
