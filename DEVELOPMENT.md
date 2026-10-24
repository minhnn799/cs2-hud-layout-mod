# Building and publishing

This repository tracks mod/launcher source, not extracted Valve assets or compiled
packages. Build against your own CS2 installation with Workshop Tools installed.
Restore this mod before rebuilding: the stock team-selection scene is an input.

Requirements: Windows, Python 3, Source 2 Viewer CLI (20.1 was used), CS2 Workshop
Tools, and the Windows .NET Framework C# compiler.

```powershell
.\Build-Release.ps1 -Cs2Root 'D:\SteamLibrary\steamapps\common\Counter-Strike Global Offensive' -Source2ViewerCli 'C:\Tools\Source2Viewer-CLI.exe' -Python python
```

The build extracts inputs under `build/` and compiles in the separate
`cs2_hud_layout_build` Workshop addon. It does not install the resulting mod.
The ZIP is written under `dist/`. Game updates may require changes to the
transformations. The build script is source-ready; a clean-machine end-to-end
build has not been tested. Current runtime visuals still need user verification.

Create an empty GitHub repository, then add its URL as `origin` and push `main`.
Attach the ZIP to a GitHub Release; do not commit build directories, game files,
backups, or local profiles. Review the release contents before publishing.

No license has been selected for the project yet. Valve assets remain Valve's
or their respective creators' property; this repository grants no rights to them.
