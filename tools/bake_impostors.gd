extends SceneTree
## Offline: renders heavy CC0 source models to cut-out atlases and generates tiling procedural textures.
## Needs a GPU window:  godot --path . --script res://tools/bake_impostors.gd
## Writes to res://assets/baked. Sources come from tools/download_realism_assets.ps1.

const SRC := "res://tools/.cache/polyhaven/"
const OUT := "res://assets/baked/"
const CELL := 1024

func _initialize() -> void:
	bake()

func bake() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var meta := {}
	var trees := Image.create_empty(CELL*2,CELL*2,false,Image.FORMAT_RGBA8)
	var ground := Image.create_empty(CELL,CELL,false,Image.FORMAT_RGBA8)
	for entry in [["tree_a","island_tree_01",0,0],["tree_b","island_tree_02",1,0],["bush","shrub_02",1,1]]:
		var shot: Dictionary=await render_model(entry[1],CELL)
		trees.blit_rect(shot.image,Rect2i(0,0,CELL,CELL),Vector2i(entry[2],entry[3])*CELL)
		meta[entry[0]]={"size":shot.size,"height":shot.height,"cell":[entry[2],entry[3]]}
		print("BAKE ",entry[0]," size=",shot.size," height=",shot.height)
	var palm := await render_palm(CELL)
	trees.blit_rect(palm.image,Rect2i(0,0,CELL,CELL),Vector2i(0,1)*CELL)
	meta["palm"]={"size":palm.size,"height":palm.height,"cell":[0,1]}
	for entry in [["fern","fern_02",0,0],["leafy","calathea_orbifolia_01",1,0],["shrub","shrub_04",0,1],["grass","grass_medium_02",1,1]]:
		var shot: Dictionary=await render_model(entry[1],CELL/2)
		ground.blit_rect(shot.image,Rect2i(0,0,CELL/2,CELL/2),Vector2i(entry[2],entry[3])*(CELL/2))
		meta[entry[0]]={"size":shot.size,"height":shot.height,"cell":[entry[2],entry[3]]}
		print("BAKE ",entry[0]," size=",shot.size," height=",shot.height)
	trees.save_png(OUT+"foliage_trees.png")
	ground.save_png(OUT+"foliage_ground.png")
	FileAccess.open(OUT+"foliage_meta.json",FileAccess.WRITE).store_string(JSON.stringify(meta,"\t"))
	frond_texture().save_png(OUT+"palm_frond.png")
	palm_bark_texture().save_png(OUT+"palm_bark.png")
	water_textures()
	print("BAKE done")
	quit()

func load_model(id: String) -> Node3D:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var path := ProjectSettings.globalize_path(SRC+id+"/"+id+".gltf")
	var error := doc.append_from_file(path,state)
	if error!=OK: push_error("Could not load "+path)
	return doc.generate_scene(state)

func studio(subject: Node3D) -> SubViewport:
	var view := SubViewport.new()
	view.size=Vector2i(CELL*2,CELL*2)
	view.own_world_3d=true
	view.transparent_bg=true
	view.msaa_3d=Viewport.MSAA_4X
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color(0.3,0.42,0.22,0)
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color(1,1,0.97)
	env.ambient_light_energy=0.72
	env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	world.environment=env
	view.add_child(world)
	var top := DirectionalLight3D.new()
	top.rotation_degrees=Vector3(-68,-30,0)
	top.light_energy=0.55
	view.add_child(top)
	view.add_child(subject)
	return view

func measure(node: Node3D) -> AABB:
	var bounds := AABB()
	var found := false
	var meshes: Array=node.find_children("*","MeshInstance3D",true,false)
	if node is MeshInstance3D: meshes.append(node)
	for mesh in meshes:
		var box: AABB=mesh.global_transform*mesh.get_aabb()
		bounds=bounds.merge(box) if found else box
		found=true
	return bounds

## Plant packs lay several variants in a row: keep only the largest, so it fills the atlas cell.
func keep_largest_variant(node: Node3D) -> void:
	var best: MeshInstance3D=null
	var best_volume := -1.0
	for mesh in node.find_children("*","MeshInstance3D",true,false):
		var box: AABB=mesh.global_transform*mesh.get_aabb()
		if box.size.y>best_volume:
			best_volume=box.size.y
			best=mesh
	for mesh in node.find_children("*","MeshInstance3D",true,false):
		if mesh!=best: mesh.visible=false; mesh.get_parent().remove_child(mesh)

func shoot(view: SubViewport,bounds: AABB,out_size: int) -> Dictionary:
	# Square framing with the base at the bottom edge and the trunk centred, as the runtime card expects.
	var extent := maxf(maxf(bounds.size.x,bounds.size.z),bounds.size.y)*1.02
	var camera := Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=extent
	camera.near=0.1
	camera.far=extent*6+100
	view.add_child(camera)
	var centre := bounds.get_center()
	camera.position=Vector3(centre.x,bounds.position.y+extent*0.5,centre.z+extent*3)
	camera.current=true
	for i in range(6): await process_frame
	var image: Image=view.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	image.resize(out_size,out_size,Image.INTERPOLATE_LANCZOS)
	view.queue_free()
	await process_frame
	return {"image":image,"size":extent,"height":bounds.size.y}

func render_model(id: String,out_size: int) -> Dictionary:
	var subject := load_model(id)
	var view := studio(subject)
	await process_frame
	if not id.begins_with("island_tree"): keep_largest_variant(subject)
	return await shoot(view,measure(subject),out_size)

func render_palm(out_size: int) -> Dictionary:
	# The billboard must match the runtime mesh, so the far palm renders the very mesh used up close.
	var builder=load("res://scripts/flora.gd").new()
	var frond_image := frond_texture()
	var bark_image := palm_bark_texture()
	var mesh: ArrayMesh=builder.palm_mesh()
	var node := MeshInstance3D.new()
	node.mesh=mesh
	var bark := StandardMaterial3D.new()
	bark.albedo_texture=ImageTexture.create_from_image(bark_image)
	bark.vertex_color_use_as_albedo=true
	var frond := StandardMaterial3D.new()
	frond.albedo_texture=ImageTexture.create_from_image(frond_image)
	frond.vertex_color_use_as_albedo=true
	frond.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	frond.alpha_scissor_threshold=0.4
	frond.cull_mode=BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0,bark)
	mesh.surface_set_material(1,frond)
	var view := studio(node)
	await process_frame
	return await shoot(view,measure(node),out_size)

## A coconut frond: stiff midrib and many narrow, slightly irregular leaflets on transparency.
func frond_texture() -> Image:
	var w := 256
	var h := 1024
	var image := Image.create_empty(w,h,true,Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed=99
	var noise := FastNoiseLite.new()
	noise.seed=7
	noise.frequency=0.03
	var pixels := PackedByteArray()
	pixels.resize(w*h*4)
	# Base stays filled with leaf colour so mipmaps do not bleed a dark fringe.
	for i in range(w*h):
		pixels[i*4]=60; pixels[i*4+1]=86; pixels[i*4+2]=32; pixels[i*4+3]=0
	var count := 72
	for leaflet in range(count):
		var t := (leaflet+rng.randf_range(-0.2,0.2))/float(count)
		var base_y := t*h
		var taper := sin(clampf(t*1.05+0.04,0,1)*PI)
		for side in [-1.0,1.0]:
			var length := (0.92+rng.randf_range(-0.1,0.06))*taper*(w*0.5)
			var droop := rng.randf_range(62.0,90.0)*(0.6+t*0.5)
			var thick := rng.randf_range(3.0,4.6)
			var tone := rng.randf_range(0.78,1.08)
			var dry := rng.randf()<0.08
			var steps := int(length)
			for s in range(steps):
				var f := s/maxf(1.0,float(steps))
				var cx: float=w*0.5+side*s
				var cy: float=base_y+droop*f*f+droop*0.35*f
				var half: float=thick*(1.0-f*f*0.92)*(0.45+0.55*minf(f*7.0,1.0))
				for y in range(int(cy-half-1),int(cy+half+2)):
					if y<0 or y>=h: continue
					var edge: float=clampf(half-absf(y-cy)+0.5,0,1)
					if edge<=0: continue
					var at: int=(y*w+int(cx))*4
					var crease: float=0.86+0.14*absf(y-cy)/maxf(half,0.01)
					var mottling := 0.92+noise.get_noise_2d(cx,y)*0.22
					var colour := Color(0.27,0.40,0.13).lerp(Color(0.62,0.60,0.24),f*f*0.55)
					if dry: colour=colour.lerp(Color(0.60,0.47,0.24),0.75)
					colour*=tone*crease*mottling
					pixels[at]=int(clampf(colour.r,0,1)*255)
					pixels[at+1]=int(clampf(colour.g,0,1)*255)
					pixels[at+2]=int(clampf(colour.b,0,1)*255)
					pixels[at+3]=maxi(pixels[at+3],int(edge*255))
	# Midrib on top of the leaflets.
	for y in range(h):
		var half := lerpf(5.0,1.2,float(y)/h)
		for x in range(int(w*0.5-half),int(w*0.5+half)+1):
			var at := (y*w+x)*4
			pixels[at]=168; pixels[at+1]=152; pixels[at+2]=88; pixels[at+3]=255
	return Image.create_from_data(w,h,false,Image.FORMAT_RGBA8,pixels)

## Grey ringed palm bark, tiling vertically.
func palm_bark_texture() -> Image:
	var size := 256
	var image := Image.create_empty(size,size,false,Image.FORMAT_RGB8)
	var noise := FastNoiseLite.new()
	noise.seed=3
	noise.frequency=0.06
	noise.fractal_octaves=4
	var rings := 8.0
	for y in range(size):
		var v := float(y)/size
		var ring := pow(absf(sin(v*rings*PI)),0.35)
		for x in range(size):
			var a := float(x)/size*TAU
			var n := noise.get_noise_3d(cos(a)*40.0,sin(a)*40.0,y*0.7)
			var streak := noise.get_noise_3d(cos(a)*90.0,sin(a)*90.0,y*0.08)
			var value := 0.40+n*0.22+streak*0.14
			value*=lerpf(0.52,1.0,ring)
			image.set_pixel(x,y,Color(value*1.03,value*0.94,value*0.82))
	return image

func water_textures() -> void:
	var noise := FastNoiseLite.new()
	noise.noise_type=FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed=21
	noise.frequency=0.018
	noise.fractal_type=FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves=4
	noise.fractal_gain=0.55
	var height := noise.get_seamless_image(512,512,false,false,0.1)
	height.convert(Image.FORMAT_RGBA8)
	height.bump_map_to_normal_map(6.0)
	height.save_png(OUT+"water_normal.png")
	var cloud := FastNoiseLite.new()
	cloud.noise_type=FastNoiseLite.TYPE_PERLIN
	cloud.seed=44
	cloud.frequency=0.012
	cloud.fractal_octaves=5
	var cells := FastNoiseLite.new()
	cells.noise_type=FastNoiseLite.TYPE_CELLULAR
	cells.seed=5
	cells.frequency=0.03
	cells.cellular_return_type=FastNoiseLite.RETURN_DISTANCE2_DIV
	var a := cloud.get_seamless_image(512,512,false,false,0.1)
	var b := cells.get_seamless_image(512,512,false,false,0.1)
	var mix := Image.create_empty(512,512,false,Image.FORMAT_RGB8)
	for y in range(512):
		for x in range(512):
			mix.set_pixel(x,y,Color(a.get_pixel(x,y).r,b.get_pixel(x,y).r,0))
	mix.save_png(OUT+"noise.png")
