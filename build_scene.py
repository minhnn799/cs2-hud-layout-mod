from pathlib import Path
import re,subprocess,shutil,json,hashlib,os
R=Path(__file__).resolve().parent
G=Path(os.environ.get('CS2_ROOT','D:/SteamLibrary/steamapps/common/Counter-Strike Global Offensive'))
s=(R/'build/team-scene.vmap').read_text()
blocks=list(re.finditer(r'^"([^"\n]+)"\n\{.*?^\}',s,re.M|re.S))
def val(b,k):
 m=re.search(r'"'+k+r'" "[^"\n]+" "([^"\n]*)"',b);return m[1] if m else None
props={val(m[0],'id'):m[0] for m in blocks if m[1]=='EditGameClassProps'}
changes=[]
def edit(m):
 b=m[0]
 if m[1]!='CMapEntity':return b
 p=props.get(val(b,'entity_properties'),'')
 if val(p,'classname') not in ('team_select_counterterrorist','team_select_terrorist'):return b
 origin=list(map(float,val(b,'origin').split()));angles=list(map(float,val(b,'angles').split()))
 old=origin[:];origin[0]=2*(-24.7502441406)-origin[0];angles[1]=(180-angles[1])%360
 for k,v in [('origin',origin),('angles',angles)]:
  b=re.sub(r'("'+k+r'" "[^"\n]+" ")[^"]+"',lambda x:x[1]+' '.join(map(str,v))+'"',b)
 changes.append({'team':val(p,'classname'),'before':old,'after':origin})
 return b
s=re.sub(r'^"([^"\n]+)"\n\{.*?^\}',edit,s,flags=re.M|re.S)
assert len(changes)==20,len(changes)
p=G/'content/csgo_addons/cs2_hud_layout_build/maps/prefabs/misc/team_select.vmap'
p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s)
r=subprocess.run([str(G/'game/bin/win64/resourcecompiler.exe'),'-i',str(p),'-game',str(G/'game/csgo'),'-addon','cs2_hud_layout_build','-nop4','-world','-phys'],capture_output=True,text=True)
(R/'build/scene-compile.log').write_text(r.stdout+r.stderr)
if r.returncode:raise RuntimeError('Scene compile failed')
shutil.copy2(G/'game/csgo_addons/cs2_hud_layout_build/maps/prefabs/misc/team_select.vpk',R/'team_select.vpk')
(R/'build/scene-changes.json').write_text(json.dumps(changes,indent=2))
print('Compiled reflected preview positions:',len(changes))
