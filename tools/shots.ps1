# Renders the game from fixed poses. Usage: tools\shots.ps1 <out_dir> [pose ...]
param([string]$Out, [Parameter(ValueFromRemainingArguments = $true)][string[]]$Poses)
$g = "C:\Users\virgo\Downloads\Godot_v4.7.2-stable_win64_console.exe"
New-Item -ItemType Directory -Force $Out | Out-Null
$argList = "--path `".`" --resolution 1280x720 --script res://tools/shot.gd -- `"$Out`" $($Poses -join ' ')"
$p = Start-Process $g -ArgumentList $argList -NoNewWindow -PassThru -RedirectStandardOutput "$Out\out.txt" -RedirectStandardError "$Out\err.txt"
if (-not $p.WaitForExit(90000)) { $p.Kill(); "TIMEOUT" }
Get-Content "$Out\out.txt" | Select-String 'SHOT|SCRIPT ERROR|SHADER ERROR|Parse Error'
Get-Content "$Out\err.txt" | Where-Object { $_ -notmatch 'PagedAllocator|Leaked instance|utilities.cpp|ObjectDB|resources still|object.cpp|resource.cpp' } | Select-Object -First 40

