extends SceneTree
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	print("TOUCH ","PASS " if ok else "FAIL ",label)
	if not ok: failures+=1
func press(hud,at: Vector2,id := 0,down := true) -> void:
	var event := InputEventScreenTouch.new();event.index=id;event.pressed=down;event.position=at;hud._input(event)
func drag(hud,at: Vector2,id := 0) -> void:
	var event := InputEventScreenDrag.new();event.index=id;event.position=at;event.relative=Vector2(999,999);hud._input(event)
func swipe(game,height: float,steps: int) -> float:
	var hud=game.field_hud
	hud.release_all();hud.size=Vector2(height*2,height)
	game.yaw=0;game.pitch=0
	var start := Vector2(height*1.4,height*.4)
	press(hud,start)
	for i in range(steps): drag(hud,start+Vector2(height*.25*(i+1)/steps,0))
	press(hud,start+Vector2(height*.25,0),0,false)
	return game.yaw
func run() -> void:
	root.get_node("Preferences").launch="new"
	change_scene_to_file("res://scenes/island.tscn")
	while current_scene==null or current_scene.get("field_hud")==null: await process_frame
	var game=current_scene;game.set_physics_process(false);game.panel="";game.paused=false
	var initial_sensitivity: float=root.get_node("Preferences").sensitivity
	root.get_node("Preferences").sensitivity=1
	var one := swipe(game,720,1)
	var many := swipe(game,720,12)
	var high_res := swipe(game,1080,12)
	check(absf(one+.275)<.0001,"quarter-screen-height drag turns 15.8 degrees without extra acceleration")
	check(absf(one-many)<.0001,"same drag follows finger regardless of event batching")
	check(absf(one-high_res)<.0001,"same screen proportion turns equally across resolutions")
	var before: float=game.yaw
	drag(game.field_hud,Vector2(1000,500))
	check(game.yaw==before,"released finger cannot rotate camera")
	root.get_node("Preferences").sensitivity=initial_sensitivity
	print("TOUCH RESULT failures=",failures)
	quit(failures)
