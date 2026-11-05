extends SceneTree
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	print("CLEANUP ","PASS " if ok else "FAIL ",label)
	if not ok: failures+=1
func run() -> void:
	root.get_node("Preferences").launch="new"
	change_scene_to_file("res://scenes/island.tscn")
	while current_scene==null or current_scene.get("field_hud")==null: await process_frame
	var game=current_scene
	game.set_physics_process(false)
	if root.focus_exited.is_connected(game.on_focus_lost): root.focus_exited.disconnect(game.on_focus_lost)
	var floating := 0
	for label in game.find_children("*","Label3D",true,false):
		if label.billboard!=BaseMaterial3D.BILLBOARD_DISABLED: floating+=1
	check(floating==0,"no floating billboard labels; physical shop signs remain")
	check(game.places.search("Blue Lagoon").size()==1,"directory remains available in inventory")
	check(game.landmarks.manifests.size()==3,"three port cargo interactions preserved")
	var props := game.find_children("Scanned_*","Node3D",true,false)
	check(props.size()>=12,"downloaded props instantiated in playable scene")
	var boats := game.find_children("Harbor_*","Node3D",true,false)
	check(boats.size()==3,"three added boats have clear water placements")
	for boat in boats:
		check(game.world.surface_height_at(boat.position.x,boat.position.z)<-2.5,"boat stays offshore: "+boat.name)
	var homes := 0
	var blocks := 0
	var first: Node3D
	for house in game.settlement.house_sites:
		if house.data.get("downloaded",false):
			var clear := true
			for x in [-.45,0,.45]:
				for z in [-.45,0,.45]:
					var p: Vector3=house.transform*Vector3(x*house.data.w,0,z*house.data.d)
					if game.world.is_on_road(p.x,p.z) or game.world.surface_height_at(p.x,p.z)<.15: clear=false
			check(clear,"building footprint stays on dry ground outside road: "+str(Vector2(house.data.x,house.data.z)))
			if house.data.style==2: blocks+=1
			else: homes+=1
			if first==null: first=house.body
	check(homes+blocks==18,"eighteen downloaded modular buildings retain original lots and solids")
	print("CLEANUP building types homes=",homes," blocks=",blocks)
	for planter in game.find_children("Detail_planter*","Node3D",true,false):
		var p: Vector3=planter.global_position
		check(absf(p.y-game.world.surface_height_at(p.x,p.z))<.03,"planter meets visible terrain")
	if not DisplayServer.get_name()=="headless" and first!=null:
		game.field_hud.hide(); game.player.hide()
		var camera := Camera3D.new();game.add_child(camera);camera.current=true
		camera.position=first.position+Vector3(14,8,15);camera.look_at(first.position+Vector3.UP*2)
		game.world.update_view(camera.position,11,0);game.world.update_daylight(11,true)
		for i in range(30): await process_frame
		root.get_texture().get_image().save_png("res://checks/downloaded-building.png")
	print("CLEANUP RESULT failures=",failures)
	quit(failures)
