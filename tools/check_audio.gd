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

	var voice_ids: Array[String] = [
		"welcome", "story_0", "story_1", "story_2", "story_3", "story_4", "story_5", "story_6",
		"villager_greet", "trade_fish", "trade_need_fish", "buy_meal", "chat_island", "ask_malia", "need_wood"
	]
	for id: String in voice_ids:
		for lang: String in ["th", "en"]:
			var path := "res://assets/audio/voice/%s_%s.mp3" % [id, lang]
			var stream := load(path) as AudioStreamMP3
			check(stream != null and stream.get_length() > 0.8, "Voiceover loaded: %s (%.2fs)" % [path, stream.get_length() if stream else 0.0])

	var scene: Node = load("res://scenes/island.tscn").instantiate()
	root.add_child(scene)
	for i in range(4):
		await process_frame

	var audio: Node3D = scene.get("audio")
	check(audio != null and is_instance_valid(audio), "IslandAudio node initialized on island")
	if audio:
		check(audio.music_player != null and audio.music_player.stream != null and audio.music_player.playing, "Vanuatu Stringband music playing on island")
		for key: String in ["blip", "step_sand", "step_road", "jump", "cast", "splash", "bite", "catch", "cook", "drink", "eat", "pickup", "rest", "car_door", "car_bump", "ui_open", "ui_close", "ocean_loop", "breeze_loop", "night_loop", "fire_loop", "engine_loop"]:
			check(audio.sfx_streams.has(key) and audio.sfx_streams[key] != null, "SFX stream ready: " + key)

		# Test Malia story dialogue voiceover in TH and EN
		scene.story.language = "th"
		scene.active_villager = "Malia / Fisher"
		scene.panel = "talk"
		audio._process(0.016)
		check(audio.is_speaking() and absf(audio.voice_player.pitch_scale - 1.0) < 0.01, "Malia speaks TH story voiceover at natural female pitch")

		scene.switch_language()
		check(scene.story.language == "en" and audio.is_speaking(), "Switching language to EN replays Malia voiceover in English")

		# Test Male villager greeting pitch differentiation
		scene.panel = ""
		audio._process(0.016)
		scene.active_villager = "Jonas / Market"
		scene.panel = "talk"
		audio._process(0.016)
		check(audio.is_speaking() and audio.voice_player.pitch_scale < 0.92, "Male villager Jonas speaks with lower male vocal pitch (%.2f)" % audio.voice_player.pitch_scale)

	print("AUDIO CHECK COMPLETE failures=", failures)
	quit(1 if failures > 0 else 0)
