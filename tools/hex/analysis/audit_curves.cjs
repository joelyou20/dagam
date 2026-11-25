const fs = require("fs");
const vm = require("vm");
const path = require("path");
const root = path.resolve(__dirname, "../../..");
const context = vm.createContext({});
vm.runInContext(
  fs.readFileSync(path.join(root, "Resources/Hex/Engine/battle.js"), "utf8"),
  context,
);
const rows = vm.runInContext(
  `Object.fromEntries([['starter',Hex.starter],...Object.keys(HEX_RESOURCE_DECKS).map(n=>[n,hexBotDeck(n)])].map(([name,deck])=>{
 const cards=deck.filter(id=>!hexType(id,'Plane')).map(id=>hexDef(id));
 const cost=c=>Object.values(c.cost).reduce((a,b)=>a+b,0);
 return [name,{planes:deck.length-cards.length,low:cards.filter(c=>cost(c)<=2).length,mid:cards.filter(c=>cost(c)>=3&&cost(c)<=4).length,high:cards.filter(c=>cost(c)>=5).length,cheap_creatures:cards.filter(c=>c.card_type==='Creature'&&cost(c)<=2).length}];
}))`,
  context,
);
fs.writeFileSync(
  path.join(root, "docs/resource-flow/deck-curves.json"),
  JSON.stringify(rows, null, 2) + "\n",
);
console.log(rows.starter, rows.crownimperium, rows["seraphic-warhost"]);
