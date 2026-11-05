$ErrorActionPreference='Stop'
$projectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$folder=Join-Path $projectRoot 'tools/.cache/update-refs'
New-Item -ItemType Directory -Force -Path $folder | Out-Null
$tree=Invoke-RestMethod 'https://api.github.com/repos/microsoft/Microsoft-Rocketbox/git/trees/master?recursive=1'
$runs=$tree.tree | Where-Object { $_.path -match '(run|jog).*\.fbx$' }
$runs | Select-Object -First 30 -ExpandProperty path
$tree | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $folder 'rocketbox-files.json')
foreach($gender in @('m','f')) {
    $assetPath="Assets/Animations/all_animations_max_motextr_xy/$gender`_run_neutral.max.fbx"
    $outFile=Join-Path $projectRoot "assets/models/people/$gender`_run_neutral.max.fbx"
    if(-not (Test-Path -LiteralPath $outFile)) {
        Invoke-WebRequest -Uri ('https://raw.githubusercontent.com/microsoft/Microsoft-Rocketbox/master/'+$assetPath) -OutFile $outFile
    }
    Write-Output "$gender run downloaded"
}
$map=Invoke-WebRequest -UseBasicParsing -Uri 'https://maps.app.goo.gl/JuCx9DdzMiA2VwCT9'
[IO.File]::WriteAllText((Join-Path $folder 'padthai-map.html'),$map.Content)
Write-Output ('MAP URL '+$map.BaseResponse.ResponseUri.AbsoluteUri)
$page=Invoke-WebRequest -UseBasicParsing -Uri 'https://wanderlog.com/place/details/7493908'
[IO.File]::WriteAllText((Join-Path $folder 'padthai-references.html'),$page.Content)
Write-Output 'References saved'
foreach($key in @('rTzPmXAZTRtJrzsWznhW2tX3pM3OxgEG','qUiwSSJ5cVDIfQXUMj18kscEE4fDbILo','qLGLDby0VNjvG6AgydZooYVGTacmeu98')) {
    Invoke-WebRequest -Uri "https://itin-dev.wanderlogstatic.com/freeImage/$key" -OutFile (Join-Path $folder "$key.jpg")
    Write-Output "Photo $key"
}
