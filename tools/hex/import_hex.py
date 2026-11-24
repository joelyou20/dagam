#!/usr/bin/env python3
"""Import the pure battle engine/catalogue and full-resolution card assets from LifestyleTracker.
Usage: python tools/hex/import_hex.py /path/to/lifestyleTracker-repo
No economy, lifestyle data, progression or other game modes are imported.
"""
import hashlib,json,re,shutil,subprocess,sys
from pathlib import Path
S=Path(sys.argv[1]);D=Path(__file__).resolve().parents[2]
files=['hex-formats','hex-engine','hex-effects','hex-resolve','hex-arcana','hex-elderberry','hex-ai','hex-ai-ascended','hex-opponents']
manifest={'repository':'https://github.com/joelyou20/lifestyleTracker','revision':subprocess.check_output(['git','-C',str(S),'rev-parse','HEAD'],text=True).strip(),'files':{},'assets':{}}
cards=[]
for name in ['first-light','shattered-arcana','war-on-elderberry']:
 data=json.loads((S/f'catalog/hex/{name}.json').read_text());cards+=data['cards']
(D/'Resources/Hex/Data/cards.json').write_text(json.dumps(cards,indent=2)+'\n')
shutil.copy(S/'catalog/hex/keywords.json',D/'Resources/Hex/Data/keywords.json')
ir=json.loads((S/'catalog/hex/illustration-rares.json').read_text())['cards']
(D/'Resources/Hex/Data/illustration-rares.json').write_text(json.dumps(ir)+'\n')
for name in files:
 p=S/f'js/core/{name}.js';s=p.read_text()
 if name=='hex-engine':s=s.replace('hexChallengePlayed(g,p,c);','')
 if name=='hex-formats':
  s=s.replace(",blitz:{id:'blitz',name:'Blitz',deckSize:10,opening:5,columns:2,slots:4,artifactSlots:1,losses:3,minCreatures:0}",'').replace("HEX_FORMATS[id==='blitz'?'blitz':'standard']","HEX_FORMATS.standard")
 (D/f'Resources/Hex/Engine/{name}.js').write_text(s);manifest['files'][str(p.relative_to(S))]=hashlib.sha256(p.read_bytes()).hexdigest()
# Only Elderberry deck definitions/power values; no Legend or rewards code.
s=(S/'js/core/hex-elderberry-world.js').read_text().split('const HEX_ELDER_REGIONS=')[0]
(D/'Resources/Hex/Engine/hex-enemy-decks.js').write_text(s)
# Rebuild authored prints rather than importing the compact browser thumbnails.
subprocess.run([sys.executable,str(D/'tools/hex/import_hd_art.py'),str(S)],check=True)
for asset in (D/'Assets/Hex/cards').glob('*.hextex'):
 manifest['assets'][asset.name]=hashlib.sha256(asset.read_bytes()).hexdigest()
shutil.copy(S/'css/hex/back.webp',D/'Assets/Hex/back.hextex')
# Existing battle audio only (no shop/pack assets).
for key in ['battle','victory','defeat']:shutil.copy(S/f'assets/audio/hex-{key}.mp3',D/f'Assets/Hex/{key}.mp3')
(D/'Resources/Hex/Data/source-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(len(cards),'base cards imported')
