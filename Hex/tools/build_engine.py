"""Bundle the imported battle-only JavaScript for the native runtime and parity tests."""
import json
from pathlib import Path
R=Path(__file__).resolve().parents[1]
cards=json.loads((R/'data/cards.json').read_text());ir=json.loads((R/'data/illustration-rares.json').read_text())
prints=cards+[{**c,'id':c['id']+'-FA','baseId':c['id'],'finish':'full-art'} for c in cards]+[{**c,'id':c['id']+'-IR','baseId':c['id'],'finish':'illustration-rare'} for c in cards if c['id'] in ir]
s='const HEX_CARDS='+json.dumps(cards,separators=(',',':'))+';\nconst HEX_PRINTS='+json.dumps(prints,separators=(',',':'))+';\nconst HEX_CARD=Object.fromEntries(HEX_PRINTS.map(c=>[c.id,c]));\nconst HEX_KEYWORDS='+json.dumps(json.loads((R/'data/keywords.json').read_text()))+';\n'
for name in ['platform','hex-formats','hex-engine','hex-effects','hex-resolve','hex-arcana','hex-elderberry','hex-ai','hex-ai-ascended','hex-opponents','hex-enemy-decks','bridge']:
 s+='\n// '+name+'\n'+(R/f'engine/{name}.js').read_text()+'\n'
(R/'engine/battle.js').write_text(s+'\n"ready";\n')
print('Battle bundle ready:',len(cards),'cards')
