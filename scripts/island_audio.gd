extends Node3D
## Comprehensive island audio: TH/EN spoken voiceovers, speech cadence blips, 3D ambience, footsteps, fishing, cooking, vehicles and UI SFX.

var game: Node3D
var sfx_streams := {}
var voice_cache := {}

var voice_player: AudioStreamPlayer
var blip_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer] = []
var sfx_cursor := 0

var ocean_player: AudioStreamPlayer
var breeze_player: AudioStreamPlayer
var night_player: AudioStreamPlayer
var engine_player: AudioStreamPlayer
var fire_player: AudioStreamPlayer3D

var step_timer := 0.0
var blip_timer := 0.0
var blip_count := 0
var blip_pitch := 1.0
var current_speaker := ""
var last_panel := ""
var last_paused := false
var was_on_floor := true

const MALE_NAMES := ["Jonas", "David", "Peter", "Thomas", "Ben", "Paul"]
const MIX_RATE := 22050

func _ready() -> void:
	name = "IslandAudio"
	build_streams()
	setup_players()

func setup_players() -> void:
	voice_player = AudioStreamPlayer.new()
	voice_player.name = "VoicePlayer"
	voice_player.volume_db = 1.5
	add_child(voice_player)

	blip_player = AudioStreamPlayer.new()
	blip_player.name = "BlipPlayer"
	blip_player.stream = sfx_streams["blip"]
	blip_player.volume_db = -9.5
	add_child(blip_player)

	for i in range(6):
		var p := AudioStreamPlayer.new()
		p.name = "SFX_%d" % i
		add_child(p)
		sfx_pool.append(p)

	ocean_player = AudioStreamPlayer.new()
	ocean_player.name = "OceanAmbience"
	ocean_player.stream = sfx_streams["ocean_loop"]
	ocean_player.volume_db = -12.0
	add_child(ocean_player)
	ocean_player.play()

	breeze_player = AudioStreamPlayer.new()
	breeze_player.name = "BreezeAmbience"
	breeze_player.stream = sfx_streams["breeze_loop"]
	breeze_player.volume_db = -14.0
	add_child(breeze_player)
	breeze_player.play()

	night_player = AudioStreamPlayer.new()
	night_player.name = "NightAmbience"
	night_player.stream = sfx_streams["night_loop"]
	night_player.volume_db = -40.0
	add_child(night_player)
	night_player.play()

	engine_player = AudioStreamPlayer.new()
	engine_player.name = "CarEngine"
	engine_player.stream = sfx_streams["engine_loop"]
	engine_player.volume_db = -12.0
	add_child(engine_player)

	fire_player = AudioStreamPlayer3D.new()
	fire_player.name = "CampfireAudio3D"
	fire_player.stream = sfx_streams["fire_loop"]
	fire_player.unit_size = 5.0
	fire_player.max_distance = 30.0
	fire_player.volume_db = -2.0
	add_child(fire_player)
	if game:
		fire_player.position = game.camp_position + Vector3(0, 0.5, 0)
	fire_player.play()

func is_speaking() -> bool:
	return (is_instance_valid(voice_player) and voice_player.playing) or blip_count > 0

func speaker_pitch(speaker_name: String) -> float:
	if speaker_name.is_empty() or speaker_name.begins_with("Malia"):
		return 1.0
	for m: String in MALE_NAMES:
		if speaker_name.begins_with(m):
			return 0.84 + float(speaker_name.hash() & 3) * 0.015
	return 0.98 + float(speaker_name.hash() & 3) * 0.02

func speak_id(id: String, speaker_name := "") -> void:
	if not is_instance_valid(voice_player) or game == null:
		return
	current_speaker = speaker_name
	var lang: String = "en" if game.story.language == "en" else "th"
	var path := "res://assets/audio/voice/%s_%s.mp3" % [id, lang]
	if not voice_cache.has(path):
		if ResourceLoader.exists(path):
			voice_cache[path] = load(path)
		else:
			voice_cache[path] = null
	var stream: AudioStream = voice_cache[path]
	if stream != null:
		blip_count = 0
		voice_player.stop()
		voice_player.stream = stream
		voice_player.pitch_scale = speaker_pitch(speaker_name)
		voice_player.play()
	else:
		start_blips(10, speaker_pitch(speaker_name))

func speak_dialogue_open(villager_name: String) -> void:
	play_sfx("ui_open", 1.0, -4.0)
	if villager_name.begins_with("Malia"):
		var st: int = clampi(game.story.stage, 0, 6)
		speak_id("story_%d" % st, villager_name)
	else:
		speak_id("villager_greet", villager_name)

func on_notice(text: String) -> void:
	if text.begins_with("Welcome to Sunshine") or text.begins_with("ยินดีต้อนรับสู่ Sunshine"):
		speak_id("welcome", "Malia")
		return
	if text.begins_with("Thank you! Three fresh fish"):
		play_sfx("discover", 1.08, -2.0)
		speak_id("trade_fish", current_speaker)
		return
	if text.begins_with("Bring three fresh fish"):
		speak_id("trade_need_fish", current_speaker)
		return
	if text.begins_with("A home-cooked meal"):
		play_sfx("eat", 1.0, -2.0)
		speak_id("buy_meal", current_speaker)
		return
	if text.begins_with("The Efate coast connects"):
		speak_id("chat_island", current_speaker)
		return
	if text.begins_with("Malia is by the beach fire") or text.begins_with("มาเลียอยู่แถวกองไฟ"):
		speak_id("ask_malia", current_speaker)
		return
	if text.begins_with("Bring 3 driftwood") or text.begins_with("นำไม้ลอยน้ำ 3 ชิ้น"):
		speak_id("need_wood", "Malia")
		return
	if text.begins_with("New chapter:") or text.begins_with("บทใหม่:"):
		play_sfx("discover", 1.0, -1.0)
		if game.panel == "talk" and game.active_villager.begins_with("Malia"):
			speak_id("story_%d" % clampi(game.story.stage, 0, 6), "Malia")
		else:
			start_blips(8, 1.04)
		return
	if text.begins_with("Discovered:") or text.begins_with("ค้นพบ:"):
		play_sfx("discover", 1.12, -1.5)
		start_blips(7, 1.06)
		return
	# For general notices, play subtle syllabic speech blips unless a full voiceover just started.
	if not (is_instance_valid(voice_player) and voice_player.playing):
		var count := clampi(int(text.length() / 7), 4, 12)
		start_blips(count, 1.0)

func start_blips(count: int, pitch := 1.0) -> void:
	blip_count = count
	blip_pitch = pitch
	blip_timer = 0.01

func play_sfx(kind: String, pitch := 1.0, vol_db := 0.0) -> void:
	if not sfx_streams.has(kind) or sfx_pool.is_empty():
		return
	var p: AudioStreamPlayer = sfx_pool[sfx_cursor]
	sfx_cursor = (sfx_cursor + 1) % sfx_pool.size()
	p.stop()
	p.stream = sfx_streams[kind]
	p.pitch_scale = maxf(0.4, pitch)
	p.volume_db = vol_db
	p.play()

func _process(dt: float) -> void:
	if game == null or game.player == null:
		return
	if is_instance_valid(fire_player) and fire_player.position.distance_to(game.camp_position) > 2.0:
		fire_player.position = game.camp_position + Vector3(0, 0.5, 0)

	# Panel & pause transitions
	if game.panel != last_panel:
		if game.panel == "talk":
			speak_dialogue_open(game.active_villager)
		elif game.panel != "":
			play_sfx("ui_open", 1.0, -5.0)
		elif last_panel != "":
			play_sfx("ui_close", 0.95, -6.0)
		last_panel = game.panel
	if game.paused != last_paused:
		play_sfx("ui_open" if game.paused else "ui_close", 0.92, -5.0)
		last_paused = game.paused

	# Speech cadence blips for general notices
	if blip_count > 0:
		blip_timer -= dt
		if blip_timer <= 0.0:
			blip_count -= 1
			blip_timer = 0.065 + float(blip_count % 3) * 0.018
			if is_instance_valid(blip_player) and not (is_instance_valid(voice_player) and voice_player.playing):
				blip_player.pitch_scale = blip_pitch * (0.94 + float(blip_count % 5) * 0.035)
				blip_player.play()

	# Dynamic environmental ambience mix
	var pos: Vector3 = game.player.global_position
	var h: float = game.ground(pos.x, pos.z)
	var shore_factor := clampf(1.0 - (h - 0.5) / 14.0, 0.18, 1.0)
	if is_instance_valid(ocean_player):
		ocean_player.volume_db = lerpf(-22.0, -7.5, shore_factor)
	var night_factor: float = game.world.settlement_night() if is_instance_valid(game.world) else 0.0
	if is_instance_valid(breeze_player):
		breeze_player.volume_db = lerpf(-11.5, -21.0, night_factor)
	if is_instance_valid(night_player):
		night_player.volume_db = lerpf(-38.0, -11.0, night_factor)

	# Vehicle engine loop
	if game.driving != null and not game.blocked():
		if not engine_player.playing:
			engine_player.play()
		var spd: float = absf(game.driving.speed)
		engine_player.pitch_scale = lerpf(engine_player.pitch_scale, 0.76 + clampf(spd / 13.5, 0.0, 1.25), clampf(dt * 8.0, 0.0, 1.0))
		engine_player.volume_db = lerpf(-11.0, -4.5, clampf(spd / 12.0, 0.0, 1.0))
		if game.driving.bumped:
			play_sfx("car_bump", 0.95, -1.5)
	else:
		if engine_player.playing:
			engine_player.stop()

	# Footsteps & jump detection
	if not game.blocked() and game.driving == null:
		var on_floor: bool = game.player.is_on_floor()
		if was_on_floor and not on_floor and game.player.velocity.y > 3.0:
			play_sfx("jump", 1.0, -4.0)
		was_on_floor = on_floor
		if on_floor and game.locomotion_speed > 0.35:
			var interval := 0.31 if game.locomotion_state == "sprint" else 0.46
			step_timer -= dt
			if step_timer <= 0.0:
				step_timer = interval
				var on_road: bool = is_instance_valid(game.world) and game.world.road_surface_offset(pos.x, pos.z) > 0.001
				var kind := "step_road" if on_road else "step_sand"
				var pitch := (1.06 if game.locomotion_state == "sprint" else 0.96) + randf_range(-0.06, 0.06)
				play_sfx(kind, pitch, -6.5 if game.locomotion_state == "sprint" else -8.5)
		else:
			step_timer = 0.08

func make_wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		var s := clampf(samples[i], -1.0, 1.0)
		bytes.encode_s16(i * 2, int(s * 32767.0))
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	return wav

func build_streams() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210

	# 1. Syllabic speech blip (soft warm marimba/vocal formant tone)
	var blip_len := int(MIX_RATE * 0.055)
	var blip_buf := PackedFloat32Array()
	blip_buf.resize(blip_len)
	for i in range(blip_len):
		var t := float(i) / MIX_RATE
		var env := sin(float(i) / blip_len * PI)
		var f := 390.0 + sin(t * 38.0) * 18.0
		blip_buf[i] = (sin(TAU * f * t) * 0.55 + sin(TAU * f * 2.0 * t) * 0.22) * env * 0.45
	sfx_streams["blip"] = make_wav(blip_buf)

	# 2. Footstep sand / grass
	var sand_len := int(MIX_RATE * 0.11)
	var sand_buf := PackedFloat32Array()
	sand_buf.resize(sand_len)
	var lp := 0.0
	for i in range(sand_len):
		var u := float(i) / sand_len
		var env := pow(1.0 - u, 1.8) * sin(minf(u * 6.0, 1.0) * PI * 0.5)
		var n := rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, n, 0.28)
		var thud := sin(TAU * (95.0 - u * 40.0) * (float(i) / MIX_RATE)) * exp(-u * 9.0)
		sand_buf[i] = (lp * 0.65 + thud * 0.45) * env * 0.55
	sfx_streams["step_sand"] = make_wav(sand_buf)

	# 3. Footstep road / floor
	var road_len := int(MIX_RATE * 0.085)
	var road_buf := PackedFloat32Array()
	road_buf.resize(road_len)
	var rlp := 0.0
	for i in range(road_len):
		var u := float(i) / road_len
		var env := exp(-u * 10.0)
		rlp = lerpf(rlp, rng.randf_range(-1.0, 1.0), 0.52)
		var tap := sin(TAU * (165.0 - u * 60.0) * (float(i) / MIX_RATE))
		road_buf[i] = (rlp * 0.45 + tap * 0.55) * env * 0.55
	sfx_streams["step_road"] = make_wav(road_buf)

	# 4. Jump push-off
	var jmp_len := int(MIX_RATE * 0.16)
	var jmp_buf := PackedFloat32Array()
	jmp_buf.resize(jmp_len)
	for i in range(jmp_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / jmp_len
		var freq := lerpf(110.0, 260.0, u)
		jmp_buf[i] = (sin(TAU * freq * t) * 0.5 + rng.randf_range(-0.25, 0.25)) * (1.0 - u) * 0.5
	sfx_streams["jump"] = make_wav(jmp_buf)

	# 5. Fishing cast whoosh + reel whirr
	var cast_len := int(MIX_RATE * 0.34)
	var cast_buf := PackedFloat32Array()
	cast_buf.resize(cast_len)
	var clp := 0.0
	for i in range(cast_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / cast_len
		var env := sin(u * PI)
		clp = lerpf(clp, rng.randf_range(-1.0, 1.0), 0.15 + u * 0.35)
		var whirr := sin(TAU * (420.0 + u * 380.0) * t) * (0.5 + 0.5 * sin(TAU * 42.0 * t))
		cast_buf[i] = (clp * 0.65 + whirr * 0.25) * env * 0.65
	sfx_streams["cast"] = make_wav(cast_buf)

	# 6. Water splash / plop
	var spl_len := int(MIX_RATE * 0.32)
	var spl_buf := PackedFloat32Array()
	spl_buf.resize(spl_len)
	var slp := 0.0
	for i in range(spl_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / spl_len
		var plop_f := lerpf(240.0, 520.0, minf(u * 3.5, 1.0))
		var plop := sin(TAU * plop_f * t) * exp(-u * 9.0)
		slp = lerpf(slp, rng.randf_range(-1.0, 1.0), 0.32)
		var spray := slp * exp(-u * 4.5) * (0.6 + 0.4 * sin(TAU * 19.0 * t))
		spl_buf[i] = (plop * 0.55 + spray * 0.65) * 0.7
	sfx_streams["splash"] = make_wav(spl_buf)

	# 7. Fish bite alert (urgent dual-ping + reel click)
	var bite_len := int(MIX_RATE * 0.36)
	var bite_buf := PackedFloat32Array()
	bite_buf.resize(bite_len)
	for i in range(bite_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / bite_len
		var f := 660.0 if u < 0.45 else 880.0
		var local_u := fmod(u, 0.45) / 0.45
		var env := exp(-local_u * 4.5)
		var click := sin(TAU * 55.0 * t) > 0.85
		bite_buf[i] = (sin(TAU * f * t) * 0.55 + sin(TAU * f * 2.0 * t) * 0.2 + (0.2 if click else 0.0)) * env * 0.65
	sfx_streams["bite"] = make_wav(bite_buf)

	# 8. Fish caught / discovery chord (C5 - E5 - G5 - C6 arpeggio)
	var disc_len := int(MIX_RATE * 0.68)
	var disc_buf := PackedFloat32Array()
	disc_buf.resize(disc_len)
	var notes: Array[float] = [523.25, 659.25, 783.99, 1046.50]
	for i in range(disc_len):
		var t := float(i) / MIX_RATE
		var s := 0.0
		for n_idx in range(notes.size()):
			var onset := n_idx * 0.10
			if t >= onset:
				var nt := t - onset
				var env := exp(-nt * 5.2)
				s += (sin(TAU * notes[n_idx] * nt) + 0.3 * sin(TAU * notes[n_idx] * 2.0 * nt)) * env * 0.26
		disc_buf[i] = s
	sfx_streams["discover"] = make_wav(disc_buf)
	sfx_streams["catch"] = sfx_streams["discover"]

	# 9. Cooking sizzle + warm chime
	var cook_len := int(MIX_RATE * 0.62)
	var cook_buf := PackedFloat32Array()
	cook_buf.resize(cook_len)
	var klp := 0.0
	for i in range(cook_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / cook_len
		var raw := rng.randf_range(-1.0, 1.0)
		klp = lerpf(klp, raw, 0.65)
		var sizzle := (raw - klp * 0.5) * sin(u * PI) * 0.45
		var bell := sin(TAU * 784.0 * t) * exp(-maxf(0.0, t - 0.15) * 6.0) * (0.35 if t > 0.15 else 0.0)
		cook_buf[i] = sizzle + bell
	sfx_streams["cook"] = make_wav(cook_buf)

	# 10. Drink water (refreshing splash + harmonic drop)
	var drk_len := int(MIX_RATE * 0.38)
	var drk_buf := PackedFloat32Array()
	drk_buf.resize(drk_len)
	for i in range(drk_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / drk_len
		var gulp_f := 320.0 + sin(TAU * 7.5 * t) * 90.0 + u * 180.0
		var env := sin(u * PI)
		drk_buf[i] = (sin(TAU * gulp_f * t) * 0.5 + rng.randf_range(-0.12, 0.12)) * env * 0.55
	sfx_streams["drink"] = make_wav(drk_buf)

	# 11. Eat food (crisp bite + warm two-note chime)
	var eat_len := int(MIX_RATE * 0.36)
	var eat_buf := PackedFloat32Array()
	eat_buf.resize(eat_len)
	for i in range(eat_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / eat_len
		var crunch := rng.randf_range(-1.0, 1.0) * exp(-u * 14.0) * 0.5
		var note_f := 587.33 if u < 0.45 else 783.99
		var chime := sin(TAU * note_f * t) * exp(-fmod(u, 0.45) * 9.0) * 0.4
		eat_buf[i] = crunch + chime
	sfx_streams["eat"] = make_wav(eat_buf)

	# 12. Pickup resource (woody marimba pop)
	var pck_len := int(MIX_RATE * 0.16)
	var pck_buf := PackedFloat32Array()
	pck_buf.resize(pck_len)
	for i in range(pck_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / pck_len
		var f := lerpf(380.0, 620.0, minf(u * 2.5, 1.0))
		pck_buf[i] = (sin(TAU * f * t) + 0.35 * sin(TAU * f * 2.0 * t)) * exp(-u * 8.0) * 0.55
	sfx_streams["pickup"] = make_wav(pck_buf)

	# 13. Rest at shelter (soothing warm chord)
	var rst_len := int(MIX_RATE * 0.75)
	var rst_buf := PackedFloat32Array()
	rst_buf.resize(rst_len)
	for i in range(rst_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / rst_len
		var env := sin(u * PI) * exp(-u * 1.8)
		rst_buf[i] = (sin(TAU * 261.63 * t) + sin(TAU * 329.63 * t) + sin(TAU * 392.00 * t) + sin(TAU * 493.88 * t)) * 0.18 * env
	sfx_streams["rest"] = make_wav(rst_buf)

	# 14. Car door open/close & car bump
	var door_len := int(MIX_RATE * 0.22)
	var door_buf := PackedFloat32Array()
	door_buf.resize(door_len)
	for i in range(door_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / door_len
		var latch := sin(TAU * 920.0 * t) * exp(-u * 35.0) * 0.45
		var thud := sin(TAU * lerpf(135.0, 55.0, u) * t) * exp(-maxf(0.0, u - 0.18) * 12.0) * (0.75 if u >= 0.18 else 0.0)
		door_buf[i] = latch + thud
	sfx_streams["car_door"] = make_wav(door_buf)

	var bump_len := int(MIX_RATE * 0.24)
	var bump_buf := PackedFloat32Array()
	bump_buf.resize(bump_len)
	for i in range(bump_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / bump_len
		bump_buf[i] = (sin(TAU * lerpf(120.0, 48.0, u) * t) * 0.7 + rng.randf_range(-0.3, 0.3)) * exp(-u * 10.0) * 0.7
	sfx_streams["car_bump"] = make_wav(bump_buf)

	# 15. UI click / open / close
	var ui_len := int(MIX_RATE * 0.065)
	var open_buf := PackedFloat32Array()
	var close_buf := PackedFloat32Array()
	open_buf.resize(ui_len)
	close_buf.resize(ui_len)
	for i in range(ui_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / ui_len
		var env := exp(-u * 14.0)
		open_buf[i] = sin(TAU * lerpf(480.0, 720.0, u) * t) * env * 0.45
		close_buf[i] = sin(TAU * lerpf(640.0, 420.0, u) * t) * env * 0.45
	sfx_streams["ui_open"] = make_wav(open_buf)
	sfx_streams["ui_close"] = make_wav(close_buf)
	sfx_streams["ui_click"] = sfx_streams["ui_open"]

	# 16. Continuous Loops: Ocean surf (6s), Day breeze & tropical birds (6s), Night crickets (4s), Campfire (3s), Car engine (1s)
	var ocean_len := MIX_RATE * 6
	var ocean_buf := PackedFloat32Array()
	ocean_buf.resize(ocean_len)
	var olp1 := 0.0
	var olp2 := 0.0
	for i in range(ocean_len):
		var t := float(i) / MIX_RATE
		var wave := 0.48 + 0.42 * sin(TAU * t / 6.0) + 0.10 * sin(TAU * t / 3.0 + 1.1)
		var wn := rng.randf_range(-1.0, 1.0)
		olp1 = lerpf(olp1, wn, 0.04 + 0.08 * wave)
		olp2 = lerpf(olp2, olp1, 0.12)
		ocean_buf[i] = olp2 * wave * 0.65
	sfx_streams["ocean_loop"] = make_wav(ocean_buf, true)

	var brz_len := MIX_RATE * 6
	var brz_buf := PackedFloat32Array()
	brz_buf.resize(brz_len)
	var blp := 0.0
	for i in range(brz_len):
		var t := float(i) / MIX_RATE
		blp = lerpf(blp, rng.randf_range(-1.0, 1.0), 0.025)
		var wind := blp * (0.35 + 0.25 * sin(TAU * t / 6.0))
		var bird := 0.0
		for call_t: float in [1.1, 1.32, 3.6, 3.85, 4.1]:
			var dt_c: float = t - call_t
			if dt_c >= 0.0 and dt_c < 0.16:
				var bf: float = 1650.0 + sin(dt_c * 55.0) * 280.0 + dt_c * 600.0
				bird += sin(TAU * bf * dt_c) * sin(dt_c / 0.16 * PI) * 0.14
		brz_buf[i] = wind * 0.45 + bird
	sfx_streams["breeze_loop"] = make_wav(brz_buf, true)

	var ngt_len := MIX_RATE * 4
	var ngt_buf := PackedFloat32Array()
	ngt_buf.resize(ngt_len)
	for i in range(ngt_len):
		var t := float(i) / MIX_RATE
		var pulse := maxf(0.0, sin(TAU * 3.5 * t)) * (0.5 + 0.5 * sin(TAU * 28.0 * t))
		ngt_buf[i] = sin(TAU * 3850.0 * t) * pulse * 0.12
	sfx_streams["night_loop"] = make_wav(ngt_buf, true)

	var fire_len := MIX_RATE * 3
	var fire_buf := PackedFloat32Array()
	fire_buf.resize(fire_len)
	var flp := 0.0
	for i in range(fire_len):
		var wn := rng.randf_range(-1.0, 1.0)
		flp = lerpf(flp, wn, 0.06)
		var pop := wn * 0.75 if rng.randf() < 0.0028 else 0.0
		fire_buf[i] = (flp * 0.35 + pop) * 0.65
	sfx_streams["fire_loop"] = make_wav(fire_buf, true)

	var eng_len := MIX_RATE
	var eng_buf := PackedFloat32Array()
	eng_buf.resize(eng_len)
	for i in range(eng_len):
		var t := float(i) / MIX_RATE
		var f := 52.0
		var sig := sin(TAU * f * t) * 0.48 + sin(TAU * f * 2.0 * t + 0.4) * 0.28 + sin(TAU * f * 3.0 * t) * 0.14 + sin(TAU * f * 4.0 * t) * 0.07
		eng_buf[i] = tanh(sig * 1.4) * 0.42
	sfx_streams["engine_loop"] = make_wav(eng_buf, true)
