/* Isolated cost/Plane-density experiments. Live game files are never changed. */
const fs = require("fs");
const path = require("path");
const vm = require("vm");
const root = path.resolve(__dirname, "../../..");
const variant = process.argv[2] || "current";
const seeds = Number(process.argv[3] || 8);
const maxRounds = Number(process.argv[4] || 25);
const variants = {
  current: {},
  cheaper: { discount: true },
  planes12: { planes: 12 },
  cheaper_planes12: { discount: true, planes: 12 },
  cheaper_planes14: { discount: true, planes: 14 },
  cheaper_planes12_grace: { discount: true, planes: 12, grace: 5 },
  cheaper_planes12_pressure: { discount: true, planes: 12, pressure: true },
};
if (!variants[variant]) throw Error("Unknown variant: " + variant);
if (!Number.isInteger(seeds) || seeds < 1 || !Number.isInteger(maxRounds) || maxRounds < 1)
  throw Error("Positive integer seeds/round limit required");
let bundle = fs.readFileSync(path.join(root, "Resources/Hex/Engine/battle.js"), "utf8");
const config = variants[variant];
const emptyCondition =
  "if (!g.players[g.active].board.some(Boolean) && g.players[1 - g.active].board.some(Boolean)) {";
if (!bundle.includes(emptyCondition)) throw Error("Defeat rule changed; review patch");
if (config.grace)
  bundle = bundle.replace(
    emptyCondition,
    emptyCondition.replace("if (", "if (hexTurnNumber(g) >= " + config.grace + " && "),
  );
if (config.pressure)
  bundle = bundle.replace(
    emptyCondition,
    `if (!g.players[g.active].board.some(Boolean) && g.players[1 - g.active].board.some(Boolean) && hexTurnNumber(g)>=3) {
  const p=g.players[g.active];p.losses++;p.pressure=(p.pressure||0)+1;
  if(p.losses>=hexRules(g).losses){g.winner=1-g.active;g.lossReason='pressure';g.phase='over';g.tasks=[];g.stack=[];g.choice=null;break;}
}
if(false) {`,
  );
const context = vm.createContext({ console, EXPERIMENT: config, MAX_ROUNDS: maxRounds });
vm.runInContext(bundle, context);
vm.runInContext(
  `
if(EXPERIMENT.discount) {
  // Broad diagnostic discount, not a claim that every individual card needs it.
  for(const c of HEX_PRINTS) {
    const entries=Object.entries(c.cost||{});
    if(c.card_type!=='Plane'&&entries.length===1&&entries[0][1]>1)c.cost={[entries[0][0]]:entries[0][1]-1};
  }
}
function flowDeck(original) {
  const planes=original.filter(id=>hexType(id,'Plane'));
  const battle=original.filter(id=>!hexType(id,'Plane'));
  const desired=EXPERIMENT.planes||planes.length;
  // Raising Plane density within 30 cards requires cuts: trim expensive support
  // cards first, retaining early creatures and the original two-colour identity.
  while(battle.length>30-desired) {
    const ranked=battle.map((id,index)=>({id,index,cost:Object.values(hexDef(id).cost).reduce((a,b)=>a+b,0),creature:hexType(id,'Creature')}));
    ranked.sort((a,b)=>Number(a.creature)-Number(b.creature)||b.cost-a.cost||a.index-b.index);
    battle.splice(ranked[0].index,1);
  }
  const basics=[...new Set(planes.filter(id=>hexDef(id).basic_plane))];
  let i=0;while(planes.length<desired)planes.push(basics[i++%basics.length]);
  return [...battle,...planes];
}
function flowSetup(enemy,seed) {
  const g=hexNewGame(flowDeck(Hex.starter),flowDeck(hexBotDeck(enemy)),seed,{interactiveCoin:true,context:{opponentAI:'ascended'}});
  g.first=g.active=hexRand(g)<0.5?0:1;g.phase='opening';
  for(let side=0;side<2;side++) {
    const p=g.players[side];hexDraw(g,side,5);
    const creatures=p.hand.filter(c=>hexType(c,'Creature')).length;
    const planes=p.hand.filter(c=>hexType(c,'Plane')).length;
    const redraw=side===1 ? creatures<2||creatures>4 : planes<2||creatures<1;
    if(redraw){p.deck=hexShuffle(g,p.deck.concat(p.hand));p.hand=[];hexDraw(g,side,5);p.mulligan=true;}
  }
  const opening=g.players.map(p=>({planes:p.hand.filter(c=>hexType(c,'Plane')).length,creatures:p.hand.filter(c=>hexType(c,'Creature')).length}));
  hexKeep(g);return {g,opening};
}
function flowMatch(enemy,seed) {
  const {g,opening}=flowSetup(enemy,seed);
  const records=[], map=new Map();let steps=0, error=null;
  const firstCreature=[null,null];
  function turnRecord(){
    if(!g.turn)return null;
    const key=g.turn;
    if(!map.has(key)) {
      const r={side:g.active,round:hexTurnNumber(g),planes:g.players[g.active].planes.reduce((n,h)=>n+h.level,0),plays:0,attacks:0,abilities:0,pre:false};map.set(key,r);records.push(r);
    }
    return map.get(key);
  }
  while(g.winner===null&&hexTurnNumber(g)<=MAX_ROUNDS&&steps++<1800) {
    const r=turnRecord();
    const side=g.choice?.player??g.stack.at(-1)?.priority??g.active;
    if(g.phase==='pre'&&!r.pre) {
      const p=g.players[g.active],non=p.hand.filter(c=>!hexType(c,'Plane'));
      r.pre=true;r.planes=p.planes.reduce((n,h)=>n+h.level,0);r.power=p.power.length;
      r.locked=non.length>0 && non.every(c=>hexPowerPayment(g,g.active,c)===null);
      r.playable=non.filter(c=>hexPlayOptions(g,g.active,c).length).length;
    }
    const a=hexAscendedPlan(g,side);
    if(!a){error='No action '+g.phase;break;}
    const c=a.kind==='play'?g.players[side].hand.find(c=>c.uid===a.uid):null;
    if(!hexAscendedApply(g,side,a)){error='Rejected '+a.kind;break;}
    if(side===r.side){
      if(a.kind==='play'&&c&&!hexType(c,'Plane'))r.plays++;
      if(a.kind==='attack')r.attacks++;
      if(a.kind==='active')r.abilities++;
    }
    for(let p=0;p<2;p++)if(firstCreature[p]===null&&g.players[p].board.some(Boolean))firstCreature[p]=hexTurnNumber(g);
    g.fx=[];g.log=g.log.slice(-5);
  }
  const round=Math.min(hexTurnNumber(g),MAX_ROUNDS);
  return {enemy,seed,first:g.first,opening,winner:g.winner,reason:g.lossReason||g.drawReason||(g.winner!==null?'defeat-limit':'censored'),round,steps,error,firstCreature,losses:g.players.map(p=>p.losses),pressure:g.players.map(p=>p.pressure||0),records};
}
`,
  context,
);
const pilotEnemies = [
  "thornbound",
  "meadowfolk",
  "stormcourt",
  "cinderforge",
  "gravekeepers",
  "bloodfist-horde",
  "cloudcarriage-guard",
  "seraphic-warhost",
];
const allEnemies = process.argv[5] === "all";
const enemies = allEnemies ? vm.runInContext("Object.keys(HEX_BOT_DECKS)", context) : pilotEnemies;
const games = [];
for (const enemy of enemies) {
  for (let i = 0; i < seeds; i++)
    games.push(vm.runInContext(`flowMatch(${JSON.stringify(enemy)},${8100 + i * 7919})`, context));
  console.log(variant, enemy, games.length);
}
const output = path.join(
  root,
  "docs/resource-flow",
  variant + (allEnemies ? "-all" : "") + ".json",
);
fs.mkdirSync(path.dirname(output), { recursive: true });
fs.writeFileSync(
  output,
  JSON.stringify({ variant, config, seeds, maxRounds, enemies, games }, null, 2) + "\n",
);
