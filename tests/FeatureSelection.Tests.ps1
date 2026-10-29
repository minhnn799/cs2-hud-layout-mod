$ErrorActionPreference='Stop'
. "$PSScriptRoot\..\Loader.ps1" -LibraryOnly
$fixture=Join-Path "$PSScriptRoot\..\build" ('fixture-'+[Guid]::NewGuid())
New-Item -ItemType Directory -Force "$fixture\state","$fixture\game\csgo\maps\prefabs\misc" | Out-Null
$script:TestPaths=@{root=$fixture;state="$fixture\state";gi="$fixture\gameinfo.gi";backup="$fixture\state\gameinfo.original.gi";journal="$fixture\state\active.json";mod="$fixture\addon"}
function Paths {return $script:TestPaths}
function Closed {}
$script:SettingsPath="$fixture\features.json"
$folder=[pscustomobject]@{Text=$fixture};$status=[pscustomobject]@{Text=''}
$original="SearchPaths`n{`n Game csgo`n Mod csgo`n}"
[IO.File]::WriteAllText($script:TestPaths.gi,$original)
$scene="$fixture\game\csgo\maps\prefabs\misc\team_select.vpk"
[IO.File]::WriteAllText($scene,'original-scene')
foreach($mask in @(7,3,4,0)){
 $script:FeatureMask=$mask
 Install
 if($mask -eq 0){if(Test-Path $script:TestPaths.journal){throw 'All-off left active journal'}}
 else {
  $journal=Get-Content $script:TestPaths.journal -Raw | ConvertFrom-Json
  if($journal.features -ne $mask){throw 'Wrong features journal'}
  if((Hash "$fixture\addon\hud_layout.vpk") -ne (Hash "$PSScriptRoot\..\profiles\$mask.vpk")){throw 'Wrong profile installed'}
 }
 if($mask -band 4){if((Hash $scene) -ne (Hash "$PSScriptRoot\..\team_select.vpk")){throw 'Team scene missing'}}
 elseif([IO.File]::ReadAllText($scene) -ne 'original-scene'){throw 'Disabled team scene was changed'}
}
if([IO.File]::ReadAllText($script:TestPaths.gi) -ne $original){throw 'All-off failed to restore'}
$script:FeatureMask=2;Install;CloseSession
if([IO.File]::ReadAllText($script:TestPaths.gi) -ne $original){throw 'Feature profile exit restore failed'}
if((Get-Content $script:SettingsPath -Raw | ConvertFrom-Json).mask -ne 3){throw 'Settings were not saved'}
Write-Output 'PASS: all 4 combined selections and old-settings migration, switching installed features, team scene isolation, all-off restore, saved settings, exit restore.'
