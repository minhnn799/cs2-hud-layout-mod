# CS2 HUD Layout — standalone mod

Moves radar to the upper right and kill feed to the upper left. Team selection
shows CT on the left and T on the right, including the 3D preview positions. Telemetry moves to the upper left, above the kill feed. Team button IDs and selection handlers
are preserved. No weapon, team color, logo, loadout, animation or defusal changes.

## Install

1. Extract the entire ZIP. Keep the EXE, Loader.ps1, VPK and checksum together.
2. Close CS2 and restore any other active mod first. Start Steam.
3. Open CS2-HUD-Layout.exe and choose your Counter-Strike Global Offensive folder.
4. Click Play. This installs the HUD and launches with `-insecure` for local testing.
5. When finished, close CS2 and click Restore before launching stock CS2.

Installation persists until you click Restore; closing the launcher does not
automatically restore files. Backups are under `%LOCALAPPDATA%/CS2HudLayout`.
Open backup locates the backup for the selected installation. If the game updates
while installed, Restore refuses to overwrite an externally changed gameinfo.

## Files changed

- `game/csgo/gameinfo.gi`: adds a prioritized mount for the standalone HUD VPK.
  Its original bytes are backed up and verified before installation.
- `game/csgo/addons/cs2_hud_layout/hud_layout.vpk` and ownership marker: added.
  After restoration these files remain on disk but are not mounted.
- `game/csgo/maps/prefabs/misc/team_select.vpk`: preview character positions reflected horizontally; original backed up and restored. No DLL or stock pak01 archive is edited.

The HUD VPK overrides `panorama/styles/hud_perfstats_basics.vcss_c` plus `panorama/layout/hud/hud.vxml_c`,
`panorama/layout/teamselectmenu.vxml_c`, `panorama/styles/hud/hudradar.vcss_c`
and `panorama/styles/hud/huddeathnotice.vcss_c`.

Built from the locally installed UI on October 24, 2026. UI compilation and VPK
checks are performed; appearance, menu interaction and HUD edge cases still need
in-game verification. Future CS2 UI updates may require rebuilding this mod.
This is an unofficial, vibe-coded (AI-assisted) project, not endorsed by Valve.
Client UI only; no server installation is needed. Windows launcher only.
