extends SceneTree
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	print("MOUNTS ","PASS " if ok else "FAIL ",label)
	if not ok: failures+=1
func run() -> void:
	root.get_node("Preferences").launch="new"
	change_scene_to_file("res://scenes/island.tscn")
	while current_scene==null or current_scene.get("field_hud")==null: await process_frame
	var game=current_scene
	game.set_physics_process(false)
	if root.focus_exited.is_connected(game.on_focus_lost): root.focus_exited.disconnect(game.on_focus_lost)
	var spa=game.sunshine
	var hospital: Node3D=game.places.featured["way/307095157"]
	check(Vector2(hospital.position.x-spa.position.x,hospital.position.z-spa.position.z).length()>30,"hospital model no longer overlaps salon parcel")
	var dry := true
	for x in [-9,0,9]:
		for z in [-5,0,5]:
			var p: Vector3=hospital.to_global(Vector3(x,0,z))
			if game.world.is_on_road(p.x,p.z) or game.world.surface_height_at(p.x,p.z)<.3: dry=false
	check(dry,"hospital model footprint is dry and clear of roads")
	var pin: Dictionary=game.places.by_id["way/307095157"]
	check(Vector2(pin.at[0],pin.at[1]).distance_to(Vector2(-437.71322,890.63625))<.01,"original hospital geographic pin is preserved")
	var ac: Node3D=spa.get_node("Detail_ac_unit")
	check(ac.position.distance_to(Vector3(3.5,1.8,-6.54))<.001,"AC references permanent shell offset on solid rear wall")
	var gutter: Node3D=spa.get_node("Detail_gutter")
	check(gutter.position.distance_to(Vector3(3,3.3,2.65))<.001,"gutter follows actual roof edge")
	for shape in spa.body.get_children():
		if shape is CollisionShape3D and shape.shape is BoxShape3D and is_equal_approx(shape.shape.size.x,12.4):
			var bottom: float=spa.floor_height+shape.position.y-shape.shape.size.y/2
			var covered := true
			for x in [-6.2,0,6.2]:
				for z in [-4.45,0,4.45]:
					var p: Vector3=spa.to_global(Vector3(x,0,z)+spa.SHELL_OFFSET)
					if bottom>game.world.surface_height_at(p.x,p.z)-.05: covered=false
			check(covered,"visible foundation reaches terrain across rotated shell footprint")
	if DisplayServer.get_name()!="headless":
		game.field_hud.hide();game.player.hide()
		var camera := Camera3D.new();game.add_child(camera);camera.current=true
		for pose in [Vector3(-12,4.8,-14),Vector3(-12,4.8,13)]:
			camera.position=spa.position+pose;camera.look_at(spa.position+Vector3(0,1,0))
			game.world.update_daylight(11,true);game.world.update_view(camera.position,11,0)
			for i in range(30): await process_frame
			root.get_texture().get_image().save_png("res://checks/sunshine-mount-"+("front" if pose.z<0 else "rear")+".png")
	print("MOUNTS RESULT failures=",failures)
	quit(failures)
