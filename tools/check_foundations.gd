extends SceneTree
var failures := 0
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.get_node("Preferences").launch="new"
	change_scene_to_file("res://scenes/island.tscn")
	while current_scene==null or current_scene.get("field_hud")==null: await process_frame
	var game=current_scene
	game.set_physics_process(false)
	await physics_frame
	var labels := {}
	var samples := 0
	var gaps := []
	var worst := {}
	var old_floating := 0
	var supports: Array=game.settlement.foundation_supports
	for support: Dictionary in supports:
		labels[support.label]=int(labels.get(support.label,0))+1
		var t: Transform3D=support.transform
		var size: Vector3=support.size
		var center: Vector3=support.center
		var nx := maxi(1,ceili(size.x*2))
		var nz := maxi(1,ceili(size.z*2))
		var old_bottom: float=-3.4 if support.label=="ShopFoundation" else (-2.8 if support.label=="ShopPorch" else 0.0)
		var old_gap := 0.0
		for ix in range(nx+1):
			for iz in range(nz+1):
				var at: Vector3=t*(center+Vector3((float(ix)/nx-.5)*size.x,0,(float(iz)/nz-.5)*size.z))
				var ground: float=game.world.surface_height_at(at.x,at.z)
				var gap: float=t.origin.y+support.bottom-ground
				old_gap=maxf(old_gap,t.origin.y+old_bottom-ground)
				samples+=1
				if gap>0.005: gaps.append({"label":support.label,"at":at,"gap":gap})
		if old_gap>.1: old_floating+=1
		if worst.is_empty() or old_gap>worst.gap: worst={"at":t.origin,"gap":old_gap,"label":support.label}
	if not gaps.is_empty(): failures+=1
	# Inspect actual render instances, not only the collision/support bookkeeping.
	var visible_count := 0
	var render_gaps := 0
	for node in game.settlement.get_children():
		if not node is MultiMeshInstance3D or not String(node.name).begins_with("VisibleFoundations_"): continue
		for i in range(node.multimesh.instance_count):
			visible_count+=1
			var transform: Transform3D=node.global_transform*node.multimesh.get_instance_transform(i)
			for x in [-.5,.5]:
				for z in [-.5,.5]:
					var at: Vector3=transform*Vector3(x,-.5,z)
					if at.y>game.world.surface_height_at(at.x,at.z)+.005: render_gaps+=1
	if visible_count!=supports.size() or render_gaps>0: failures+=1
	for label in ["Foundation","PorchDeck","LowerStep","UpperStep","ShopFoundation","ShopPorch"]:
		if int(labels.get(label,0))==0: failures+=1
	# Visual support and collision must cover the same volume on sampled sloped lots.
	var ray_count := 0
	for i in range(0,supports.size(),maxi(1,supports.size()/20)):
		var s: Dictionary=supports[i]
		var t: Transform3D=s.transform
		var at: Vector3=t*(s.center+Vector3(0,(s.bottom+s.top)*.5,0))
		var from: Vector3=at+t.basis*Vector3(s.size.x*.5+1,0,0)
		var hit: Dictionary=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,at,1))
		if hit.is_empty(): failures+=1
		ray_count+=1
	var result := {"failures":failures,"buildings":game.settlement.house_sites.size(),"supports":supports.size(),"visible_supports":visible_count,"render_gaps":render_gaps,"samples":samples,"support_types":labels,"gaps":gaps.slice(0,20),"worst":worst,"old_unsupported_slabs":old_floating,"collision_checks":ray_count}
	var file := FileAccess.open("res://checks/foundation-results.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	print("FOUNDATION AUDIT ",JSON.stringify(result))
	quit(0 if failures==0 else 1)
