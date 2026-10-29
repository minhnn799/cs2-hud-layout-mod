$ErrorActionPreference='Stop'
. "$PSScriptRoot\..\Loader.ps1" -LibraryOnly
$fixture=Join-Path "$PSScriptRoot\..\build" ('hud-exit-test-'+[Guid]::NewGuid())
New-Item -ItemType Directory $fixture | Out-Null
$script:TestPaths=@{root=$fixture;state=$fixture;gi=(Join-Path $fixture 'gameinfo.gi');backup=(Join-Path $fixture 'original.gi');journal=(Join-Path $fixture 'active.json')}
function Paths {return $script:TestPaths}
function Closed {}
$folder=[pscustomobject]@{Text=$fixture};$status=[pscustomobject]@{Text=''}
function Seed {
 [IO.File]::WriteAllText($script:TestPaths.gi,'modified')
 [IO.File]::WriteAllText($script:TestPaths.backup,'original')
 @{original=(Hash $script:TestPaths.backup);modified=(Hash $script:TestPaths.gi)} | ConvertTo-Json | Set-Content $script:TestPaths.journal
}
Seed
CloseSession
if([IO.File]::ReadAllText($script:TestPaths.gi) -ne 'original' -or (Test-Path $script:TestPaths.journal)){throw 'Install-only exit restoration failed'}
CloseSession
Seed
$script:LaunchedGame=[pscustomobject]@{HasExited=$false;Closed=$false;Killed=$false}
$script:LaunchedGame | Add-Member ScriptMethod CloseMainWindow {$this.Closed=$true;return $true}
$script:LaunchedGame | Add-Member ScriptMethod WaitForExit {param($ms) return $this.Killed}
$script:LaunchedGame | Add-Member ScriptMethod Kill {$this.Killed=$true;$this.HasExited=$true}
CloseSession
if(!$script:LaunchedGame.Closed -or !$script:LaunchedGame.Killed -or (Test-Path $script:TestPaths.journal)){throw 'Owned-game shutdown/restore failed'}
$script:LaunchedGame=$null
Seed
[IO.File]::WriteAllText($script:TestPaths.gi,'external-update')
$blocked=$false
try {CloseSession}catch {$blocked=$true}
if(!$blocked -or [IO.File]::ReadAllText($script:TestPaths.gi) -ne 'external-update' -or !(Test-Path $script:TestPaths.journal)){throw 'External-change protection failed'}
Write-Output 'PASS: install-only exit, repeated exit, owned-process termination, external-change refusal. Temporary fixtures only.'
