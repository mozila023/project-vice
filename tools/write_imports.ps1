$ErrorActionPreference = 'Stop'
# Godot only auto-picks 3D texture settings inside the editor. These stubs make command-line imports
# produce GPU-compressed, mipmapped textures for both desktop (S3TC) and phones (ETC2/ASTC).
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

function Write-Stub($file, $mode, $mipmaps, $normal, $sizeLimit, $highQuality = 'false') {
	$text = @"
[remap]

importer="texture"
type="CompressedTexture2D"

[params]

compress/mode=$mode
compress/high_quality=$highQuality
compress/lossy_quality=0.8
compress/hdr_compression=1
compress/normal_map=$normal
compress/channel_pack=0
mipmaps/generate=$mipmaps
mipmaps/limit=-1
roughness/mode=0
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/size_limit=$sizeLimit
detect_3d/compress_to=0
"@
	[IO.File]::WriteAllText("$file.import", $text)
}

Get-ChildItem (Join-Path $root 'assets/environment') -Filter *.jpg | ForEach-Object {
	if ($_.Name -match '^(asphalt|worn_corrugated|rusty_corrugated).*_nor_gl') { Write-Stub $_.FullName 2 true 1 1024 }
	elseif ($_.Name -match '_nor_gl') { Write-Stub $_.FullName 2 true 1 512 }
	elseif ($_.Name -match '^(leafy_grass|coast_sand|rocky_terrain|forest_leaves)') { Write-Stub $_.FullName 2 true 0 0 }
	else { Write-Stub $_.FullName 2 true 0 1024 }
}
$baked = Join-Path $root 'assets/baked'
foreach ($name in 'foliage_trees', 'foliage_ground', 'palm_frond', 'palm_bark') { Write-Stub (Join-Path $baked "$name.png") 2 true 0 0 }
# Soft colour gradients: the higher quality block format avoids visible banding and blocks from the air.
Write-Stub (Join-Path $baked 'terrain_macro.png') 2 true 0 0 'true'
Write-Stub (Join-Path $baked 'water_normal.png') 2 true 1 0
# Data maps must stay exact: lossless. The elevation channel drives the shoreline.
Write-Stub (Join-Path $baked 'terrain_data.png') 0 false 0 0
Write-Stub (Join-Path $baked 'noise.png') 0 true 0 0

