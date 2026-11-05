extends SceneTree
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool,label: String) -> void:
	print("BOARDING ","PASS " if ok else "FAIL ",label)
	if not ok: failures+=1

func run() -> void:
	change_scene_to_file("res://scenes/front_end.tscn")
	while current_scene==null or current_scene.get("boarding")==null or current_scene.get("view")==null: await process_frame
	var front=current_scene
	front.set_process(false)
	var sequence=front.boarding
	var aircraft: AABB=front.bounds(front.plane)
	check(aircraft.size.x>20 and aircraft.size.x<23 and aircraft.size.z>24 and aircraft.size.z<27,"aircraft retains metre-scale fuselage and wingspan")
	check(absf(aircraft.position.y)<0.01,"aircraft wheels rest on apron")
	check(sequence.door.is_finite() and sequence.door.y>0.8 and sequence.door.y<1.4,"landing height comes from the mesh's aft-door UV")
	check(sequence.WIDTH>=0.75 and sequence.WIDTH<=0.9 and sequence.step_count==6,"stairs have human-scale width and six treads")
	check(sequence.rise>0.15 and sequence.rise<0.19,"step rise is suitable for the actor's scale")
	check(sequence.RUN*sequence.step_count<aircraft.size.x*0.1,"stair flight is small relative to aircraft")
	var treads_match := true
	for i in range(sequence.step_count):
		var tread: MeshInstance3D=sequence.get_node("Tread_%02d"%i)
		var top: float=tread.position.y+(tread.mesh as BoxMesh).size.y*0.5
		if absf(top-(i+1)*sequence.rise)>0.001: treads_match=false
	check(treads_match,"tread tops follow the measured rise")
	var aligned := true
	var forward := true
	var clear := true
	var last_z: float=sequence.approach.z
	for i in range(151):
		var at: float=i*0.05
		var pose: Dictionary=sequence.pose(at)
		var position: Vector3=pose.position
		aligned=aligned and absf(position.x-sequence.door.x)<0.001
		forward=forward and position.z>=last_z-0.001 and is_zero_approx(float(pose.yaw))
		clear=clear and position.z+0.3<sequence.door.z-0.23
		last_z=position.z
	check(aligned,"entire passenger path stays on stair and doorway centreline")
	check(forward,"passenger faces and moves toward the door")
	check(clear,"passenger stops before penetrating the aircraft shell")
	var arrival: Dictionary=sequence.pose(sequence.LANDING_END)
	check((arrival.position as Vector3).is_equal_approx(sequence.entry) and absf(arrival.position.y-sequence.door.y)<0.001,"path finishes on landing at door-floor height")
	check(sequence.pose(7.4).clip=="idle","actor settles at doorway before cabin cut")
	front.screen="intro"
	for at in [0.0,1.5,3.5,5.5,6.6,7.4]:
		front.set_intro_pose(at)
		check(front.traveler.visible and absf(front.traveler.position.x-sequence.door.x)<0.001,"actor remains visible and aligned at t="+str(at))
	front.set_intro_pose(8.0)
	check(front.cabin.visible and not front.apron.visible,"boarding cuts cleanly to cabin")
	print("BOARDING RESULT ","PASS" if failures==0 else "FAIL"," failures=",failures)
	quit(0 if failures==0 else 1)
