#!/usr/bin/env python3
"""Recover 1024x1536 card composites using the saved source art, frames and text scripts.
No image generation and no source-repository writes. Pillow is required.
Usage: python tools/hex/import_hd_art.py /path/to/lifestyleTracker-repo
"""
import hashlib,importlib.util,json,re,shutil,sys,tempfile
from pathlib import Path
from PIL import Image
S=Path(sys.argv[1]).resolve();R=Path(__file__).resolve().parents[2]
OUT=R/'Assets/Hex/cards';D=R/'Resources/Hex/Data'
source={c['id']:c for name in ['first-light','shattered-arcana','war-on-elderberry'] for c in json.loads((S/f'catalog/hex/{name}.json').read_text())['cards']}
current=json.loads((D/'cards.json').read_text())
for c in current:
 for key in ['rules','attack','hp','keywords','rarity']:
  assert c.get(key)==source[c['id']].get(key),(c['id'],key,'Catalogue mismatch: refresh game data first')
work=Path(tempfile.mkdtemp(prefix='hex-hd-'))
records=[]
def run(path,args,replacements):
 code=path.read_text()
 for a,b in replacements:
  assert a in code,(path,a)
  code=code.replace(a,b)
 saved=sys.argv;sys.argv=[str(path)]+args
 try:exec(compile(code,str(path),'exec'),{'__file__':str(path),'__name__':'__main__'})
 finally:sys.argv=saved

def install(id,path):
 image=Image.open(path);assert image.size==(1024,1536),(id,image.size)
 target=OUT/(id+'.hextex');shutil.copy(path,target)
 records.append({'id':id,'width':image.width,'height':image.height,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
# First Light's regular cards were only kept as reduced web files. Rebuild at frame size.
collection=S/'artwork/first-light-authoring/card-collection'
spec=importlib.util.spec_from_file_location('hex_frame_composer',collection/'compose_cards.py');composer=importlib.util.module_from_spec(spec);spec.loader.exec_module(composer)
collection_data=json.loads((collection/'collection.json').read_text());frames={}
for rarity,path in collection_data['templates'].items():
 frame=Image.open(collection/path).convert('RGBA');mask,bbox=composer.artwork_mask(frame);frames[rarity]=(frame,mask,bbox)
blanks=work/'blanks';blanks.mkdir();regular=work/'regular';regular.mkdir()
for row in collection_data['cards']:
 c=source['LT-'+str(row['number']).zfill(3)];frame,mask,bbox=frames[c['rarity']]
 canvas=composer.compose(Image.open(collection/row['art']),frame,mask,bbox,'cover',row.get('framing'))
 slug=re.sub('[^a-z0-9]+','-',c['name'].lower()).strip('-')
 canvas.save(blanks/(str(c['number']).zfill(3)+'-'+slug+'.png'))
run(S/'tools/render-hex-text.py',['--composites',str(blanks)],[("image.resize((768,1152),Image.Resampling.LANCZOS).save(ROOT/'css/hex/cards'/(str(row['number']).zfill(3)+'.webp'),quality=92,method=6)",f"image.save(Path({str(regular)!r})/(row['id']+'.webp'),quality=92,method=4)")])
for c in current:
 if c['set']=='first-light':install(c['id'],regular/(c['id']+'.webp'))
 else:
  # Authored prints must match the current rules/stats before reuse.
  authored=next(row for row in json.loads((S/f'artwork/{c["set"]}/manifest.json').read_text()) if row['id']==c['id'])
  for key in ['attack','hp','rarity']:assert authored.get(key)==c.get(key),(c['id'],key,'Stale authored print')
  for finish,suffix in [('regular',''),('full-art','-FA')]:install(c['id']+suffix,S/f'artwork/{c["set"]}/{finish}/{c["id"]}.webp')
full=work/'full-art'
run(S/'tools/hex-full-art/render.py',['--sources',str(collection/'sources')],[("OUT=ROOT/'css/hex/full-art'",f"OUT=Path({str(full)!r})"),("canvas.resize((768,1152),Image.Resampling.LANCZOS).save","canvas.save"),("quality=90,method=6","quality=92,method=4")])
for c in current:
 if c['set']=='first-light':install(c['id']+'-FA',full/(c['id']+'.webp'))
ir=work/'ir'
run(S/'tools/hex-illustration-rare/render.py',['--set','all'],[("OUT=ROOT/'css/hex/illustration-rare'",f"OUT=Path({str(ir)!r})"),("canvas.resize((768,1152),Image.Resampling.LANCZOS).save","canvas.save"),("quality=90,method=6","quality=92,method=4"),("quality=95,method=6","quality=92,method=4"),("review=ROOT/'docs/hex-clay-illustration-rares/cards'",f"review=Path({str(work/'review')!r})"),("proof_path=ROOT/'docs/hex-clay-illustration-rares/render-proof.json'",f"proof_path=Path({str(work/'proof.json')!r})")])
for id in json.loads((D/'illustration-rares.json').read_text()):install(id+'-IR',ir/(id+'.webp'))
assert len(records)==345
(D/'hd-art-manifest.json').write_text(json.dumps({'source':'Original authored art/frames and current catalogue text','cards':records},indent=2)+'\n')
shutil.rmtree(work)
print('Imported',len(records),'full-resolution card prints')
