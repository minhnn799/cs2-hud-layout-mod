param([string]$LaunchRoot,[switch]$RestoreFirst,[switch]$LibraryOnly,[switch]$TestInstallButton)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$script:LaunchedGame=$null
$script:SessionRoot=$null
function Hash($p) { (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash }
function Closed { if(Get-Process cs2 -ErrorAction SilentlyContinue){throw 'Close CS2 before installing or restoring.'} }
function Paths {
 $root=[IO.Path]::GetFullPath($folder.Text.Trim().Trim('"').Replace('/','\')).TrimEnd('\')
 $gi=Join-Path $root 'game\csgo\gameinfo.gi'
 if(!(Test-Path -LiteralPath $gi)){throw 'Select the Counter-Strike Global Offensive folder.'}
 $sha=[Security.Cryptography.SHA256]::Create()
 try{$key=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($root.ToLowerInvariant())))).Replace('-','').Substring(0,20)}finally{$sha.Dispose()}
 $state=Join-Path $env:LOCALAPPDATA "CS2HudLayout\$key"
 # Older versions hashed trailing separators differently. Recover only a
 # journal proven to describe this installation and its current gameinfo.
 if(!(Test-Path -LiteralPath (Join-Path $state 'active.json'))){
  $currentHash=Hash $gi
  foreach($candidate in @(Get-ChildItem -LiteralPath (Join-Path $env:LOCALAPPDATA 'CS2HudLayout') -Filter active.json -Recurse -ErrorAction SilentlyContinue)){
   $record=Get-Content -LiteralPath $candidate.FullName -Raw | ConvertFrom-Json
   $expectedScene=Join-Path $root 'game\csgo\maps\prefabs\misc\team_select.vpk'
   if($record.sceneTarget -and [IO.Path]::GetFullPath($record.sceneTarget) -eq $expectedScene -and $record.modified -eq $currentHash){$state=$candidate.DirectoryName;break}
  }
 }
 New-Item -ItemType Directory -Force $state | Out-Null
 return @{root=$root;gi=$gi;state=$state;journal=(Join-Path $state 'active.json');backup=(Join-Path $state 'gameinfo.original.gi');mod=(Join-Path $root 'game\csgo\addons\cs2_hud_layout')}
}
function Install {
 Closed; $p=Paths
 $diag=Join-Path $p.state 'install-trace.log'
 Add-Content $diag "$(Get-Date -Format o) journal=$($p.journal) exists=$(Test-Path -LiteralPath $p.journal)"
 if(-not [IO.File]::Exists($p.journal) -and [IO.File]::ReadAllText($p.gi).Contains('cs2_hud_layout')){
  $current=Hash $p.gi
  foreach($archive in [IO.Directory]::GetFiles($p.state,'restored-*.json')){
   $saved=[IO.File]::ReadAllText($archive) | ConvertFrom-Json
   if($saved.modified -ne $current -or (Hash $p.backup) -ne $saved.original){continue}
   if(-not $saved.sceneTarget -or [IO.Path]::GetFullPath($saved.sceneTarget) -ne (Join-Path $p.root 'game\csgo\maps\prefabs\misc\team_select.vpk')){continue}
   if((Hash $saved.sceneBackup) -ne $saved.sceneOriginal){continue}
   $sceneHash=Hash $saved.sceneTarget
   if($sceneHash -ne $saved.sceneOriginal -and $sceneHash -ne $saved.sceneModified){continue}
   [IO.File]::WriteAllText($p.journal,[IO.File]::ReadAllText($archive))
   Add-Content $diag "Recovered matching journal from $archive"
   break
  }
 }
 if([IO.File]::Exists($p.journal)){
  $r=Get-Content -LiteralPath $p.journal -Raw | ConvertFrom-Json
  # Restore verified originals before updating, never back up patched files.
  Restore
  Add-Content $diag "after Restore: journal=$(Test-Path -LiteralPath $p.journal) gameinfo=$(Hash $p.gi)"
  $p=Paths
 }
 $text=[IO.File]::ReadAllText($p.gi)
 if($text -match 'cs2_rebalance_loader'){throw 'The reversed-defusal mod mount is active. Restore that mod first.'}
 if($text -match 'cs2_hud_layout'){throw "HUD Layout is mounted, but its recovery record was not found. Selected root: $($p.root). Recovery folder: $($p.state). Launcher: $PSScriptRoot. Do not delete your backups."}
 if((Test-Path -LiteralPath $p.mod) -and !(Test-Path -LiteralPath (Join-Path $p.mod 'hud-layout-owned.txt'))){throw 'The mod folder already exists and is not owned by this loader.'}
 $vpk=Join-Path $PSScriptRoot 'hud_layout.vpk'
 if((Hash $vpk) -ne (Get-Content (Join-Path $PSScriptRoot 'hud_layout.sha256') -Raw).Trim()){throw 'HUD payload checksum failed.'}
 foreach($type in @('Game','Mod')){
  $pattern='(?m)^(\s*'+$type+'\s+)csgo\s*$'
  if([regex]::Matches($text,$pattern).Count -ne 1){throw 'Unsupported gameinfo search paths.'}
  $prefix=if($type -eq 'Game'){"`t`t`tWrite`tcsgo`r`n"}else{''}
  $replacement=$prefix+"`t`t`t$type`tcsgo/addons/cs2_hud_layout/hud_layout.vpk`r`n"
  $text=[regex]::Replace($text,$pattern,{param($m) $replacement+$m.Value})
 }
 Copy-Item -LiteralPath $p.gi -Destination $p.backup -Force
 if((Hash $p.gi) -ne (Hash $p.backup)){throw 'Backup verification failed.'}
 $staged=Join-Path $p.state 'gameinfo.modified.gi'
 [IO.File]::WriteAllText($staged,$text,(New-Object Text.UTF8Encoding($false)))
 $scene=Join-Path $p.root 'game\csgo\maps\prefabs\misc\team_select.vpk'
 $sceneSource=Join-Path $PSScriptRoot 'team_select.vpk'
 if((Hash $sceneSource) -ne (Get-Content (Join-Path $PSScriptRoot 'team_select.sha256') -Raw).Trim()){throw 'Scene payload checksum failed.'}
 $sceneBackup=Join-Path $p.state 'team_select.original.vpk'
 Copy-Item -LiteralPath $scene -Destination $sceneBackup -Force
 if((Hash $scene) -ne (Hash $sceneBackup)){throw 'Scene backup verification failed.'}
 @{original=(Hash $p.backup);modified=(Hash $staged);sceneTarget=$scene;sceneBackup=$sceneBackup;sceneOriginal=(Hash $sceneBackup);sceneModified=(Hash $sceneSource)} | ConvertTo-Json | Set-Content -LiteralPath $p.journal -Encoding UTF8
 New-Item -ItemType Directory -Force $p.mod | Out-Null
 Set-Content -LiteralPath (Join-Path $p.mod 'hud-layout-owned.txt') -Value 'CS2 HUD Layout'
 Copy-Item -LiteralPath $vpk -Destination (Join-Path $p.mod 'hud_layout.vpk') -Force
 Copy-Item -LiteralPath $staged -Destination $p.gi -Force
 Copy-Item -LiteralPath $sceneSource -Destination $scene -Force
 $script:SessionRoot=$p.root
 $status.Text='Installed. Use Play for local testing. Restore before stock play.'
}
function Restore {
 Closed; $p=Paths
 if(![IO.File]::Exists($p.journal)){$status.Text='No active HUD installation to restore.';return}
 $r=Get-Content -LiteralPath $p.journal -Raw | ConvertFrom-Json
 if((Hash $p.backup) -ne $r.original){throw 'Backup checksum failed; no files changed.'}
 $now=Hash $p.gi
 if($now -ne $r.original -and $now -ne $r.modified){throw 'Gameinfo changed externally. Backup retained; refusing to overwrite it.'}
 if($r.sceneTarget){
  if((Hash $r.sceneBackup) -ne $r.sceneOriginal){throw 'Scene backup checksum failed.'}
  $sceneNow=Hash $r.sceneTarget
  if($sceneNow -ne $r.sceneOriginal -and $sceneNow -ne $r.sceneModified){throw 'Team-selection scene changed externally. Backup retained.'}
  Copy-Item -LiteralPath $r.sceneBackup -Destination $r.sceneTarget -Force
 }
 Copy-Item -LiteralPath $p.backup -Destination $p.gi -Force
 Move-Item -LiteralPath $p.journal -Destination (Join-Path $p.state ('restored-'+[Guid]::NewGuid()+'.json'))
 $status.Text='Original gameinfo restored. HUD addon is now inactive.'
}
function Run($action){try{& $action}catch{
 $detail="$(Get-Date -Format o)`r`nLauncher: $PSScriptRoot`r`nLocalAppData: $env:LOCALAPPDATA`r`nSelected: $($folder.Text)`r`n$($_ | Out-String)`r`n$($_.ScriptStackTrace)"
 $log=Join-Path $env:LOCALAPPDATA 'CS2HudLayout\launcher-error.log'
 New-Item -ItemType Directory -Force (Split-Path $log) | Out-Null
 Add-Content -LiteralPath $log -Value $detail
 if($TestInstallButton){throw}
 [Windows.Forms.MessageBox]::Show($_.Exception.Message,'CS2 HUD Layout 1.4') | Out-Null
}}
function CloseSession {
 if($script:LaunchedGame -and !$script:LaunchedGame.HasExited){
  $status.Text='Closing the game and restoring originals...'
  $null=$script:LaunchedGame.CloseMainWindow()
  if(!$script:LaunchedGame.WaitForExit(5000)){
   $script:LaunchedGame.Kill()
   if(!$script:LaunchedGame.WaitForExit(5000)){throw 'CS2 has not exited. Originals have not been restored yet.'}
  }
 }
 $selected=$folder.Text
 try {
  if($script:SessionRoot){$folder.Text=$script:SessionRoot}
  $p=Paths
  if([IO.File]::Exists($p.journal)){Restore}
 } finally {$folder.Text=$selected}
}
if($LibraryOnly){return}
if($LaunchRoot){
 $folder=[pscustomobject]@{Text=$LaunchRoot};$status=[pscustomobject]@{Text=''}
 if(!(Get-Process steam -ErrorAction SilentlyContinue)){throw 'Start Steam first.'}
 if($RestoreFirst){Restore}
 Install
 $p=Paths
 try {
  $script:LaunchedGame=Start-Process -FilePath (Join-Path $p.root 'game\bin\win64\cs2.exe') -ArgumentList '-insecure -console' -WorkingDirectory $p.root -PassThru
  Write-Output "Launched CS2 PID $($script:LaunchedGame.Id). Backup: $($p.backup)"
  $script:LaunchedGame.WaitForExit()
 } finally {CloseSession}
 exit
}
$form=New-Object Windows.Forms.Form
$form.Text='CS2 HUD Layout 1.4 - standalone';$form.ClientSize=New-Object Drawing.Size(650,190);$form.StartPosition='CenterScreen'
$folder=New-Object Windows.Forms.TextBox;$folder.SetBounds(15,20,525,25);$folder.Text='D:\SteamLibrary\steamapps\common\Counter-Strike Global Offensive';$form.Controls.Add($folder)
$browse=New-Object Windows.Forms.Button;$browse.Text='Browse';$browse.SetBounds(550,18,85,28);$browse.Add_Click({$d=New-Object Windows.Forms.FolderBrowserDialog;if($d.ShowDialog() -eq 'OK'){$folder.Text=$d.SelectedPath}});$form.Controls.Add($browse)
$status=New-Object Windows.Forms.Label;$status.SetBounds(15,110,620,65);$status.Text='Radar right / kill feed left. Team selection: CT left / T right.';$form.Controls.Add($status)
$install=New-Object Windows.Forms.Button;$install.Text='Install';$install.SetBounds(15,65,120,30);$install.Add_Click({Run {Install}});$form.Controls.Add($install)
$play=New-Object Windows.Forms.Button;$play.Text='Play (-insecure)';$play.SetBounds(145,65,150,30);$play.Add_Click({Run {Closed;if(!(Get-Process steam -ErrorAction SilentlyContinue)){throw 'Start Steam first.'};Install;$p=Paths;$script:LaunchedGame=Start-Process -FilePath (Join-Path $p.root 'game\bin\win64\cs2.exe') -ArgumentList '-insecure' -WorkingDirectory $p.root -PassThru;$status.Text='Closing this launcher closes its game and restores originals.'}});$form.Controls.Add($play)
$restore=New-Object Windows.Forms.Button;$restore.Text='Restore';$restore.SetBounds(305,65,120,30);$restore.Add_Click({Run {Restore}});$form.Controls.Add($restore)
$backup=New-Object Windows.Forms.Button;$backup.Text='Open backup';$backup.SetBounds(435,65,120,30);$backup.Add_Click({Run {$p=Paths;Start-Process explorer.exe -ArgumentList ('"'+$p.state+'"')}});$form.Controls.Add($backup)
$form.Add_FormClosing({param($sender,$eventArgs)
 try{CloseSession}catch{$eventArgs.Cancel=$true;[Windows.Forms.MessageBox]::Show("Could not restore originals: "+$_.Exception.Message+"`nClose any separately launched CS2 instance, then try closing again.",'CS2 HUD Layout') | Out-Null}
})
if($TestInstallButton){$form.Add_Shown({$install.PerformClick();Write-Output ("Install button result: "+$status.Text);$form.Close()})}
[Windows.Forms.Application]::EnableVisualStyles()
[Windows.Forms.Application]::Run($form)
