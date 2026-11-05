extends SceneTree
var failures := 0
var report := {}
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	print("LUNA ","PASS " if ok else "FAIL ",label)
	report[label]=ok
	if not ok: failures+=1
func follow(game,target_stage: int) -> void:
	game.panel=""
	game.paused=false
	Engine.time_scale=10
	for i in range(2400):
		await physics_frame
		var old: Vector3=game.luna.position
		game.player.position=old+Vector3(0,0,-2.5)
		game.guide.update(10.0/60.0)
		game.story.update()
		if i%400==0: print("LUNA ROUTE stage=",game.story.stage," at=",game.luna.position," waypoint=",game.guide.waypoint,"/",game.guide.route.size())
		if game.story.stage>=target_stage: break
	Engine.time_scale=1
	check(game.story.stage==target_stage,"Luna physically reaches tour stop stage "+str(target_stage))
func run() -> void:
	root.get_node("Preferences").launch="new"
	change_scene_to_file("res://scenes/island.tscn")
	var timeout := Time.get_ticks_msec()+30000
	while current_scene==null or current_scene.get("field_hud")==null:
		await process_frame
		if Time.get_ticks_msec()>timeout:
			printerr("LUNA game startup failed")
			quit(2)
			return
	var game=current_scene
	game.set_physics_process(false)
	if root.focus_exited.is_connected(game.on_focus_lost): root.focus_exited.disconnect(game.on_focus_lost)
	await physics_frame
	check(game.story.stage==0 and game.luna.position.distance_to(game.player.position)<3,"new game starts beside Luna at Sunshine")
	game.interact()
	check(game.panel=="talk" and game.active_villager=="Luna","interacting at spawn opens Luna introduction")
	game.trade("story")
	check(game.story.stage==1 and game.panel=="","Let's go starts the real walking escort")
	game.guide.make_route()
	var before: Vector3=game.luna.position
	game.player.position=before+Vector3(60,0,0)
	for i in range(15):
		await physics_frame
		game.guide.update(1.0/60.0)
	check(game.guide.waiting and Vector2(game.luna.position.x-before.x,game.luna.position.z-before.z).length()<.15,"Luna waits rather than disappearing when player falls behind")
	await follow(game,2)
	var saved: Dictionary=game.story.data()
	game.story.stage=0
	game.story.restore(saved)
	check(game.story.stage==2 and game.story.dialogue().contains("Pad Thai"),"tour stage and guide position survive save restore")
	game.active_villager="Luna";game.panel="talk"
	game.trade("story")
	check(game.story.stage==3,"restaurant conversation starts hotel leg")
	await follow(game,4)
	game.active_villager="Luna";game.panel="talk"
	game.trade("story")
	check(game.story.stage==5 and game.quests.unlocked(),"hotel introduction finishes onboarding and unlocks optional island stories")
	game.player.position=game.restaurant.position+Vector3(0,.08,2.5)
	game.panel=""
	game.interact()
	check(game.panel=="restaurant","Pad Thai can be used by entering its real dining room")
	game.food=10;game.thirst=10;game.coins=20
	game.service("restaurant_meal")
	check(game.coins==12 and game.food==55 and game.thirst==30,"Pad Thai meal charges eight vatu and restores needs")
	game.fish=1;game.coconuts=1;game.wood=1
	game.service("ingredient_fish");game.service("ingredient_coconuts");game.service("ingredient_wood")
	check(game.coins==36 and game.fish==0 and game.coconuts==0 and game.wood==0,"restaurant buys each ingredient at its displayed price")
	game.service("ingredient_fish")
	check(game.coins==36 and game.fish==0,"empty ingredient cannot generate money")
	game.coins=0;game.service("restaurant_meal")
	check(game.coins==0 and game.food==55,"meal cannot be bought without enough money")
	# Traverse the inn entrance using the actual player capsule.
	game.player.position=Vector3(game.hotel.ENTRANCE.x,game.world.surface_height_at(game.hotel.ENTRANCE.x,game.hotel.ENTRANCE.y)+.2,game.hotel.ENTRANCE.y)
	game.player.velocity=Vector3.ZERO
	var goal: Vector3=game.hotel.rest_point
	for i in range(320):
		await physics_frame
		var delta: Vector3=goal-game.player.position
		delta.y=0
		if delta.length()<.2: break
		var direction: Vector3=delta.normalized()
		game.player.velocity=Vector3(direction.x*3,game.player.velocity.y-20.0/60,direction.z*3)
		game.player.move_and_slide()
		game.player.apply_floor_snap()
	check(Vector2(goal.x-game.player.position.x,goal.z-game.player.position.z).length()<.3,"player walks through the inn door to the bed aisle")
	game.panel="";game.interact()
	check(game.panel=="hotel","inn bed service opens inside the room")
	game.coins=10;game.day_time=21.5;game.days=2;game.energy=5;game.stamina=4
	game.service("sleep")
	check(game.coins==0 and game.day_time==8 and game.days==3 and game.energy==100 and game.stamina==100,"hotel sleep charges room fee and advances to next morning")
	await create_timer(1.3).timeout
	check(not game.resting,"sleep fade releases controls")
	game.day_time=8;game.days=3
	game.advance_hours(3600.0*24/game.REAL_DAY_SECONDS)
	check(game.days==4 and is_equal_approx(game.day_time,8),"one real hour equals exactly one game day")
	game.day_time=23.999;game.days=4;game.advance_hours(.01)
	check(game.days==5 and game.day_time<.02,"midnight rolls calendar forward once")
	var periods := []
	for hour in [6.0,10.0,14.0,18.0,23.0]: game.day_time=hour;periods.append(game.time_period())
	check(periods.size()==5 and periods[0]!=periods[1] and periods[3]!=periods[4],"clock exposes morning, late morning, afternoon, evening and night")
	game.story.restore({"stage":6,"language":"th"})
	check(game.story.stage==0,"old recovery-story saves migrate into Luna onboarding")
	var file := FileAccess.open("res://checks/luna-tour-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures":failures,"checks":report},"\t"))
	print("LUNA RESULT failures=",failures)
	quit(0 if failures==0 else 1)
