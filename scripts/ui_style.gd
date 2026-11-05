extends RefCounted
const INK := Color("101e25")
const PAPER := Color("e9e5d9")
const GOLD := Color("dbbd7d")
const MUTED := Color("91a7ac")

static func panel(color := INK,radius := 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color=color
	style.set_corner_radius_all(radius)
	style.border_color=Color(0.7,0.81,0.8,0.16)
	style.set_border_width_all(1)
	style.shadow_color=Color(0,0,0,0.22)
	style.shadow_size=8
	style.shadow_offset=Vector2(0,4)
	return style

static func theme() -> Theme:
	var result := Theme.new()
	var font: Font=preload("res://assets/fonts/NotoSansThai.ttf")
	font.fallbacks=[ThemeDB.fallback_font]
	result.default_font=font
	result.default_font_size=17
	for kind in ["Button","OptionButton"]:
		result.set_stylebox("normal",kind,panel(Color("152b33"),7))
		result.set_stylebox("hover",kind,panel(Color("29434a"),7))
		result.set_stylebox("pressed",kind,panel(Color("4a5144"),7))
		var focus := panel(Color(0,0,0,0),7)
		focus.border_color=GOLD
		focus.set_border_width_all(2)
		result.set_stylebox("focus",kind,focus)
		result.set_color("font_color",kind,PAPER)
		result.set_color("font_hover_color",kind,Color.WHITE)
	result.set_color("font_color","Label",PAPER)
	return result
