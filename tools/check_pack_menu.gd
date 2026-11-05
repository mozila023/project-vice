extends SceneTree
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	print("PACK ","PASS " if ok else "FAIL ",label)
	if not ok: failures+=1
func key(game,code: int) -> void:
	var event := InputEventKey.new()
	event.pressed=true
	event.physical_keycode=code
	game._unhandled_input(event)
func run() -> void:
	root.get_node("Preferences").launch="new"
	change_scene_to_file("res://scenes/island.tscn")
	while current_scene==null or current_scene.get("field_hud")==null: await process_frame
	var game=current_scene
	game.set_physics_process(false)
	game.paused=false
	game.panel=""
	var hud=game.field_hud
	var language: String=game.story.language
	key(game,KEY_L)
	check(game.story.language==language,"in-game L no longer overrides preselected language")
	for mobile in [false,true]:
		hud.mobile=mobile
		var controls: Dictionary=hud.buttons()
		check(not controls.has("language") and not controls.has("journal") and not controls.has("map") and controls.has("pack"),"gameplay exposes bag without language/quest/map tabs mobile="+str(mobile))
	key(game,KEY_TAB)
	check(game.panel=="pack","Tab opens inventory first")
	for tab in ["journal","island","map","pack"]:
		var controls: Dictionary=hud.buttons()
		var reachable := true
		for target in ["pack","journal","island","map"]: reachable=reachable and controls.has(target)
		check(reachable,"all compact tabs remain reachable from "+game.panel)
		hud.activate(tab,true)
		check(game.panel==tab,"bag switches to "+tab)
		key(game,KEY_TAB)
		check(game.panel=="","Tab closes any bag tab: "+tab)
		key(game,KEY_TAB)
	check(failures==0,"bag interaction regression")
	quit(0 if failures==0 else 1)
