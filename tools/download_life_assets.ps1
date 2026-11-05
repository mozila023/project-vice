$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$modelRoot = Join-Path $projectRoot 'assets/models'
New-Item -ItemType Directory -Force -Path $modelRoot | Out-Null
$repo = Invoke-RestMethod 'https://api.github.com/repos/shorepine/kenney/git/trees/main?recursive=1'
$repo | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $modelRoot 'kenney-file-index.json')
$files = @('3d/car/sedan.glb','3d/car/van.glb','3d/car/truck.glb','3d/car/Textures/colormap.png','3d/watercraft/boat-fishing-small.glb','3d/watercraft/boat-row-small.glb','3d/watercraft/Textures/colormap.png','3d/mini-characters/character-male-b.glb','3d/mini-characters/character-male-d.glb','3d/mini-characters/character-female-b.glb','3d/mini-characters/character-female-d.glb','3d/mini-characters/Textures/colormap.png')
foreach ($file in $files) {
    $relative = $file.Substring(3)
    $targetModel = Join-Path $modelRoot $relative
    New-Item -ItemType Directory -Force -Path (Split-Path $targetModel) | Out-Null
    if (Test-Path -LiteralPath $targetModel) { continue }
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/shorepine/kenney/main/$file" -OutFile $targetModel
    Write-Output "Downloaded $relative"
}
$geoRoot = Join-Path $projectRoot 'assets/geography'
New-Item -ItemType Directory -Force -Path $geoRoot | Out-Null
$query = '[out:json][timeout:45];(way["highway"~"^(primary|secondary|tertiary)$"](-17.88,168.10,-17.43,168.68);way["natural"="coastline"](-17.88,168.10,-17.43,168.68);node["place"~"^(city|town|village)$"](-17.88,168.10,-17.43,168.68););out geom;'
$target = Join-Path $geoRoot 'efate-osm.json'
if (-not (Test-Path -LiteralPath $target)) {
    $url = 'https://overpass-api.de/api/interpreter?data=' + [uri]::EscapeDataString($query)
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $target -TimeoutSec 50 -UserAgent 'EfateIslandLife-local-prototype'
}
Write-Output "OSM map downloaded: $((Get-Item -LiteralPath $target).Length) bytes"
foreach ($modelId in @('HMnuH5geEG','jpKRgGDxhk')) {
    $page = Invoke-WebRequest -UseBasicParsing -Uri "https://poly.pizza/m/$modelId"
    $pagePath = Join-Path $modelRoot "$modelId.html"
    [IO.File]::WriteAllText($pagePath,$page.Content)
    $modelUrl = [regex]::Match($page.Content,'https://static\.poly\.pizza/[^"\s<>]+\.glb').Value
    $filename = if ($modelId -eq 'HMnuH5geEG') { 'villager-man.glb' } else { 'villager-woman.glb' }
    $modelPath = Join-Path $modelRoot $filename
    if (-not (Test-Path -LiteralPath $modelPath)) { Invoke-WebRequest -Uri $modelUrl -OutFile $modelPath }
    Write-Output "$filename downloaded"
}
