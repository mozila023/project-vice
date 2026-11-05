param([string]$BuildDirectory='build/refined-web')
$ErrorActionPreference='Stop'
$projectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$buildRoot=[IO.Path]::GetFullPath((Join-Path $projectRoot $BuildDirectory))
if(-not $buildRoot.StartsWith($projectRoot+[IO.Path]::DirectorySeparatorChar)){throw 'Build must be inside this project'}
if(-not (Test-Path -LiteralPath (Join-Path $buildRoot 'index.pck'))){throw 'Export the Web build first'}
$deployRoot=Join-Path $projectRoot 'build/publish-original'
New-Item -ItemType Directory -Force -Path $deployRoot | Out-Null
foreach($file in Get-ChildItem -LiteralPath $buildRoot -File){Copy-Item -LiteralPath $file.FullName -Destination $deployRoot -Force}
$source=(git -C $projectRoot rev-parse HEAD).Trim()
$htmlPath=Join-Path $deployRoot 'index.html'
$html=[IO.File]::ReadAllText($htmlPath)
# Preserve the original URLs. Revalidate the pack so returning players receive the update.
$cachePolicy=@'
const fetchGameResource = window.fetch.bind(window);
window.fetch = function(input, options) {
    const url = typeof input === 'string' ? input : (input.url || '');
    return fetchGameResource(input, /\.pck(?:$|\?)/.test(url) ? {...options, cache: 'reload'} : options);
};
const engine = new Engine(GODOT_CONFIG);
'@
$html=$html.Replace('const engine = new Engine(GODOT_CONFIG);',$cachePolicy)
$html=$html.Replace('<head>',('<head>'+"`n"+'<meta name="game-source-commit" content="'+$source+'">'))
[IO.File]::WriteAllText($htmlPath,$html,[Text.UTF8Encoding]::new($false))
$version=@{commit=$source;pack='index.pck';pack_bytes=(Get-Item -LiteralPath (Join-Path $deployRoot 'index.pck')).Length}
[IO.File]::WriteAllText((Join-Path $deployRoot 'version.json'),($version|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
foreach($name in @('ASSET_CREDITS.md','ELLUK_UPDATE.md','MODEL_REFINEMENT.md')){Copy-Item -LiteralPath (Join-Path $projectRoot $name) -Destination $deployRoot -Force}
$previousIndex=$env:GIT_INDEX_FILE
try {
    git -C $projectRoot fetch origin gh-pages
    if($LASTEXITCODE -ne 0){throw 'Fetch failed'}
    $env:GIT_INDEX_FILE=Join-Path $projectRoot 'build/publish-original.index'
    git -C $projectRoot read-tree origin/gh-pages
    if($LASTEXITCODE -ne 0){throw 'Deployment index failed'}
    foreach($file in Get-ChildItem -LiteralPath $deployRoot -File){
        $blob=(git -C $projectRoot hash-object -w -- $file.FullName).Trim()
        if($LASTEXITCODE -ne 0){throw 'Storing build file failed'}
        git -C $projectRoot update-index --add --cacheinfo "100644,$blob,$($file.Name)"
        if($LASTEXITCODE -ne 0){throw 'Staging build file failed'}
    }
    $tree=(git -C $projectRoot write-tree).Trim()
    $parent=(git -C $projectRoot rev-parse origin/gh-pages).Trim()
    $commit=(git -C $projectRoot commit-tree $tree -p $parent -m "Update original Web game files from $($source.Substring(0,7))").Trim()
    if($LASTEXITCODE -ne 0){throw 'Deployment commit failed'}
    git -C $projectRoot push origin "${commit}:refs/heads/gh-pages"
    if($LASTEXITCODE -ne 0){throw 'Deployment push failed'}
    Write-Output "DEPLOY=$commit SOURCE=$source PACK=index.pck"
} finally {$env:GIT_INDEX_FILE=$previousIndex}
