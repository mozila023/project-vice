extends Node
## Small persistent settings shared by the front end and island.
var language := "th"
var quality := -1
var sensitivity := 1.0
var volume := 0.65
var relaxed := true
var navigation := true
var launch := "new"

func _ready() -> void:
	var file := ConfigFile.new()
	if file.load("user://vice_settings.cfg")==OK:
		language="en" if file.get_value("game","language","th")=="en" else "th"
		quality=clampi(int(file.get_value("game","quality",-1)),-1,2)
		sensitivity=clampf(float(file.get_value("game","sensitivity",1.0)),0.5,1.5)
		volume=clampf(float(file.get_value("game","volume",0.65)),0,1)
		relaxed=bool(file.get_value("game","relaxed",true))
		navigation=bool(file.get_value("game","navigation",true))
	apply_audio()

func save(path := "user://vice_settings.cfg") -> void:
	var file := ConfigFile.new()
	for key in ["language","quality","sensitivity","volume","relaxed","navigation"]: file.set_value("game",key,get(key))
	file.save(path)
	apply_audio()

func apply_audio() -> void:
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(volume,0.001)))
	AudioServer.set_bus_mute(0,volume<=0.001)

func l(en: String,th: String) -> String:
	return th if language=="th" else en
