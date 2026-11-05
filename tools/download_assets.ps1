$ErrorActionPreference = 'Stop'
$assetRoot = Join-Path $PSScriptRoot '../assets/environment'
New-Item -ItemType Directory -Force -Path $assetRoot | Out-Null
foreach ($asset in @('aerial_beach_01','aerial_grass_rock','rocky_terrain','leafy_grass')) {
    $catalog = Invoke-RestMethod "https://api.polyhaven.com/files/$asset"
    foreach ($map in @('Diffuse','nor_gl')) {
        $entry = $catalog.$map.'1k'.jpg
        if ($null -eq $entry) { throw "No JPG $map for $asset" }
        $target = Join-Path $assetRoot "$asset`_$map.jpg"
        if (-not (Test-Path -LiteralPath $target)) { Invoke-WebRequest -Uri $entry.url -OutFile $target }
        Write-Output "$asset $map : $((Get-Item -LiteralPath $target).Length) bytes"
    }
}
$skyId = 'kloofendal_48d_partly_cloudy_puresky'
$catalog = Invoke-RestMethod "https://api.polyhaven.com/files/$skyId"
if (-not (Test-Path -LiteralPath (Join-Path $assetRoot 'tropical_sky.hdr'))) { Invoke-WebRequest -Uri $catalog.hdri.'1k'.hdr.url -OutFile (Join-Path $assetRoot 'tropical_sky.hdr') }
Write-Output 'Sky downloaded'
$treeCatalog = Invoke-RestMethod 'https://api.polyhaven.com/files/island_tree_01'
foreach ($map in @('leaves_diff','leaves_alpha','branches_diff')) {
    $entry = $treeCatalog.$map.'1k'.jpg
    Invoke-WebRequest -Uri $entry.url -OutFile (Join-Path $assetRoot "island_tree_01_$map.jpg")
    Write-Output "Tree $map downloaded"
}
