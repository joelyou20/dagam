/* Replay representative themed decks against the old and current prices. */
const fs = require("fs");
const vm = require("vm");
const path = require("path");
const root = path.resolve(__dirname, "../..");
const pair = (...ids) => ids.flatMap((id) => [id, id]);
const waterSky = [
  ...pair(
    "SA-036",
    "SA-038",
    "SA-042",
    "SA-043",
    "SA-006",
    "SA-010",
    "SA-011",
    "SA-019",
    "SA-025",
    "SA-035",
  ),
  ...pair("FD-013"),
  ...Array(4).fill("FD-002"),
  ...Array(4).fill("FD-004"),
];
const darkLight = [
  ...pair(
    "SA-039",
    "SA-041",
    "SA-044",
    "SA-045",
    "SA-047",
    "SA-004",
    "SA-009",
    "SA-013",
    "SA-021",
    "SA-030",
  ),
  ...pair("FD-021"),
  ...Array(4).fill("FD-005"),
  ...Array(4).fill("FD-006"),
];
const prismatic = [
  ...pair(
    "SA-036",
    "SA-037",
    "SA-038",
    "SA-039",
    "SA-043",
    "SA-044",
    "SA-045",
    "SA-010",
    "SA-011",
    "SA-035",
  ),
  ...pair("FD-013", "FD-014", "FD-015", "FD-019", "FD-021"),
];
const decks = {
  water_sky_mages: waterSky,
  dark_light_mages: darkLight,
  prismatic_mages: prismatic,
};
const current = fs.readFileSync(path.join(root, "Resources/Hex/Engine/battle.js"), "utf8");
const audit = JSON.parse(
  fs.readFileSync(path.join(root, "docs/card-costs/repricing.json"), "utf8"),
);
const results = {};
for (const version of ["previous", "current"]) {
  const source = current;
  const ctx = vm.createContext({ console });
  vm.runInContext(source, ctx);
  if (version === "previous")
    vm.runInContext(
      `for(const row of ${JSON.stringify(audit)})for(const c of HEX_PRINTS)if((c.baseId||c.id)===row.id)c.cost={[row.colour]:row.old};`,
      ctx,
    );
  vm.runInContext(
    `
 function repricedMatch(deck,enemy,seed) {
  const g=hexNewGame(deck,hexBotDeck(enemy),seed,{interactiveCoin:true});
  g.first=g.active=hexRand(g)<.5?0:1;g.phase='opening';hexDraw(g,0,5);hexDraw(g,1,5);
  for(const p of g.players)if(p.hand.filter(c=>hexType(c,'Plane')).length<1||!p.hand.some(c=>hexType(c,'Creature'))){p.deck=hexShuffle(g,p.deck.concat(p.hand));p.hand=[];hexDraw(g,p===g.players[0]?0:1,5);p.mulligan=true;}
  hexKeep(g);let steps=0,plays=0,spells=0;const spellTurns={};let earlyNoPlay=0,earlyObserved=0;const observed=new Set();
  while(g.winner===null&&steps++<1200) {
   const side=g.choice?.player??g.stack.at(-1)?.priority??g.active;
   if(side===0&&g.phase==='pre'&&!observed.has(g.turn)) {
    observed.add(g.turn);if(hexTurnNumber(g)<=3){earlyObserved++;if(!g.players[0].hand.some(c=>!hexType(c,'Plane')&&hexPlayOptions(g,0,c).length))earlyNoPlay++;}
   }
   const a=hexAscendedPlan(g,side);if(!a)throw Error('no action');
   const c=a.kind==='play'?g.players[side].hand.find(c=>c.uid===a.uid):null;
   if(!hexAscendedApply(g,side,a))throw Error('rejected action');
   if(side===0&&c&&!hexType(c,'Plane')){plays++;if(hexType(c,'Spell')){spells++;spellTurns[g.turn]=(spellTurns[g.turn]||0)+1;}}
   g.fx=[];g.log=g.log.slice(-5);
  }
  if(g.winner===null)throw Error('unfinished themed match');
  return {enemy,seed,round:hexTurnNumber(g),winner:g.winner,reason:g.lossReason||'defeat-limit',plays,spells,multiSpellTurns:Object.values(spellTurns).filter(n=>n>=2).length,earlyNoPlay,earlyObserved};
 }
 `,
    ctx,
  );
  results[version] = {};
  const starter = vm.runInContext("Hex.starter", ctx);
  for (const [name, deck] of Object.entries({ ...decks, starter })) {
    const check = vm.runInContext(
      `Hex.dispatch({op:'deckcheck',cards:${JSON.stringify(deck)}})`,
      ctx,
    );
    if (!check.valid) throw Error(name + JSON.stringify(check));
    const games = [];
    for (const enemy of ["stormcourt", "gravekeepers", "bloodfist-horde"])
      for (const seed of [42, 1337, 8100, 16019])
        games.push(
          vm.runInContext(
            `repricedMatch(${JSON.stringify(deck)},${JSON.stringify(enemy)},${seed})`,
            ctx,
          ),
        );
    const costs = vm.runInContext(
      `${JSON.stringify(deck)}.filter(id=>!hexType(id,'Plane')).map(id=>Object.values(hexDef(id).cost).reduce((a,b)=>a+b,0))`,
      ctx,
    );
    results[version][name] = {
      meanBattleCost: costs.reduce((a, b) => a + b, 0) / costs.length,
      onePowerBattleCards: costs.filter((n) => n === 1).length,
      games,
    };
    console.log(version, name, "average cost", results[version][name].meanBattleCost);
  }
}
fs.writeFileSync(
  path.join(root, "docs/card-costs/themed-validation.json"),
  JSON.stringify({ decks, results }, null, 2) + "\n",
);
