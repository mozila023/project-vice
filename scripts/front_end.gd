extends Node3D
## Blender-rendered aerial menu keeps mobile startup lightweight.
var screen := "menu"
var clock := 0.0
var loading := false
var camera: Camera3D
var view: Control
var ambience: AudioStreamPlayer
func _ready() -> void:
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	camera=Camera3D.new()
	add_child(camera)
	camera.current=true
	var layer := CanvasLayer.new()
	add_child(layer)
	view=preload("res://scripts/front_view.gd").new()
	view.front=self
	layer.add_child(view)
	ambience=AudioStreamPlayer.new()
	add_child(ambience)
	var music := preload("res://assets/audio/music/vanuatu_stringband.wav") as AudioStreamWAV
	music.loop_mode=AudioStreamWAV.LOOP_FORWARD
	music.loop_end=int(music.get_length()*music.mix_rate)
	ambience.stream=music
	ambience.volume_db=-5.5
	ambience.play()
func start_new_game() -> void:
	Preferences.launch="new"
	arrive()
func continue_game() -> void:
	Preferences.launch="continue"
	arrive()
func arrive() -> void:
	if loading: return
	loading=true
	screen="loading"
	ambience.stop()
	ResourceLoader.load_threaded_request("res://scenes/island.tscn")
func _process(dt: float) -> void:
	clock+=dt
	if loading and ResourceLoader.load_threaded_get_status("res://scenes/island.tscn")==ResourceLoader.THREAD_LOAD_LOADED:
		get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get("res://scenes/island.tscn"))
