# CS2 HUD Layout — standalone mod

Moves radar to the upper right and kill feed to the upper left. Team selection
shows CT on the left and T on the right, including the 3D preview positions. Telemetry moves to the upper left, above the kill feed. Team button IDs and selection handlers
are preserved. No weapon, team color, logo, loadout, animation or defusal changes.

## Install

1. Extract the entire ZIP. Keep the EXE, Loader.ps1, VPK and checksum together.
2. Close CS2 and restore any other active mod first. Start Steam.
3. Open CS2-HUD-Layout.exe and choose your Counter-Strike Global Offensive folder.
4. Click Play. This installs the HUD and launches with `-insecure` for local testing.
5. When finished, close the launcher. It closes the CS2 process it launched and restores originals automatically. Restore is also available manually with CS2 closed.

Normal launcher exit restores files, including when you used Install without Play.
If CS2 was launched separately, close it first; the launcher will keep its window
open if restoration is blocked. A game launched by this launcher gets five seconds
to exit normally before it is terminated. Force-killing the launcher, a crash or
power loss can prevent cleanup; reopen it and click Restore.
Backups are under `%LOCALAPPDATA%/CS2HudLayout`.
Open backup locates the backup for the selected installation. If the game updates
while installed, Restore refuses to overwrite an externally changed gameinfo.

## Manual installation without the launcher

Close CS2 and restore any existing mod first. All paths below are relative to
your `Counter-Strike Global Offensive` installation directory.

1. Copy the ORIGINAL `game/csgo/gameinfo.gi` and
   `game/csgo/maps/prefabs/misc/team_select.vpk` to a safe backup folder outside
   the game installation. Preserve their folder names so you can identify them.
   Never replace these backups with already modified files.
2. Create `game/csgo/addons/cs2_hud_layout/` and copy the release's
   `hud_layout.vpk` into it.
3. Replace `game/csgo/maps/prefabs/misc/team_select.vpk` with the release's
   `team_select.vpk`.
4. Open `game/csgo/gameinfo.gi` in a text editor. Within `FileSystem` →
   `SearchPaths`, insert the following immediately BEFORE the existing
   `Game csgo` entry. Keep the existing entries:

   ```text
   Write csgo
   Game csgo/addons/cs2_hud_layout/hud_layout.vpk
   ```

   If `Write csgo` already exists, do not duplicate it. Immediately before
   the existing `Mod csgo` entry, insert:

   ```text
   Mod csgo/addons/cs2_hud_layout/hud_layout.vpk
   ```

5. Start Steam, add `-insecure` to CS2's Steam launch options, then launch CS2
   for local testing. This manual install stays active until manually restored.

### Manual removal

Close CS2. Copy BOTH original files from your backup folder back to their exact
paths, replacing the modified files. Remove `-insecure` if you added it solely
for this mod. The added `game/csgo/addons/cs2_hud_layout/` folder can then be
deleted or left inactive. Do not replace updated game files with old-version
backups after a Steam update; Steam's Verify integrity can restore current stock
files instead. Manual installations have no launcher recovery journal: the
launcher's Restore button cannot recover backups you made elsewhere.

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

October 25 update: telemetry ping text has leading whitespace trimmed; team-selection camera moved back 32 units to widen framing. The FIRST HALF intro is unchanged. The HUD package also adds panorama/layout/hud_perfstats_basics.vxml_c and panorama/scripts/hud_layout_telemetry.vjs_c. Both fixes are compiled and archive-verified; in-game appearance still needs confirmation.

