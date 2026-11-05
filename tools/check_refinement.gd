extends SceneTree
var failures := 0
var report := {}

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool,label: String) -> void:
	report[label]=ok
	print("REFINEMENT ","PASS " if ok else "FAIL ",label)
	if not ok: failures+=1

func ray(a: Vector3,b: Vector3,mask := 1) -> Dictionary:
	return current_scene.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a,b,mask))

func run() -> void:
	root.get_node("Preferences").launch="new"
	change_scene_to_file("res://scenes/island.tscn")
	while current_scene==null or current_scene.get("field_hud")==null: await process_frame
	var game=current_scene
	game.set_physics_process(false)
	if root.focus_exited.is_connected(game.on_focus_lost): root.focus_exited.disconnect(game.on_focus_lost)
	await physics_frame
	check(game.settlement.refined_parts.size()>20,"Blender house is used by settlement generator")
	var houses := 0
	var walls_blocked := true
	var posts_blocked := true
	var deck_open := true
	var capsule_blocked := true
	for site in game.settlement.house_sites:
		if site.data.style==2: continue
		houses+=1
		var t: Transform3D=site.transform
		var width: float=site.data.w
		var depth: float=site.data.d
		var hit := ray(t*Vector3(width*0.5+1.5,1.2,0),t*Vector3(0,1.2,0))
		walls_blocked=walls_blocked and not hit.is_empty() and hit.collider==site.body
		var from := Transform3D(Basis.IDENTITY,t*Vector3(width*0.5+1.5,0.5,0))
		var motion: Vector3=t.basis*Vector3(-width*0.5-1.5,0,0)
		capsule_blocked=capsule_blocked and game.player.test_move(from,motion)
		var post_x: float=3.12*width/8
		var post_z: float=6.85*depth/10
		hit=ray(t*Vector3(post_x,1.4,post_z+0.8),t*Vector3(post_x,1.4,post_z-0.3))
		posts_blocked=posts_blocked and not hit.is_empty() and hit.collider==site.body
		hit=ray(t*Vector3(0,1.4,7.0*depth/10),t*Vector3(0,1.4,5.4*depth/10))
		deck_open=deck_open and hit.is_empty()
		if houses>=12: break
	check(houses>=5 and walls_blocked,"sampled house walls block movement rays")
	check(capsule_blocked,"player capsule cannot move through sampled house walls")
	check(posts_blocked,"porch posts have matching collision")
	check(deck_open,"porch opening stays passable between posts")
	var rock_count := 0
	var rocks_hit := false
	for node in game.world.get_children():
		if not node is MultiMeshInstance3D or node.name!="Rocks": continue
		var body: StaticBody3D = node.get_node_or_null("RockCollision")
		if body==null: continue
		rock_count+=body.get_child_count()
		if body.get_child_count()>0:
			var shape: CollisionShape3D=body.get_child(0)
			var center: Vector3=shape.global_transform*shape.shape.get_debug_mesh().get_aabb().get_center()
			var hit := ray(center+Vector3.UP*12,center,game.world.TREE_LAYER)
			rocks_hit=rocks_hit or (not hit.is_empty() and hit.collider==body)
	check(rock_count>0 and rocks_hit,"batched rocks have physical hulls")
	var prop_bodies := game.find_children("PropCollision_*","StaticBody3D",true,false)
	var kinds := {}
	for body in prop_bodies: kinds[String(body.name)]=body.get_child_count()
	check(kinds.has("PropCollision_village_well"),"well has Blender-derived collision")
	check(kinds.has("PropCollision_island_shelter"),"shelter has separate structural collision")
	check(kinds.has("PropCollision_spa_furniture"),"salon furniture has component collision")
	var data: Dictionary=game.prop_physics.definitions
	var grounded := true
	for node in game.get_children():
		for entry in [["village_well","PropCollision_village_well"],["campfire_pit","PropCollision_campfire_pit"],["island_shelter","PropCollision_island_shelter"]]:
			if node.get_node_or_null(entry[1])==null: continue
			var bottom: float=node.position.y+data[entry[0]].min[1]
			grounded=grounded and absf(bottom-game.world.surface_height_at(node.position.x,node.position.z))<0.02
	check(grounded,"static props contact the visible terrain surface")
	var splash: Node3D=load("res://assets/models/island_refined/fishing_splash.glb").instantiate()
	root.add_child(splash)
	var animation: AnimationPlayer=splash.find_child("AnimationPlayer",true,false)
	check(animation!=null and animation.get_animation_list().size()==1 and animation.get_animation(animation.get_animation_list()[0]).get_track_count()>=20,"Blender splash exports one complete multi-object animation")
	splash.queue_free()
	var original_count := game.get_child_count()
	game.fishing_splash(Vector3(-530,0,170))
	check(game.get_child_count()==original_count+1,"fishing splash spawns in the game")
	await create_timer(1.2).timeout
	check(game.get_child_count()==original_count,"fishing splash cleans up after playback")
	var file := FileAccess.open("res://checks/refinement-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures":failures,"checks":report},"\t"))
	print("REFINEMENT RESULT ","PASS" if failures==0 else "FAIL"," failures=",failures)
	quit(0 if failures==0 else 1)
