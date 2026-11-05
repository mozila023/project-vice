extends RefCounted
## Shared measured-scale photographic materials, using the existing credited texture library.
var cache := {}
func material(key: String,color := Color.WHITE) -> StandardMaterial3D:
	var id := key+color.to_html()
	if cache.has(id): return cache[id]
	var mat := StandardMaterial3D.new()
	var textures := {"plaster":"clean_plaster","concrete":"clean_concrete","wood":"weathered_planks","roof":"worn_corrugated_iron","sandstone":"rocky_terrain"}
	mat.albedo_color=color
	mat.roughness=.88
	if textures.has(key):
		var path: String="res://assets/environment/"+textures[key]
		mat.albedo_texture=load(path+"_Diffuse.jpg")
		mat.normal_enabled=true
		var normal_file: String={"plaster":"white_plaster_rough_01","concrete":"concrete_floor_worn_001"}.get(key,textures[key])
		mat.normal_texture=load("res://assets/environment/"+normal_file+"_nor_gl.jpg")
		mat.normal_scale=.35 if key=="plaster" else .55
		mat.uv1_triplanar=true
		mat.uv1_world_triplanar=true
		mat.uv1_scale=Vector3.ONE*(.7 if key=="roof" else .4)
		mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if key in ["glass","water"]:
		mat.roughness=.16 if key=="glass" else .12
		mat.metallic_specular=.5
	if key=="glass" and color.a<.99:
		mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	if key=="roof": mat.roughness=.65; mat.metallic=.1
	if key=="steel": mat.roughness=.55; mat.metallic=.2
	cache[id]=mat
	return mat
func polish(root: Node3D) -> void:
	for node: MeshInstance3D in root.find_children("*","MeshInstance3D",true,false):
		if node.mesh==null: continue
		for i in range(node.mesh.get_surface_count()):
			var old: Material=node.get_active_material(i)
			if not old is StandardMaterial3D: continue
			var name: String=old.resource_name.to_lower()
			var key := ""
			if name.contains("cream") or name.contains("plaster") or name=="paint" or name=="board": key="plaster"
			elif name.contains("roof") or name=="iron": key="roof"
			elif name.contains("concrete"): key="concrete"
			elif name.contains("wood"): key="wood"
			elif name.contains("sandstone"): key="sandstone"
			elif name in ["glass","water","steel"]: key=name
			if key=="water":
				var water := ShaderMaterial.new()
				water.shader=load("res://shaders/freshwater.gdshader")
				water.set_shader_parameter("normal_tex",load("res://assets/baked/water_normal.png"))
				water.set_shader_parameter("noise_tex",load("res://assets/baked/noise.png"))
				node.set_surface_override_material(i,water)
			elif key!="": node.set_surface_override_material(i,material(key,old.albedo_color))
