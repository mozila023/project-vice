extends CharacterBody3D
## One car, in any of three roles: parked, following the traffic route, or driven by the player.
## Handling is arcade rather than simulated: it stays predictable on the coarse terrain and cheap on phones.
## Road car: Innerscene, CC0, consolidated to 20 material batches.
const LAYER_WORLD := 1
const LAYER_PEOPLE := 2
const LAYER_CARS := 4
const LAYER_TREES := 8
## The ground has its own layer: cars ride on the height data, so their box must not catch on slopes.
const LAYER_TERRAIN := 16
## Steeper than this ahead of the car is a bank it cannot climb (rise per metre).
const MAX_CLIMB := 0.8
const LENGTHS := {"sedan":4.5,"suv":4.7,"taxi":4.5,"hatchback-sports":4.1,"van":5.2,"truck":5.8}
const MAX_SPEED := 26.0
const MAX_REVERSE := 8.0
const WHEELBASE := 2.7
const GROUND_CLEARANCE := 0.4

var world: Node3D
var kind := ""
var speed := 0.0
var steer := 0.0
var half_length := 2.2
var half_width := 0.9
var bumped := false
var tilt: Node3D
var flip := 1.0
var front_wheels: Array[Node3D] = []
var all_wheels: Array[Node3D] = []
var wheel_spin := 0.0
var wheel_rest := {}

func setup(model_kind: String,world_node: Node3D,paint_index := 0) -> void:
	kind=model_kind
	world=world_node
	name=kind.capitalize().replace(" ","")
	motion_mode=CharacterBody3D.MOTION_MODE_FLOATING
	collision_layer=LAYER_CARS
	collision_mask=LAYER_WORLD|LAYER_PEOPLE|LAYER_CARS|LAYER_TREES
	wall_min_slide_angle=0.0
	tilt=Node3D.new()
	add_child(tilt)
	var model: Node3D=preload("res://assets/models/vehicles/road_car.scn").instantiate()
	tilt.add_child(model)
	var bounds := measure(model)
	# The kit's cars are all proportioned alike, so scale by length and let height follow.
	var scale_factor: float=4.7/maxf(bounds.size.z,0.01)
	model.scale=Vector3.ONE*scale_factor
	var paints := [Color("c2c8c8"),Color("23434e"),Color("a7a295"),Color("61423a"),Color("d1c7ad"),Color("333c44")]
	for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		var source=mesh.material_override
		if source is StandardMaterial3D and source.resource_name in ["white","blue"]:
			var paint: StandardMaterial3D=source.duplicate()
			paint.albedo_color=Color("c8ae62") if kind=="taxi" else paints[paint_index%paints.size()]
			paint.metallic=0.35
			paint.roughness=0.3
			mesh.material_override=paint
	for node in model.find_children("wheel-*","Node3D",true,false):
		if node.name.contains("left") or node.name.contains("right"):
			all_wheels.append(node)
			wheel_rest[node]=node.basis
			if node.name.contains("front"): front_wheels.append(node)
	# +Z is forward everywhere in the game: turn the model round if its front wheels point the other way.
	if not front_wheels.is_empty() and front_wheels[0].position.z<0.0:
		flip=-1.0
		model.rotation.y=PI
	var centre: Vector3=bounds.get_center()*scale_factor
	model.position=Vector3(-centre.x*flip,-bounds.position.y*scale_factor,-centre.z*flip)
	half_length=bounds.size.z*scale_factor*0.5
	half_width=bounds.size.x*scale_factor*0.5
	var height: float=bounds.size.y*scale_factor
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size=Vector3(half_width*2.0,height-GROUND_CLEARANCE,half_length*2.0)
	collision.shape=shape
	collision.position.y=GROUND_CLEARANCE+(height-GROUND_CLEARANCE)*0.5
	add_child(collision)

func measure(root: Node3D) -> AABB:
	var bounds := AABB()
	var found := false
	for mesh: MeshInstance3D in root.find_children("*","MeshInstance3D",true,false):
		mesh.visibility_range_end=320.0
		var transform := Transform3D.IDENTITY
		var cursor: Node3D=mesh
		while cursor!=root:
			transform=cursor.transform*transform
			cursor=cursor.get_parent()
		var box: AABB=transform*mesh.get_aabb()
		bounds=bounds.merge(box) if found else box
		found=true
	return bounds

func forward() -> Vector3:
	return Vector3(sin(rotation.y),0,cos(rotation.y))

## One physics step of player driving. throttle: -1 reverse .. 1 forward. turn: -1 left .. 1 right.
func drive(dt: float,throttle: float,turn: float,handbrake: bool) -> void:
	if throttle>0.05:
		speed+=(16.0 if speed<-0.5 else lerpf(8.5,2.5,absf(speed)/MAX_SPEED))*throttle*dt
	elif throttle<-0.05:
		speed+=(18.0 if speed>0.5 else 5.0)*throttle*dt
	else:
		speed=move_toward(speed,0.0,2.2*dt)
	if handbrake: speed=move_toward(speed,0.0,22.0*dt)
	# Off the tarmac the car is held back: rough ground, not a wall.
	var on_road: bool=world.is_on_road(position.x,position.z)
	var top: float=MAX_SPEED if on_road else MAX_SPEED*0.55
	if speed>top: speed=move_toward(speed,top,10.0*dt)
	speed=maxf(speed,-MAX_REVERSE)
	var lock: float=lerpf(0.62,0.14,clampf(absf(speed)/MAX_SPEED,0.0,1.0))
	steer=move_toward(steer,-turn*lock,dt*2.8)
	rotation.y+=speed/WHEELBASE*tan(steer)*dt
	# The sea is the end of the road.
	var reach: float=half_length+1.0
	var nose: Vector3=position+forward()*signf(speed)*reach
	var nose_height: float=world.height_at(nose.x,nose.z)
	if absf(speed)>0.01 and (nose_height<-0.25 or nose_height-world.height_at(position.x,position.z)>MAX_CLIMB*reach): speed=0.0
	velocity=forward()*speed
	var before: float=speed
	move_and_slide()
	bumped=get_slide_collision_count()>0
	if bumped: speed=get_real_velocity().dot(forward())*0.85
	bumped=bumped and absf(before)>4.0
	settle(dt,false)
	spin_wheels(dt)

## Pose set from outside, for the traffic route.
func follow(at: Vector3,heading: float,moving_speed: float,dt: float) -> void:
	position=at
	rotation.y=lerp_angle(rotation.y,heading,clampf(dt*5.0,0.0,1.0))
	speed=moving_speed
	settle(dt,false)
	spin_wheels(dt)

## Sits the car on the terrain and leans the body to match the slope under it.
func settle(dt: float,instant: bool) -> void:
	var f: Vector3=forward()
	var left := Vector3(f.z,0,-f.x)
	var ahead: Vector3=position+f*half_length
	var behind: Vector3=position-f*half_length
	var port: Vector3=position+left*half_width
	var starboard: Vector3=position-left*half_width
	var h_front: float=world.height_at(ahead.x,ahead.z)
	var h_back: float=world.height_at(behind.x,behind.z)
	var h_left: float=world.height_at(port.x,port.z)
	var h_right: float=world.height_at(starboard.x,starboard.z)
	position.y=maxf((h_front+h_back+h_left+h_right)*0.25,world.height_at(position.x,position.z))+0.1
	var pitch: float=atan2(h_back-h_front,half_length*2.0)
	var roll: float=atan2(h_left-h_right,half_width*2.0)
	var blend: float=1.0 if instant else clampf(dt*8.0,0.0,1.0)
	tilt.rotation.x=lerpf(tilt.rotation.x,pitch,blend)
	tilt.rotation.z=lerpf(tilt.rotation.z,roll,blend)

func spin_wheels(dt: float) -> void:
	wheel_spin=fmod(wheel_spin+speed/0.33*dt*flip,TAU)
	for wheel in all_wheels:
		var turned: float=steer if wheel in front_wheels else 0.0
		wheel.basis=Basis(Vector3.UP,turned)*Basis(Vector3.RIGHT,wheel_spin)*wheel_rest[wheel]
