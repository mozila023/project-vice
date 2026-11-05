extends SceneTree
## Headless integration check using the real island and vehicle models.
var failures: Array[String] = []

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
	print("DRIVING ", "PASS " if ok else "FAIL ", message)

func run() -> void:
	change_scene_to_file("res://scenes/island.tscn")
	while current_scene==null or current_scene.get("field_hud")==null:
		await process_frame
	var game = current_scene
	game.set_physics_process(false)
	await physics_frame
	check(game.cars.size()>=12,"traffic and parked cars spawn")
	var car = game.cars[4]
	game.player.position=car.position
	car.speed=6.0
	check(game.nearest_car()!=car,"moving car cannot be selected")
	game.enter_car(car)
	check(game.driving==null,"moving car cannot be entered directly")
	car.speed=0.0
	game.enter_car(car)
	check(game.driving==car and game.player.collision_mask==0,"enter car disables pedestrian collision")
	car.speed=6.0
	check(not game.leave_car() and game.driving==car,"exit is blocked at speed")
	car.speed=0.0
	check(game.leave_car() and game.driving==null and game.player.visible,"stopped car allows safe exit")
	check(game.player.collision_mask==game.PLAYER_MASK,"exit restores pedestrian collision")
	var npc = game.villagers[0].body
	var original: Vector3=npc.position
	game.player.position=Vector3(1200,100,1200)
	npc.position=car.position+car.forward()*4.0
	check(game.blocked_ahead(car,car.forward()),"traffic detects villagers ahead")
	npc.position=original
	print("DRIVING RESULT ", "PASS" if failures.is_empty() else "FAIL", " failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
