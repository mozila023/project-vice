extends SceneTree
## Regenerate the Blender aerial input from the game's authoritative baked heights.
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://tools/.cache/island-expansion")
	var baked: Dictionary=bytes_to_var(FileAccess.get_file_as_bytes("res://assets/baked/world.dat"))
	var file := FileAccess.open("res://tools/.cache/island-expansion/terrain.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"heights":Array(baked.heights),"n":243,"step":12,"min":-1452}))
	print("Aerial terrain input exported")
	quit()
