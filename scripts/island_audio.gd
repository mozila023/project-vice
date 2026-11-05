extends Node3D
## Vanuatu Stringband background music and clean musical gameplay SFX (all spoken voiceovers removed).

var game: Node3D
var sfx_streams := {}

var music_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer] = []
var sfx_cursor := 0
var engine_player: AudioStreamPlayer

var step_timer := 0.0
var last_panel := ""
var last_paused := false
var was_on_floor := true

const MIX_RATE := 22050
const MUSIC_PATH := "res://assets/audio/music/vanuatu_stringband.wav"

func _ready() -> void:
	name = "IslandAudio"
	build_streams()
	setup_players()

func setup_players() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "VanuatuMusic"
	var music_stream := load(MUSIC_PATH) as AudioStreamWAV
	if music_stream != null:
		music_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		music_stream.loop_begin = 0
		music_stream.loop_end = int(music_stream.get_length() * music_stream.mix_rate)
		music_player.stream = music_stream
	music_player.volume_db = -6.0
	add_child(music_player)
	music_player.play()

	for i in range(6):
		var p := AudioStreamPlayer.new()
		p.name = "SFX_%d" % i
		add_child(p)
		sfx_pool.append(p)

	engine_player = AudioStreamPlayer.new()
	engine_player.name = "CarEngine"
	engine_player.stream = sfx_streams["engine_loop"]
	engine_player.volume_db = -13.0
	add_child(engine_player)

func is_speaking() -> bool:
	return false

func on_notice(text: String) -> void:
	if text.begins_with("Thank you! Three fresh fish"):
		play_sfx("discover", 1.08, -2.5)
	elif text.begins_with("A home-cooked meal"):
		play_sfx("eat", 1.0, -2.5)
	elif text.begins_with("New chapter:") or text.begins_with("บทใหม่:"):
		play_sfx("discover", 1.0, -2.0)
	elif text.begins_with("Discovered:") or text.begins_with("ค้นพบ:"):
		play_sfx("discover", 1.12, -2.5)

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

	# Ensure Vanuatu background music stays playing
	if is_instance_valid(music_player) and music_player.stream != null:
		if not music_player.playing:
			music_player.play()
		var target_music_db := -9.0 if game.paused else -5.5
		music_player.volume_db = lerpf(music_player.volume_db, target_music_db, clampf(dt * 6.0, 0.0, 1.0))

	# Panel & pause transitions
	if game.panel != last_panel:
		if game.panel != "":
			play_sfx("ui_open", 1.0, -5.5)
		elif last_panel != "":
			play_sfx("ui_close", 0.95, -6.5)
		last_panel = game.panel
	if game.paused != last_paused:
		play_sfx("ui_open" if game.paused else "ui_close", 0.92, -5.5)
		last_paused = game.paused

	# Vehicle engine loop (only while driving)
	if game.driving != null and not game.blocked():
		if not engine_player.playing:
			engine_player.play()
		var spd: float = absf(game.driving.speed)
		engine_player.pitch_scale = lerpf(engine_player.pitch_scale, 0.78 + clampf(spd / 14.0, 0.0, 1.15), clampf(dt * 8.0, 0.0, 1.0))
		engine_player.volume_db = lerpf(-14.0, -7.5, clampf(spd / 12.0, 0.0, 1.0))
		if game.driving.bumped:
			play_sfx("car_bump", 0.95, -2.5)
	else:
		if engine_player.playing:
			engine_player.stop()

	# Soft footsteps & jump detection
	if not game.blocked() and game.driving == null:
		var on_floor: bool = game.player.is_on_floor()
		if was_on_floor and not on_floor and game.player.velocity.y > 3.0:
			play_sfx("jump", 1.0, -5.0)
		was_on_floor = on_floor
		if on_floor and game.locomotion_speed > 0.35:
			var interval := 0.32 if game.locomotion_state == "sprint" else 0.47
			step_timer -= dt
			if step_timer <= 0.0:
				step_timer = interval
				var pos: Vector3 = game.player.global_position
				var on_road: bool = is_instance_valid(game.world) and game.world.road_surface_offset(pos.x, pos.z) > 0.001
				var kind := "step_road" if on_road else "step_sand"
				var pitch := (1.05 if game.locomotion_state == "sprint" else 0.96) + randf_range(-0.04, 0.04)
				play_sfx(kind, pitch, -9.5 if game.locomotion_state == "sprint" else -11.5)
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
	# Soft low footstep thud on sand/earth
	var sand_len := int(MIX_RATE * 0.075)
	var sand_buf := PackedFloat32Array()
	sand_buf.resize(sand_len)
	for i in range(sand_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / sand_len
		sand_buf[i] = sin(TAU * lerpf(115.0, 58.0, u) * t) * exp(-u * 12.0) * 0.45
	sfx_streams["step_sand"] = make_wav(sand_buf)

	# Soft wooden/shoe tap on road/floor
	var road_len := int(MIX_RATE * 0.065)
	var road_buf := PackedFloat32Array()
	road_buf.resize(road_len)
	for i in range(road_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / road_len
		road_buf[i] = (sin(TAU * lerpf(175.0, 82.0, u) * t) * 0.7 + sin(TAU * 310.0 * t) * 0.3) * exp(-u * 14.0) * 0.45
	sfx_streams["step_road"] = make_wav(road_buf)

	# Jump
	var jmp_len := int(MIX_RATE * 0.14)
	var jmp_buf := PackedFloat32Array()
	jmp_buf.resize(jmp_len)
	for i in range(jmp_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / jmp_len
		jmp_buf[i] = sin(TAU * lerpf(130.0, 260.0, u) * t) * exp(-u * 6.0) * 0.4
	sfx_streams["jump"] = make_wav(jmp_buf)

	# Fishing cast (plucked string + gentle reel spin)
	var cast_len := int(MIX_RATE * 0.26)
	var cast_buf := PackedFloat32Array()
	cast_buf.resize(cast_len)
	for i in range(cast_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / cast_len
		cast_buf[i] = sin(TAU * lerpf(280.0, 560.0, u) * t) * sin(u * PI) * 0.42
	sfx_streams["cast"] = make_wav(cast_buf)

	# Water plop (clean harmonic droplet)
	var spl_len := int(MIX_RATE * 0.22)
	var spl_buf := PackedFloat32Array()
	spl_buf.resize(spl_len)
	for i in range(spl_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / spl_len
		var f := lerpf(240.0, 540.0, minf(u * 2.8, 1.0))
		spl_buf[i] = sin(TAU * f * t) * exp(-u * 8.5) * 0.55
	sfx_streams["splash"] = make_wav(spl_buf)

	# Fish bite alert (two-note marimba alert)
	var bite_len := int(MIX_RATE * 0.32)
	var bite_buf := PackedFloat32Array()
	bite_buf.resize(bite_len)
	for i in range(bite_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / bite_len
		var f := 587.33 if u < 0.48 else 880.0
		var local_u := fmod(u, 0.48) / 0.48
		bite_buf[i] = (sin(TAU * f * t) + 0.2 * sin(TAU * f * 4.0 * t) * exp(-local_u * 12.0)) * exp(-local_u * 5.5) * 0.5
	sfx_streams["bite"] = make_wav(bite_buf)

	# Discovery / Fish catch (Vanuatu marimba C major arpeggio: C5 - E5 - G5 - C6)
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
				var env := (1.0 - exp(-nt * 200.0)) * exp(-nt * 5.5)
				s += (sin(TAU * notes[n_idx] * nt) + 0.16 * sin(TAU * notes[n_idx] * 4.0 * nt) * exp(-nt * 18.0)) * env * 0.25
		disc_buf[i] = s
	sfx_streams["discover"] = make_wav(disc_buf)
	sfx_streams["catch"] = sfx_streams["discover"]

	# Cooking completion marimba two-chord
	var cook_len := int(MIX_RATE * 0.45)
	var cook_buf := PackedFloat32Array()
	cook_buf.resize(cook_len)
	for i in range(cook_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / cook_len
		var f := 523.25 if u < 0.45 else 659.25
		cook_buf[i] = (sin(TAU * f * t) + 0.2 * sin(TAU * f * 2.0 * t)) * exp(-fmod(u, 0.45) * 7.0) * 0.45
	sfx_streams["cook"] = make_wav(cook_buf)

	# Drink water / Eat food / Pickup resource / Rest
	var drk_len := int(MIX_RATE * 0.30)
	var drk_buf := PackedFloat32Array()
	drk_buf.resize(drk_len)
	for i in range(drk_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / drk_len
		drk_buf[i] = sin(TAU * lerpf(330.0, 523.25, u) * t) * sin(u * PI) * 0.45
	sfx_streams["drink"] = make_wav(drk_buf)

	var eat_len := int(MIX_RATE * 0.32)
	var eat_buf := PackedFloat32Array()
	eat_buf.resize(eat_len)
	for i in range(eat_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / eat_len
		var note_f := 523.25 if u < 0.45 else 659.25
		eat_buf[i] = sin(TAU * note_f * t) * exp(-fmod(u, 0.45) * 8.0) * 0.45
	sfx_streams["eat"] = make_wav(eat_buf)

	var pck_len := int(MIX_RATE * 0.15)
	var pck_buf := PackedFloat32Array()
	pck_buf.resize(pck_len)
	for i in range(pck_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / pck_len
		var f := lerpf(392.0, 587.33, minf(u * 2.5, 1.0))
		pck_buf[i] = (sin(TAU * f * t) + 0.2 * sin(TAU * f * 4.0 * t)) * exp(-u * 9.0) * 0.48
	sfx_streams["pickup"] = make_wav(pck_buf)

	var rst_len := int(MIX_RATE * 0.70)
	var rst_buf := PackedFloat32Array()
	rst_buf.resize(rst_len)
	for i in range(rst_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / rst_len
		var env := sin(u * PI) * exp(-u * 2.0)
		rst_buf[i] = (sin(TAU * 261.63 * t) + sin(TAU * 329.63 * t) + sin(TAU * 392.00 * t)) * 0.20 * env
	sfx_streams["rest"] = make_wav(rst_buf)

	# Car door & bump
	var door_len := int(MIX_RATE * 0.18)
	var door_buf := PackedFloat32Array()
	door_buf.resize(door_len)
	for i in range(door_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / door_len
		door_buf[i] = sin(TAU * lerpf(140.0, 58.0, u) * t) * exp(-u * 11.0) * 0.55
	sfx_streams["car_door"] = make_wav(door_buf)
	sfx_streams["car_bump"] = sfx_streams["car_door"]

	# UI wooden marimba click
	var ui_len := int(MIX_RATE * 0.06)
	var open_buf := PackedFloat32Array()
	var close_buf := PackedFloat32Array()
	open_buf.resize(ui_len)
	close_buf.resize(ui_len)
	for i in range(ui_len):
		var t := float(i) / MIX_RATE
		var u := float(i) / ui_len
		var env := exp(-u * 15.0)
		open_buf[i] = sin(TAU * 523.25 * t) * env * 0.38
		close_buf[i] = sin(TAU * 392.00 * t) * env * 0.38
	sfx_streams["ui_open"] = make_wav(open_buf)
	sfx_streams["ui_close"] = make_wav(close_buf)
	sfx_streams["ui_click"] = sfx_streams["ui_open"]

	# Smooth low car engine purr (only plays while driving)
	var eng_len := MIX_RATE
	var eng_buf := PackedFloat32Array()
	eng_buf.resize(eng_len)
	for i in range(eng_len):
		var t := float(i) / MIX_RATE
		var f := 50.0
		var sig := sin(TAU * f * t) * 0.55 + sin(TAU * f * 2.0 * t + 0.3) * 0.25 + sin(TAU * f * 3.0 * t) * 0.10
		eng_buf[i] = sig * 0.32
	sfx_streams["engine_loop"] = make_wav(eng_buf, true)
