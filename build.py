from pathlib import Path
import re, subprocess, struct, zlib, json, hashlib, shutil, os
import xml.etree.ElementTree as ET
R=Path(__file__).resolve().parent
GAME=Path(os.environ.get('CS2_ROOT','D:/SteamLibrary/steamapps/common/Counter-Strike Global Offensive'))
base=R/'build/baseline/panorama'
src=R/'build/content/csgo'
out=R/'build/game/csgo'
out.mkdir(parents=True,exist_ok=True)
files={}
s=(base/'layout/hud/hud.xml').read_text()
a='<CSGOHudRadar id="HudRadar" />';b='<CSGOHudDeathNotice id="HudDeathNotice" />'
assert s.count(a)==s.count(b)==1
s=s.replace(a,'__SWAP__').replace(b,a).replace('__SWAP__',b)
files['layout/hud/hud.vxml']=s
files['styles/hud/hudradar.vcss']=(base/'styles/hud/hudradar.css').read_text()+'\n/* Standalone HUD layout */\n.hud-radar { horizontal-align: right; }\n'
files['styles/hud/huddeathnotice.vcss']=(base/'styles/hud/huddeathnotice.css').read_text()+'''\n/* Standalone HUD layout */
CSGOHudDeathNotice { horizontal-align: left; height: fit-children; margin-top: 72px; padding-right: 0px; padding-left: 10px; }
#VisibleNotices { horizontal-align: left; height: fit-children; }
.DeathNotice { horizontal-align: left; }
'''
s=(base/'layout/teamselectmenu.xml').read_text()
m=re.search(r'(<Button id="BtnSelectTeam-TERRORIST".*?</Button>)(\s*)(<Button id="BtnSelectTeam-CT".*?</Button>)',s,re.S)
assert m
def flip(x):return x.replace('horizontal-align-left','__LEFT__').replace('horizontal-align-right','horizontal-align-left').replace('__LEFT__','horizontal-align-right')
s=s[:m.start()]+flip(m[3])+m[2]+flip(m[1])+s[m.end():]
files['layout/teamselectmenu.vxml']=s
files['styles/hud_perfstats_basics.vcss']=(base/'styles/hud_perfstats_basics.css').read_text()+'''\n/* Standalone HUD: telemetry follows the kill-feed corner. */
HudPerfStatsBasics { horizontal-align: left; margin-left: 8px; margin-right: 0px; }
#fps_row, #net_numbers_basic, #net_numbers_detailed, #trueview_row { horizontal-align: left; }
'''
for rel,s in files.items():
 p=src/'panorama'/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s)
 if p.suffix=='.vxml':ET.fromstring(s)
 installed=GAME/'content/csgo_addons/cs2_hud_layout_build/panorama'/rel
 installed.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,installed)
 result=subprocess.run([str(GAME/'game/bin/win64/resourcecompiler.exe'),'-i',str(installed),'-game',str(GAME/'game/csgo'),'-addon','cs2_hud_layout_build','-nop4'],capture_output=True,text=True)
 compiled=GAME/'game/csgo_addons/cs2_hud_layout_build/panorama'/(rel+'_c')
 target=out/'panorama'/(rel+'_c');target.parent.mkdir(parents=True,exist_ok=True)
 if compiled.is_file():shutil.copy2(compiled,target)
 (R/'build'/ (p.name+'.log')).write_text(result.stdout+result.stderr)
 if result.returncode or not (out/'panorama'/(rel+'_c')).is_file():raise RuntimeError('Compile failed: '+rel)
# VPK v2, embedded archive, CRC per entry and package MD5 integrity block.
tree=bytearray();data=bytearray()
paths=[out/'panorama'/(rel+'_c') for rel in files]
for ext in sorted({p.suffix[1:] for p in paths}):
 tree.extend(ext.encode()+b'\0')
 for folder in sorted({p.parent.relative_to(out).as_posix() for p in paths if p.suffix[1:]==ext}):
  tree.extend(folder.encode()+b'\0')
  for p in sorted(p for p in paths if p.suffix[1:]==ext and p.parent.relative_to(out).as_posix()==folder):
   raw=p.read_bytes();tree.extend(p.stem.encode()+b'\0');tree.extend(struct.pack('<IHHIIH',zlib.crc32(raw),0,0x7fff,len(data),len(raw),0xffff));data.extend(raw)
  tree.extend(b'\0')
 tree.extend(b'\0')
tree.extend(b'\0')
packed=struct.pack('<7I',0x55aa1234,2,len(tree),len(data),0,48,0)+tree+data
packed+=hashlib.md5(tree).digest()+hashlib.md5(b'').digest()
packed+=hashlib.md5(packed).digest()
(R/'hud_layout.vpk').write_bytes(packed)
(R/'build/manifest.json').write_text(json.dumps({p.relative_to(out).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},indent=2))
print('Compiled and packed',len(files),'UI resources:',R/'hud_layout.vpk')
