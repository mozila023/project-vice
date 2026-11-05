# OpenStreetMap data  contributors, ODbL. Named places, not an architectural or business-hours survey.
$ErrorActionPreference='Stop'
$dir=Join-Path $PSScriptRoot '.cache/island-survey'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$box='-17.85,168.10,-17.40,168.62'
$query="[out:json][timeout:120];(nwr[`"name`"][`"amenity`"]($box);nwr[`"name`"][`"tourism`"]($box);nwr[`"name`"][`"shop`"]($box);nwr[`"place`"]($box);nwr[`"name`"][`"natural`"~`"beach|waterfall|peak|spring|cave_entrance`"]($box);nwr[`"aeroway`"=`"aerodrome`"]($box);nwr[`"name`"][`"harbour`"]($box););out tags center;"
Invoke-WebRequest 'https://overpass-api.de/api/interpreter' -Method Post -Body @{data=$query} -OutFile (Join-Path $dir 'efate-pois.json') -TimeoutSec 150 -UserAgent 'ProjectVice-island-survey/1.0'
Write-Output 'Run node tools/build_island_survey.mjs to build the attributed island inventory.'
