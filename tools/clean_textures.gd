extends SceneTree
## Makes neutral, paintable wall textures:  godot --headless --path . --script res://tools/clean_textures.gd
## Building colour comes from vertex paint, so the texture must carry surface grain only. The source photos have
## strong tints and large stains that would otherwise show through every coat of paint on every building.

const DIR := "res://assets/environment/"
## output name: [source, target brightness 0..1, how much surface detail to keep]
const JOBS := {
	"clean_plaster": ["white_plaster_rough_01",0.86,0.55],
	"clean_planks": ["white_planks_clean",0.86,1.0],
	"clean_concrete": ["concrete_floor_worn_001",0.72,0.6],
}

func _initialize() -> void:
	for output in JOBS:
		var job: Array=JOBS[output]
		var image := Image.load_from_file(ProjectSettings.globalize_path(DIR+job[0]+"_Diffuse.jpg"))
		image.convert(Image.FORMAT_RGB8)
		# Broad stains live in the low frequencies: subtract a heavily blurred copy and keep the fine grain.
		var broad := image.duplicate()
		broad.resize(24,24,Image.INTERPOLATE_BILINEAR)
		broad.resize(image.get_width(),image.get_height(),Image.INTERPOLATE_CUBIC)
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var detail: float=image.get_pixel(x,y).get_luminance()-broad.get_pixel(x,y).get_luminance()
				var value: float=clampf(job[1]+detail*job[2],0.0,1.0)
				image.set_pixel(x,y,Color(value,value*0.995,value*0.98))
		image.save_jpg(ProjectSettings.globalize_path(DIR+output+"_Diffuse.jpg"),0.93)
		print("CLEAN ",output)
	quit()
