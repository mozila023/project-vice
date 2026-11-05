$file = Join-Path $PSScriptRoot '../scripts/island.gd'
$source = [IO.File]::ReadAllText($file)
$source = $source.Replace('const SPAWN := Vector3(0, 3, 85)', @'
const SPAWN := Vector3(-245, 7, 510)
var world: Node3D
var field_hud: Control
var walking_phase := 0.0
'@)
$start = $source.IndexOf('func ground(')
$end = $source.IndexOf('func _ready()', $start)
$source = $source.Substring(0,$start) + @'
func ground(x: float, z: float) -> float:
    return world.height_at(x,z)

'@ + "`n" + $source.Substring($end)
$start = $source.IndexOf('func build_world()')
$end = $source.IndexOf('func add_capsule(', $start)
$source = $source.Substring(0,$start) + @'
func building_material(key: String, color: Color, metal := false) -> ShaderMaterial:
    if materials.has(key): return materials[key]
    var m := ShaderMaterial.new()
    m.shader=load("res://shaders/building.gdshader")
    m.set_shader_parameter("paint",color)
    m.set_shader_parameter("corrugated",metal)
    materials[key]=m
    return m

func build_world() -> void:
    world=preload("res://scripts/tropical_world.gd").new()
    add_child(world)
    world.build()
    var wood := building_material("wood",Color("78664d"))
    var trim := mat("trim",Color("d8d7bd"))
    var glass := mat("glass",Color("23464b"),0.18)
    for i in range(10):
        var x := -220.0+(-25.0 if i%2==0 else 25.0)
        var z := 385.0+floorf(i/2.0)*34.0
        var p := Vector3(x,ground(x,z),z)
        var wall := building_material("wall%d"%(i%3),[Color("d2cfb3"),Color("a7bdb3"),Color("b2bca3")][i%3])
        box(self,"Weatherboard home",p+Vector3(0,2,0),Vector3(10,4,12),wall,true)
        box(self,"Concrete plinth",p+Vector3(0,0.15,0),Vector3(10.5,0.3,12.6),mat("stone",Color("8a8c7b")),true)
        var roof := building_material("roof%d"%(i%2),Color("7b8c88") if i%2==0 else Color("a17b62"),true)
        for side in [-1.0,1.0]:
            var slope := box(self,"Pitched metal roof",p+Vector3(side*2.8,4.5,0),Vector3(6.1,0.13,13.4),roof)
            slope.rotation.z=-side*0.27
        for wx in [-3.1,3.1]:
            box(self,"Window frame",p+Vector3(wx,2.4,6.08),Vector3(2.3,1.75,0.13),trim)
            box(self,"Window glazing",p+Vector3(wx,2.4,6.17),Vector3(2.02,1.48,0.05),glass)
            box(self,"Window mullion",p+Vector3(wx,2.4,6.22),Vector3(0.06,1.5,0.06),trim)
            box(self,"Louver",p+Vector3(wx,2.4,6.25),Vector3(2.0,0.05,0.05),trim)
        box(self,"Timber door",p+Vector3(0,1.5,6.12),Vector3(1.65,3,0.14),wood)
        box(self,"Door handle",p+Vector3(0.55,1.5,6.24),Vector3(0.06,0.18,0.06),glass)
        box(self,"Veranda deck",p+Vector3(0,0.27,7.5),Vector3(9,0.2,3.2),wood,true)
        var awning := box(self,"Veranda roof",p+Vector3(0,3.5,7.4),Vector3(9.5,0.12,3.7),roof)
        awning.rotation.x=-0.12
        for wx in [-4.1,4.1]:
            box(self,"Veranda post",p+Vector3(wx,1.85,8.6),Vector3(0.15,3.2,0.15),trim,true)
        for step in range(3):
            box(self,"Entry step",p+Vector3(0,0.1+step*0.07,9.5-step*0.3),Vector3(2.3,0.2,0.4),wood,true)
        box(self,"Rain tank",p+Vector3(6.2,1.2,2),Vector3(1.8,2.4,2),mat("tank",Color("7e8e79")),true)
        for board in range(4):
            box(self,"Veranda floor seam",p+Vector3(0,0.38,6.6+board*0.65),Vector3(8.8,0.015,0.025),glass)
    var road_surface := SurfaceTool.new()
    road_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for z in range(340,585,4):
        for v in [Vector2(-225,z),Vector2(-215,z),Vector2(-225,z+4),Vector2(-215,z),Vector2(-215,z+4),Vector2(-225,z+4)]:
            road_surface.add_vertex(Vector3(v.x,ground(v.x,v.y)+0.07,v.y))
    road_surface.generate_normals()
    var road := MeshInstance3D.new()
    road.name="Settlement road"
    road.mesh=road_surface.commit()
    road.material_override=building_material("asphalt",Color("555e58"))
    add_child(road)
    for z in range(350,580,9):
        box(self,"Faded lane paint",Vector3(-220,ground(-220,z)+0.1,z),Vector3(0.1,0.012,3),mat("paint",Color("d9d2b5")))
    # Waterfront shelter and timber jetty on the original Mele Bay coast.
    var beach_x := -245.0
    while ground(beach_x,510)>0.5 and beach_x>-500: beach_x-=2
    for i in range(22):
        var x := beach_x+10-i*1.1
        box(self,"Jetty plank",Vector3(x,1.15,510),Vector3(1.02,0.18,3.5),wood,true)
        if i%4==0:
            for z in [-1.5,1.5]:
                box(self,"Jetty piling",Vector3(x,-0.2,510+z),Vector3(0.2,4,0.2),wood,true)
    var tower := Vector3(0,ground(0,0),0)
    for x in [-2.0,2.0]:
        box(self,"Radio mast",tower+Vector3(x,15,0),Vector3(0.22,30,0.22),mat("steel",Color("8b9997")),true)
    for h in range(2,30,3):
        box(self,"Tower crossbrace",tower+Vector3(0,h,0),Vector3(4.2,0.12,0.18),trim)
    box(self,"Radio antenna",tower+Vector3(0,29,0),Vector3(12,0.2,0.2),trim)
    merge_static_meshes()
    for i in range(10):
        var x := -220.0+(-9.0 if i%2==0 else 9.0)
        var z := 390.0+i*18
        var p := Vector3(x,ground(x,z)+0.35,z)
        var item := box(self,"Supply case",p,Vector3(0.8,0.55,0.6),mat("supply",Color("807954")))
        box(item,"Medical stripe",Vector3(0,0.29,0),Vector3(0.16,0.025,0.62),trim)
        supplies.append(item)
    for i in range(14):
        var enemy := CharacterBody3D.new()
        add_child(enemy)
        var x := rng.randf_range(-280,-100)
        var z := rng.randf_range(190,390)
        enemy.position=Vector3(x,ground(x,z)+0.3,z)
        add_capsule(enemy)
        humanoid(enemy,true)
        enemies.append(enemy)

func merge_static_meshes() -> void:
    var groups := {}
    for node in get_children():
        if not node is MeshInstance3D: continue
        var material: Material=node.material_override
        var key := str(material.get_instance_id())+"_"+str(floori(node.position.z/120))
        if not groups.has(key):
            var s := SurfaceTool.new()
            s.begin(Mesh.PRIMITIVE_TRIANGLES)
            groups[key]={"tool":s,"mat":material}
        groups[key].tool.append_from(node.mesh,0,node.transform)
        for child in node.get_children():
            if child is StaticBody3D: child.reparent(self,true)
        node.queue_free()
    for key in groups:
        var merged := MeshInstance3D.new()
        merged.name="VillageBatch_"+key
        merged.mesh=groups[key].tool.commit()
        merged.material_override=groups[key].mat
        merged.visibility_range_end=500
        add_child(merged)

'@ + "`n" + $source.Substring($end)
$start = $source.IndexOf('func humanoid(')
$end = $source.IndexOf('func build_player()', $start)
$source = $source.Substring(0,$start) + @'
func rounded(parent: Node3D, title: String, pos: Vector3, scale: Vector3, material: Material) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.name=title
    var shape := SphereMesh.new()
    shape.radial_segments=10
    shape.rings=6
    shape.radius=0.5
    shape.height=1
    node.mesh=shape
    node.material_override=material
    parent.add_child(node)
    node.position=pos
    node.scale=scale
    return node

func humanoid(parent: Node3D, infected: bool) -> void:
    var cloth := mat("infected" if infected else "jacket",Color("697252") if infected else Color("3b5351"))
    var skin := mat("skin",Color("a88a66"))
    var dark := mat("pants",Color("39443a"))
    rounded(parent,"Torso",Vector3(0,1.2,0),Vector3(0.55,0.72,0.34),cloth)
    rounded(parent,"Head",Vector3(0,1.73,0),Vector3(0.29,0.37,0.31),skin)
    rounded(parent,"Hair",Vector3(0,1.86,0.02),Vector3(0.3,0.17,0.31),dark)
    for x in [-0.15,0.15]:
        var leg := Node3D.new()
        leg.name="LeftLeg" if x<0 else "RightLeg"
        parent.add_child(leg)
        leg.position=Vector3(x,0.86,0)
        rounded(leg,"Trouser",Vector3(0,-0.33,0),Vector3(0.22,0.72,0.25),dark)
        rounded(leg,"Boot",Vector3(0,-0.77,-0.06),Vector3(0.24,0.2,0.37),mat("boots",Color("514b3d")))
        var arm := Node3D.new()
        arm.name="LeftArm" if x<0 else "RightArm"
        parent.add_child(arm)
        arm.position=Vector3(x*2.1,1.43,0)
        rounded(arm,"Sleeve",Vector3(0,-0.13,0),Vector3(0.23,0.36,0.25),cloth)
        rounded(arm,"Forearm",Vector3(0,-0.4,-0.04),Vector3(0.15,0.31,0.17),skin)
        rounded(arm,"Hand",Vector3(0,-0.57,-0.08),Vector3(0.16,0.15,0.17),skin)
        if infected: arm.rotation.x=-0.9
    if not infected:
        rounded(parent,"Backpack",Vector3(0,1.25,0.28),Vector3(0.46,0.6,0.27),mat("pack",Color("7d7956")))
        for x in [-0.18,0.18]:
            box(parent,"Harness",Vector3(x,1.2,-0.18),Vector3(0.045,0.53,0.04),dark)
        box(parent,"Carbine",Vector3(0.35,1.08,-0.42),Vector3(0.09,0.14,0.8),mat("gun",Color("293537")))

func animate_actor(actor: Node3D, speed: float, time: float, infected := false) -> void:
    var swing := sin(time*8.0)*minf(speed/4.5,1.0)*0.48
    actor.get_node("LeftLeg").rotation.x=swing
    actor.get_node("RightLeg").rotation.x=-swing
    if not infected:
        actor.get_node("LeftArm").rotation.x=-swing*0.5
        actor.get_node("RightArm").rotation.x=-0.25+swing*0.3

'@ + "`n" + $source.Substring($end)
$start = $source.IndexOf('func build_ui()')
$end = $source.IndexOf('func _unhandled_input(', $start)
$source = $source.Substring(0,$start) + @'
func build_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    field_hud=preload("res://scripts/field_hud.gd").new()
    field_hud.game=self
    layer.add_child(field_hud)

'@ + "`n" + $source.Substring($end)
$start = $source.IndexOf('func update_ui()')
$end = $source.IndexOf('func save_game()', $start)
$source = $source.Substring(0,$start) + "func update_ui() -> void:`n`tpass`n`n" + $source.Substring($end)
$source = $source.Replace('Input.mouse_mode = Input.MOUSE_MODE_CAPTURED', 'Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if field_hud.mobile else Input.MOUSE_MODE_CAPTURED')
$source = $source.Replace('player.position = SPAWN', 'player.position = Vector3(SPAWN.x,ground(SPAWN.x,SPAWN.z)+0.3,SPAWN.z)')
$source = $source.Replace('Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if blocked() else Input.MOUSE_MODE_CAPTURED', 'Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if blocked() or field_hud.mobile else Input.MOUSE_MODE_CAPTURED')
$source = $source.Replace('event is InputEventMouseMotion and not blocked()', 'event is InputEventMouseMotion and not blocked() and not field_hud.mobile')
$source = $source.Replace('var input := Input.get_vector("left","right","forward","back")', 'var input := Input.get_vector("left","right","forward","back")' + "`n`t`tif field_hud.mobile: input=(input+field_hud.move_vector).limit_length()")
$source = $source.Replace('Input.is_action_pressed("sprint") and stamina>1', '(Input.is_action_pressed("sprint") or field_hud.running) and stamina>1')
$source = $source.Replace('if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED: fire()', 'if field_hud.firing or (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED): fire()')
$source = $source.Replace('Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not blocked()', '(Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or field_hud.aiming) and not blocked()')
$source = $source.Replace('Vector2(player.position.x,player.position.z+90)', 'Vector2(player.position.x,player.position.z)')
$source = $source.Replace('if absf(loaded.x)>190 or absf(loaded.z)>235: return', 'if absf(loaded.x)>1150 or absf(loaded.z)>1450 or ground(loaded.x,loaded.z)<0: return')
$source = $source.Replace('player.rotation.y = yaw', 'player.rotation.y = yaw' + "`n`t`tanimate_actor(player,Vector2(player.velocity.x,player.velocity.z).length(),elapsed)")
$source = $source.Replace('enemy.move_and_slide()', 'enemy.move_and_slide()' + "`n`t`t`tanimate_actor(enemy,Vector2(enemy.velocity.x,enemy.velocity.z).length(),elapsed,true)")
$source = $source.Replace('arm.spring_length = 5.2', 'arm.spring_length = 5.8')
$source = $source.Replace('camera.far = 1600', 'camera.far = 5000')
$source = $source.Replace('var pitch := -0.15', 'var pitch := -0.12')
$source = $source.Replace('var yaw := 0.0', 'var yaw := 0.5')
[IO.File]::WriteAllText($file,$source,[Text.UTF8Encoding]::new($false))
