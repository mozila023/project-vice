# Downloads the detailed Efate OpenStreetMap extract used by tools/process_geography.mjs (data (c) OSM contributors, ODbL).
$ErrorActionPreference = 'Stop'
$dir = Join-Path $PSScriptRoot '.cache\osm-detail'
New-Item -ItemType Directory -Force $dir | Out-Null
$box = '-17.85,168.10,-17.40,168.62'
$query = "[out:json][timeout:170];" +
	"(way[`"highway`"~`"^(motorway|trunk|primary|secondary|tertiary|unclassified|residential|living_street|service|track)(_link)?`$`"]($box);)->.r;.r out tags geom;" +
	"(way[`"building`"]($box);)->.b;.b out tags center;" +
	"(way[`"landuse`"~`"^(residential|commercial|retail|industrial|farmland|orchard|meadow|forest)`$`"]($box);" +
	"way[`"natural`"~`"^(wood|scrub|beach|wetland)`$`"]($box);way[`"leisure`"=`"park`"]($box);way[`"aeroway`"~`"^(runway|aerodrome|apron)`$`"]($box);)->.l;.l out tags geom;" +
	"node[`"shop`"]($box);out body;"
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri 'https://overpass-api.de/api/interpreter' -Method Post -Body @{ data = $query } -UserAgent 'ProjectVice-map-bake/1.0' -OutFile (Join-Path $dir 'efate-detail.json') -TimeoutSec 190 -UseBasicParsing
