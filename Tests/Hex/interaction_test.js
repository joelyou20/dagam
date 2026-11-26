"use strict";
globalThis.runInteractionTests = () => {
  let checks = 0;
  const check = (ok, message) => {
    checks++;
    if (!ok) throw Error(message);
  };
  const g = hexNewGame(Hex.starter, Hex.starter, 42);
  hexKeep(g);
  check(g.phase === "pre", "Opening proceeds directly to pre-combat");
  const p = g.players[g.active];
  p.hand = [{ id: "FD-022", uid: "plane", owner: g.active }];
  p.planePlayed = false;
  g.tasks = [];
  g.stack = [];
  g.choice = null;
  g.phase = "power";
  check(hexPlayOptions(g, g.active, p.hand[0]).length === 0, "No Plane plays during Power");
  check(hexMigrateMatch(g).phase === "pre", "Legacy Power checkpoint resumes into pre-combat");
  g.phase = "pre";
  check(hexPlayOptions(g, g.active, p.hand[0]).length > 0, "Plane can be played pre-combat");
  g.phase = "post";
  check(hexPlayOptions(g, g.active, p.hand[0]).length > 0, "Plane can be played post-combat");
  g.phase = "combat";
  check(hexPlayOptions(g, g.active, p.hand[0]).length === 0, "No Plane plays during combat");
  g.phase = "pre";
  p.planes[0] = hexPlane(["Water"], 2);

  hexBeginTurn(g);
  check(g.phase === "pre", "Subsequent turn also enters pre-combat automatically");
  check(!("power" in p), "Turns do not generate or retain Power");
  const card = (id, uid, slot) => ({
    id,
    uid,
    owner: g.active,
    originalOwner: g.active,
    slot,
    hp: hexDef(id).hp - 1,
    mods: [],
    spent: {},
    entered: g.turn,
  });
  const orator = card("SA-047", "orator", 0),
    mage = card("SA-044", "mage", 1);
  p.board = [orator, mage, null, null, null, null];
  p.planes = Array.from({ length: 6 }, () => hexPlane(HEX_TERRAINS, 0));
  g.choice = null;
  hexExecute(g, hexArcanaTask(g.active, "orator", { source: orator.uid }));
  check(g.choice === null, "Orator never prompts for its free untargeted heal");
  check(
    orator.hp === hexDef(orator).hp && mage.hp === hexDef(mage).hp,
    "Orator heals all Mages immediately",
  );
  p.board[0] = null;
  mage.hp = hexDef(mage).hp - 1;
  hexExecute(g, hexArcanaTask(g.active, "orator", { source: orator.uid }));
  check(mage.hp === hexDef(mage).hp - 1, "Removed Orator does not resolve its trigger");
  g.effectSource = mage;
  hexAsk(g, g.active, "Choose creature", [
    { label: "Mage", task: { kind: "noop", target: mage.uid } },
  ]);
  check(g.choice.source.uid === mage.uid, "Trigger choice retains its source snapshot");
  delete g.effectSource;
  check(
    JSON.parse(JSON.stringify(g.choice)).source.id === "SA-044",
    "Source metadata survives saves",
  );
  return { checks };
};
