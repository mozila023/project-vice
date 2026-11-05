$ErrorActionPreference = 'Stop'
# All assets are CC0 from Poly Haven (https://polyhaven.com).
# Textures ship with the game. Source models are heavy and only used offline by tools/bake_impostors.gd.
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$envDir = Join-Path $root 'assets/environment'
$srcDir = Join-Path $root 'tools/.cache/polyhaven'
New-Item -ItemType Directory -Force -Path $envDir, $srcDir | Out-Null

function Get-Texture($id) {
	$catalog = Invoke-RestMethod "https://api.polyhaven.com/files/$id"
	foreach ($map in @('Diffuse', 'nor_gl')) {
		$target = Join-Path $envDir "$id`_$map.jpg"
		if (Test-Path -LiteralPath $target) { continue }
		$entry = $catalog.$map.'1k'.jpg
		if ($null -eq $entry) { throw "No 1k $map for $id" }
		Invoke-WebRequest -UseBasicParsing -Uri $entry.url -OutFile $target
	}
	Write-Output "texture $id"
}

function Get-Model($id) {
	$dir = Join-Path $srcDir $id
	New-Item -ItemType Directory -Force -Path $dir | Out-Null
	$entry = (Invoke-RestMethod "https://api.polyhaven.com/files/$id").gltf.'1k'.gltf
	$gltf = Join-Path $dir "$id.gltf"
	if (-not (Test-Path -LiteralPath $gltf)) { Invoke-WebRequest -UseBasicParsing -Uri $entry.url -OutFile $gltf }
	foreach ($item in $entry.include.PSObject.Properties) {
		$target = Join-Path $dir ($item.Name -replace '/', '\')
		New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
		if (-not (Test-Path -LiteralPath $target)) { Invoke-WebRequest -UseBasicParsing -Uri $item.Value.url -OutFile $target }
	}
	Write-Output "model $id"
}

foreach ($id in @('worn_corrugated_iron', 'rusty_corrugated_iron', 'white_planks_clean', 'white_plaster_rough_01', 'asphalt_02', 'weathered_planks', 'concrete_floor_worn_001', 'coast_sand_01', 'forest_leaves_02')) { Get-Texture $id }
foreach ($id in @('island_tree_01', 'island_tree_02', 'shrub_02', 'shrub_04', 'fern_02', 'calathea_orbifolia_01', 'grass_medium_02')) { Get-Model $id }


