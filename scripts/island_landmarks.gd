extends Node3D
## Blender assets and matching solids, grounded to the rendered island surface.
const PORT := Vector2(-624.71524,1039.86354)
const BAR := Vector2(-747.3106,1257.95412)
var game: Node3D
var port: Node3D
var bar: Node3D
var shutters: Node3D
var lights: Array[OmniLight3D] = []
var manifests: Array[Vector3] = []
var port_desk := Vector3.ZERO
var bar_desk := Vector3.ZERO
var bar_open := false
static func reserved(x: float,z: float,margin := 0.0) -> bool:
	return (absf(x-PORT.x)<26+margin and absf(z-PORT.y)<20+margin) or (absf(x-BAR.x)<10+margin and absf(z-BAR.y)<10+margin)
func build(owner_game: Node3D) -> void:
	game=owner_game
	port=place("ifira_port",PORT,Vector2(48,32))
	bar=place("evening_nakamal",BAR,Vector2(15,12),-1)
	shutters=bar.find_child("ClosedShutters",true,false)
	port_desk=port.position+Vector3(15,0,12)
	bar_desk=bar.to_global(Vector3(0,0,2))
	for offset in [Vector3(1,0,12),Vector3(6,0,12),Vector3(10,0,12)]:
		var marker := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size=Vector3(.7,.8,.7)
		marker.mesh=mesh
		marker.position=port.position+offset+Vector3.UP*.4
		var mat := StandardMaterial3D.new()
		mat.albedo_color=Color("a88a5d")
		marker.material_override=mat
		add_child(marker)
		manifests.append(port.position+offset)
		var body := StaticBody3D.new()
		marker.add_child(body)
		var shape := CollisionShape3D.new()
		shape.shape=BoxShape3D.new()
		shape.shape.size=mesh.size
		body.add_child(shape)
	for x in [-4.5,0,4.5]:
		var light := OmniLight3D.new()
		bar.add_child(light)
		light.position=Vector3(x,2.7,3.5)
		light.light_color=Color("ffbc77")
		light.omni_range=7
		light.light_energy=.7
		lights.append(light)
	update_hours()
func place(asset: String,at: Vector2,footprint: Vector2,facing := 1,folder := "island_expansion") -> Node3D:
	var node := Node3D.new()
	add_child(node)
	var natural := folder=="coastal_detail" and asset in ["waterfall","lagoon","river","cave"]
	var high := -INF
	var low := INF
	for x in range(9):
		for z in range(9):
			var height: float=game.world.surface_height_at(at.x+(x/8.0-.5)*footprint.x,at.y+(z/8.0-.5)*footprint.y)
			high=maxf(high,height)
			low=minf(low,height)
	if natural: high=game.world.surface_height_at(at.x,at.y)-.04
	node.position=Vector3(at.x,high+(.0 if natural else .12),at.y)
	if facing<0: node.rotation.y=PI
	var model: Node3D=load("res://assets/models/"+folder+"/"+asset+".glb").instantiate()
	node.add_child(model)
	for mesh in model.find_children("*","MeshInstance3D",true,false): mesh.visibility_range_end=360
	var body := StaticBody3D.new()
	node.add_child(body)
	var solids: Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/"+folder+"/"+asset+"_collision.json"))
	# Foundation fills the entire gap down to the lowest terrain sample.
	if not natural: solids.append({"center":[0,-(high-low+.65)/2,0],"size":[footprint.x,high-low+.65,footprint.y]})
	for solid in solids:
		var shape := CollisionShape3D.new()
		if solid.has("points"):
			var convex := ConvexPolygonShape3D.new()
			var points := PackedVector3Array()
			for p in solid.points: points.append(Vector3(p[0],p[1],p[2]))
			convex.points=points
			shape.shape=convex
			body.add_child(shape)
			continue
		shape.shape=BoxShape3D.new()
		shape.shape.size=Vector3(solid.size[0],solid.size[1],solid.size[2])
		shape.position=Vector3(solid.center[0],solid.center[1],solid.center[2])
		body.add_child(shape)
	if natural: return node
	# Visible concrete footings share the collision foundation's exact dimensions.
	var base := MeshInstance3D.new()
	base.mesh=BoxMesh.new()
	base.mesh.size=Vector3(footprint.x,high-low+.65,footprint.y)
	base.position.y=-(high-low+.65)/2
	var mat := StandardMaterial3D.new()
	mat.albedo_color=Color("767c73")
	base.material_override=mat
	node.add_child(base)
	# Gentle, solid entrance ramp follows terrain at the foot, avoiding a raised-floor trap.
	var end_z: float=footprint.y/2+8
	var bottom: float=game.world.surface_height_at(at.x,at.y+end_z*facing)
	var ramp := CSGPolygon3D.new()
	var base_y := minf(-.3,bottom-node.position.y-.3)
	ramp.polygon=PackedVector2Array([Vector2(footprint.y/2-1,base_y),Vector2(end_z,base_y),Vector2(end_z,bottom-node.position.y+.04),Vector2(footprint.y/2+.8,.06),Vector2(footprint.y/2-1,.06)])
	ramp.depth=3
	ramp.rotation.y=-PI/2
	ramp.position.x=-1.5
	ramp.material=mat
	ramp.use_collision=true
	node.add_child(ramp)
	return node
func update_hours() -> void:
	bar_open=game.day_time>=16 and game.day_time<23
	if is_instance_valid(shutters): shutters.visible=not bar_open
	for light in lights: light.visible=bar_open
func context() -> String:
	for i in range(manifests.size()):
		if game.player.position.distance_to(manifests[i])<2.5: return game.story.l("INSPECT CARGO LIST","ตรวจรายการสินค้า")
	if game.player.position.distance_to(port_desk)<4: return game.story.l("IFIRA PORT · FOREMAN 07–18","IFIRA PORT · หัวหน้างาน 07–18 น.")
	if game.player.position.distance_to(bar_desk)<6: return "EVENING NAKAMAL · 16:00–23:00"
	return ""
func interact() -> bool:
	for i in range(manifests.size()):
		if game.player.position.distance_to(manifests[i])<2.5:
			game.quests.inspect(i)
			return true
	if game.player.position.distance_to(port_desk)<4:
		if game.day_time<7 or game.day_time>=18: game.tell(game.story.l("Office closed. Return 07:00–18:00.","สำนักงานปิด กลับมาเวลา 07:00–18:00 น."))
		else: game.panel="port"
		return true
	if game.player.position.distance_to(bar_desk)<6:
		game.panel="nakamal"
		return true
	return false
