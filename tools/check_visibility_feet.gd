extends SceneTree
var failures := 0
var details := []
func _initialize() -> void: run.call_deferred()
func check(ok: bool,label: String) -> void:
	print("CONTACT ","PASS " if ok else "FAIL ",label)
	if not ok: failures+=1
func run() -> void:
	root.get_node("Preferences").launch="new"
	change_scene_to_file("res://scenes/island.tscn")
	while current_scene==null or current_scene.get("field_hud")==null: await process_frame
	var game=current_scene
	game.set_physics_process(false)
	if root.focus_exited.is_connected(game.on_focus_lost): root.focus_exited.disconnect(game.on_focus_lost)
	await physics_frame
	var complete := true
	for node in game.settlement.get_children():
		if not node is MeshInstance3D or not String(node.name).begins_with("Town_"): continue
		var arrays: Array=node.mesh.surface_get_arrays(0)
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
		if indices.is_empty(): continue
		var used := PackedByteArray()
		used.resize((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
		for index in indices: used[index]=1
		for flag in used: complete=complete and flag==1
	check(complete,"all town vertices are referenced by rendered triangles")
	for tier in range(3):
		game.world.tier=tier
		game.world.apply_tier()
		var visible := true
		for site: Dictionary in game.settlement.house_sites:
			var at: Vector3=site.transform.origin
			var chunk := Vector2i(floori(at.x/180),floori(at.z/180))
			var key: String="plaster" if site.data.style in [1,2] else "board"
			var mesh: MeshInstance3D=game.settlement.get_node_or_null("Town_%s_%d_%d" % [key,chunk.x,chunk.y])
			visible=visible and mesh!=null
			if mesh:
				visible=visible and mesh.global_position.distance_to(at)<mesh.visibility_range_end-30
				visible=visible and (mesh.global_transform*mesh.get_aabb()).grow(.1).has_point(at+Vector3.UP*1.5)
		check(visible,"every nearby house remains in its own chunk range at tier "+str(tier))
	var poles_ok: bool=not game.settlement.pole_sites.is_empty()
	for at: Vector3 in game.settlement.pole_sites:
		var chunk := Vector2i(floori(at.x/180),floori(at.z/180))
		var mesh: MeshInstance3D=game.settlement.get_node_or_null("Town_pole_%d_%d" % [chunk.x,chunk.y])
		poles_ok=poles_ok and mesh!=null and absf(at.y-game.world.surface_height_at(at.x,at.z))<.01
		if mesh: poles_ok=poles_ok and (mesh.global_transform*mesh.get_aabb()).grow(.1).has_point(at+Vector3.UP*3)
	check(poles_ok,"every mapped wire support has a visible grounded pole")
	var spans_ok := true
	for span: Dictionary in game.settlement.wire_spans:
		for at: Vector3 in [span.from,span.to]: spans_ok=spans_ok and game.settlement.pole_sites.has(at)
	check(spans_ok,"all wire span endpoints terminate at mapped pole sites")
	var animation: AnimationPlayer=game.visual.find_child("AnimationPlayer",true,false)
	animation.callback_mode_process=2
	var sites := [{"name":"village","at":Vector2(-489,141)},{"name":"asphalt","at":Vector2(-300,380)},{"name":"sand","at":Vector2(-528,178)},{"name":"slope","at":Vector2(-316.9,74.5)},{"name":"spa","at":Vector2(-222.78,440.0)},{"name":"restaurant","at":game.restaurant.SITE+Vector2(0,2.5)}]
	for site: Dictionary in sites:
		var p: Vector2=site.at
		var height: float=game.ground(p.x,p.y)
		if site.name=="spa": height=game.sunshine.floor_height
		if site.name=="restaurant": height=game.restaurant.floor_height
		game.player.position=Vector3(p.x,height+.5,p.y)
		game.player.velocity=Vector3.ZERO
		for i in range(60):
			await physics_frame
			game.player.velocity=Vector3(0,-4,0)
			game.player.move_and_slide()
			game.player.apply_floor_snap()
		var worst := 0.0
		for heading in [0.0,PI*.5,PI]:
			game.player.rotation.y=heading
			for clip in ["idle","walk","sprint"]:
				animation.play(clip)
				for phase in [0.0,.25,.5,.75]:
					animation.seek(phase*animation.current_animation_length,true)
					animation.advance(0)
					var skeleton: Skeleton3D=game.visual.find_child("Skeleton3D",true,false)
					skeleton.force_update_all_bone_transforms()
					game.foot_contact.update(game.player,game.visual,game.world,1.0)
					for at: Vector3 in game.foot_contact.points(game.visual):
						worst=maxf(worst,game.foot_contact.surface(game.player,at,game.world)-at.y)
		details.append({"site":site.name,"penetration":worst,"lift":game.visual.position.y,"on_floor":game.player.is_on_floor()})
		check(game.player.is_on_floor() and worst<.012,"shoe support points stay above visible surface: "+site.name)
	game.visual.position.y=.2
	await physics_frame
	game.player.velocity=Vector3.UP*6
	game.player.move_and_slide()
	game.foot_contact.update(game.player,game.visual,game.world,.1)
	check(not game.player.is_on_floor() and game.visual.position.y<.2,"jumping releases ground correction")
	var file := FileAccess.open("res://checks/visibility-feet-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures":failures,"feet":details,"poles":game.settlement.pole_sites.size(),"wire_spans":game.settlement.wire_spans.size()},"\t"))
	print("CONTACT RESULT ",JSON.stringify(details)," failures=",failures)
	quit(0 if failures==0 else 1)
