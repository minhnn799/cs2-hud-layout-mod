param(
 [Parameter(Mandatory=$true)][string]$Cs2Root,
 [Parameter(Mandatory=$true)][string]$Source2ViewerCli,
 [string]$Python='python'
)
$ErrorActionPreference='Stop'
$env:CS2_ROOT=(Resolve-Path -LiteralPath $Cs2Root).Path
$viewer=(Resolve-Path -LiteralPath $Source2ViewerCli).Path
function Checked([string]$exe,[string[]]$arguments){ & $exe @arguments; if($LASTEXITCODE -ne 0){throw "Command failed: $exe"} }
$base=Join-Path $PSScriptRoot 'build\baseline'
New-Item -ItemType Directory -Force $base | Out-Null
Checked $viewer @('-i',"$env:CS2_ROOT\game\csgo\pak01_dir.vpk",'-o',$base,'-d','-f','panorama/layout/hud/hud.vxml_c,panorama/layout/hud/hudradar.vxml_c,panorama/layout/teamselectmenu.vxml_c,panorama/styles/hud/hudradar.vcss_c,panorama/styles/hud/huddeathnotice.vcss_c')
Checked $viewer @('-i',"$env:CS2_ROOT\game\core\pak01_dir.vpk",'-o',$base,'-d','-f','panorama/styles/hud_perfstats_basics.vcss_c,panorama/layout/hud_perfstats_basics.vxml_c')
$scene=Join-Path $PSScriptRoot 'build\team-scene'
Checked $viewer @('-i',"$env:CS2_ROOT\game\csgo\maps\prefabs\misc\team_select.vpk",'-o',$scene,'-d','-f','maps/prefabs/misc/team_select.vmap_c')
Checked "$env:CS2_ROOT\game\bin\win64\dmxconvert.exe" @('-i',$scene,'-o',"$scene.vmap",'-of','vmap','-oe','keyvalues2_flat')
Checked $Python @((Join-Path $PSScriptRoot 'build_scene.py'))
Checked $Python @((Join-Path $PSScriptRoot 'build.py'))
foreach($name in @('hud_layout','team_select')){
 Checked $viewer @('-i',"$PSScriptRoot\$name.vpk",'--vpk_verify')
 (Get-FileHash -LiteralPath "$PSScriptRoot\$name.vpk" -Algorithm SHA256).Hash | Set-Content -LiteralPath "$PSScriptRoot\$name.sha256"
}
Checked "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe" @('/nologo','/target:winexe','/platform:x64','/reference:System.Windows.Forms.dll',"/out:$PSScriptRoot\CS2-HUD-Layout.exe","$PSScriptRoot\Launcher.cs")
New-Item -ItemType Directory -Force "$PSScriptRoot\dist" | Out-Null
$files=@('CS2-HUD-Layout.exe','Loader.ps1','hud_layout.vpk','hud_layout.sha256','team_select.vpk','team_select.sha256','README.md','profiles') | ForEach-Object {Join-Path $PSScriptRoot $_}
Compress-Archive -LiteralPath $files -DestinationPath "$PSScriptRoot\dist\CS2-HUD-Layout.zip" -Force
