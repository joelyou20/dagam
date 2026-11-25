/* Real random-draw matches across every authored archetype, with the live engine. */
const fs = require("fs");
const path = require("path");
const vm = require("vm");
const root = path.resolve(__dirname, "../..");
const context = vm.createContext({ console });
vm.runInContext(
  fs.readFileSync(path.join(root, "Resources/Hex/Engine/battle.js"), "utf8"),
  context,
);
vm.runInContext(
  `
function testArchetype(deck,enemy,seed) {
 const g=hexNewGame(deck,hexBotDeck(enemy),seed,{context:{opponentAI:'ascended'}});
 const p=g.players[0];if(!p.hand.some(c=>hexType(c,'Plane'))||!p.hand.some(c=>hexType(c,'Creature')))hexMulligan(g,0);else hexKeep(g);
 let steps=0,genericPlays=0,plays=0;
 while(g.winner===null&&steps++<1800) {
  const side=g.choice?.player??g.stack.at(-1)?.priority??g.active;
  const action=hexAscendedPlan(g,side);if(!action)throw Error('No legal action');
  const c=action.kind==='play'?g.players[side].hand.find(c=>c.uid===action.uid):null;
  if(!hexAscendedApply(g,side,action))throw Error('Rejected action');
  if(side===0&&c&&!hexType(c,'Plane')){plays++;if(hexDef(c).cost.Any)genericPlays++;}
  g.fx=[];g.log=g.log.slice(-5);
 }
 if(g.winner===null)throw Error('Unfinished archetype match');
 return {enemy,seed,winner:g.winner,round:hexTurnNumber(g),steps,plays,genericPlays};
}
`,
  context,
);
const archetypes = vm.runInContext("HEX_ARCHETYPES", context),
  results = [];
for (const a of archetypes) {
  const check = vm.runInContext(
    `Hex.dispatch({op:'deckcheck',cards:${JSON.stringify(a.cards)}})`,
    context,
  );
  if (!check.valid) throw Error(a.id + JSON.stringify(check));
  const games = [];
  for (const enemy of ["thornbound", "stormcourt"])
    for (const seed of [42, 1337, 8100])
      games.push(
        vm.runInContext(
          `testArchetype(${JSON.stringify(a.cards)},${JSON.stringify(enemy)},${seed})`,
          context,
        ),
      );
  results.push({ id: a.id, colours: a.colours, games });
  console.log(a.id, games.length, "completed");
}
fs.writeFileSync(
  path.join(root, "docs/archetype-costs/matches.json"),
  JSON.stringify(results, null, 2) + "\n",
);
