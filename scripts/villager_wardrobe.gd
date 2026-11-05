extends RefCounted
## Per-instance fabric materials: imported mesh and animations stay shared.
const SHIRTS := ["e6b450","3d8f91","d87965","e5dfc8","668dc0","b18bb5","91aa65","cc6947","e2bd9c","567976","a94960","839bc4"]
const TROUSERS := ["344458","c7ad82","514842","55654b","35495c","7d5864"]

static func dress(root: Node3D,index: int) -> void:
	for mesh: MeshInstance3D in root.find_children("*","MeshInstance3D",true,false):
		for surface in range(mesh.mesh.get_surface_count()):
			var original=mesh.get_active_material(surface)
			if not original is StandardMaterial3D: continue
			var slot: String=original.resource_name.to_lower()
			if not slot in ["shirt","pants","socks","shoes"]: continue
			var fabric: StandardMaterial3D=original.duplicate()
			fabric.albedo_color=Color(SHIRTS[index%SHIRTS.size()] if slot=="shirt" else TROUSERS[index%TROUSERS.size()])
			fabric.roughness=0.92
			fabric.metallic=0.0
			if slot=="shirt":
				var image := Image.create(64,64,false,Image.FORMAT_RGB8)
				var base := fabric.albedo_color
				for y in range(64):
					for x in range(64):
						var accent: bool=(y%16<3) if index%3==0 else ((x%16<2 or y%16<2) if index%3==1 else false)
						image.set_pixel(x,y,base.lightened(0.32) if accent else base)
				fabric.albedo_color=Color.WHITE
				fabric.albedo_texture=ImageTexture.create_from_image(image)
				fabric.uv1_triplanar=true
				fabric.uv1_scale=Vector3.ONE*2.0
			mesh.set_surface_override_material(surface,fabric)
