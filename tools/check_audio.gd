extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("CHECK FAILED: ", message)
	else:
		print("OK: ", message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var music := load("res://assets/audio/music/vanuatu_stringband.wav") as AudioStreamWAV
	check(music != null and music.get_length() > 50.0, "Vanuatu Stringband music loaded (%.2fs)" % (music.get_length() if music else 0.0))
	check(not DirAccess.dir_exists_absolute("res://assets/audio/voice"), "Voiceover directory removed completely")

	var scene: Node = load("res://scenes/island.tscn").instantiate()
	root.add_child(scene)
	for i in range(4):
		await process_frame

	var audio: Node3D = scene.get("audio")
	check(audio != null and is_instance_valid(audio), "IslandAudio node initialized on island")
	if audio:
		check(audio.music_player != null and audio.music_player.stream != null and audio.music_player.playing, "Vanuatu Stringband music playing on island")
		check(not audio.is_speaking(), "No spoken voiceovers active")
		for key: String in ["step_sand", "step_road", "jump", "cast", "splash", "bite", "catch", "cook", "drink", "eat", "pickup", "rest", "car_door", "car_bump", "ui_open", "ui_close", "engine_loop"]:
			check(audio.sfx_streams.has(key) and audio.sfx_streams[key] != null, "SFX stream ready: " + key)

	print("AUDIO CHECK COMPLETE failures=", failures)
	quit(1 if failures > 0 else 0)
