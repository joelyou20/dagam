"use strict";
globalThis.runArchetypeTests = () => {
  let checks = 0;
  const check = (v, m) => {
    checks++;
    if (!v) throw Error(m);
  };
  const g = hexNewGame(Hex.starter, Hex.starter, 42),
    p = g.players[0];
  const pay = (id, power) => {
    p.power = power;
    return hexPowerPayment(g, 0, { id });
  };
  check(
    JSON.stringify(hexDef("SA-044").cost) === '{"Water":1,"Any":1}',
    "Professor is one Water plus one generic",
  );
  check(
    pay("SA-044", [["Water"], ["Fire"]])?.length === 2,
    "any colour pays Professor generic cost",
  );
  check(pay("SA-044", [["Earth"], ["Fire"]]) === null, "generic does not waive Water requirement");
  check(pay("SA-043", [["Sky", "Water"]]) === null, "one split sphere cannot pay a two-Power cost");
  check(
    pay("SA-043", [["Sky", "Water"], ["Earth"]])?.length === 2,
    "split sphere plus off-colour Power pays mixed cost",
  );
  const assignment = pay("SA-044", [["Water"], ["Fire"], ["Water", "Sky"]]);
  check(
    assignment.includes(0) && assignment.includes(1) && !assignment.includes(2),
    "payment preserves flexible dual Power when possible",
  );
  check(
    JSON.stringify(pay("LT-042", [["Water", "Sky"], ["Earth"]])) === "[1]",
    "neutral utility spends single-colour Power first",
  );
  check(
    pay("WE-018", [["Earth"], ["Water"], ["Sky"]]) === null,
    "focused cards retain two matching requirements",
  );
  check(
    pay("WE-018", [["Earth"], ["Earth", "Fire"], ["Water"]])?.length === 3,
    "two matching plus generic can be paid",
  );
  p.hand = [{ id: "SA-035", uid: "held-counter", owner: 0 }];
  const reserved = pay("SA-044", [["Water"], ["Sky"], ["Fire"]]);
  check(
    reserved.includes(0) && reserved.includes(2) && !reserved.includes(1),
    "generic payment preserves Sky for a held Countermagic when Fire can pay instead",
  );
  const pairs = new Set();
  for (const a of HEX_ARCHETYPES) {
    check(
      Hex.dispatch({ op: "deckcheck", cards: a.cards }).valid,
      a.id + " legal 30-card template",
    );
    check(a.cards.filter((id) => hexType(id, "Plane")).length === 10, a.id + " has ten Planes");
    for (const id of a.cards)
      check(
        Object.keys(hexDef(id).cost)
          .filter((t) => t !== "Any")
          .every((t) => a.colours.includes(t)),
        a.id + " supports " + id,
      );
    if (a.colours.length === 2) pairs.add([...a.colours].sort().join("/"));
  }
  check(pairs.size === 15, "all fifteen colour pairs have a buildable template");
  check(
    HEX_ARCHETYPES.some((a) => a.id === "water_mages" && a.colours.length === 1),
    "single-colour Mage template exists",
  );
  const core = [
    "SA-038",
    "SA-040",
    "SA-042",
    "SA-043",
    "SA-044",
    "SA-045",
    "SA-047",
    "SA-002",
    "SA-008",
    "SA-010",
    "SA-011",
    "SA-025",
    "SA-028",
    "SA-030",
    "SA-031",
    "SA-032",
    "SA-033",
    "SA-035",
  ];
  for (const id of core)
    check(
      Object.keys(hexDef(id).cost).every((t) => ["Water", "Sky", "Any"].includes(t)),
      id + " fits Water/Sky core",
    );
  for (const id of ["SA-036", "SA-039"])
    check(hexDef(id).cost.Any === 1, id + " is a neutral Goblin/Mage bridge");
  for (const c of HEX_CARDS) {
    check(
      Object.keys(c.cost).every((t) => t === "Any" || HEX_TERRAINS.includes(t)),
      c.id + " only known cost types",
    );
    for (const [tribe, colours] of [
      ["Goblin", ["Earth", "Fire"]],
      ["Wiskin", ["Earth", "Light"]],
    ]) {
      if ((c.types || []).includes(tribe))
        check(
          Object.keys(c.cost)
            .filter((t) => t !== "Any")
            .every((t) => colours.includes(t)),
          c.id + " fits its " + tribe + " tribal core",
        );
    }
    if (c.card_type === "Plane") check(!Object.keys(c.cost).length, c.id + " remains free");
    for (const suffix of ["-FA", "-IR"])
      if (HEX_CARD[c.id + suffix])
        check(
          JSON.stringify(HEX_CARD[c.id + suffix].cost) === JSON.stringify(c.cost),
          c.id + suffix + " cosmetic price equality",
        );
  }
  for (const id of Object.keys(HEX_RESOURCE_DECKS)) {
    const deck = hexBotDeck(id),
      colours = new Set(
        deck.flatMap((c) => Object.keys(hexDef(c).cost).filter((t) => t !== "Any")),
      );
    check(colours.size <= 2, id + " enemy stays within two anchored colours");
    const production = new Set(
      deck.filter((c) => hexType(c, "Plane")).flatMap((c) => hexDef(c).terrain_types),
    );
    check(
      [...colours].every((t) => production.has(t)),
      id + " Plane base covers every requirement",
    );
  }
  Hex.dispatch({ op: "new", seed: 1 });
  const saved = Hex.dispatch({ op: "save" }).game;
  saved.players[0].power = [["Any"]];
  let rejected = false;
  try {
    Hex.dispatch({ op: "load", game: saved });
  } catch (_) {
    rejected = true;
  }
  check(rejected, "generic is a cost allowance, not a seventh generated Power colour");
  {
    const h = hexNewGame(Hex.starter, Hex.starter, 42);
    Object.assign(h, { active: 0, phase: "pre", turn: 1, stack: [], tasks: [], choice: null });
    h.players[0].planes = Array.from({ length: 6 }, () => hexPlane(["Earth"], 0));
    h.players[0].planes[3] = hexPlane(["Fire"], 0);
    const hero = { id: "LT-006", uid: "moving", owner: 0, originalOwner: 0, spent: {} },
      other = { id: "WE-004", uid: "companion", owner: 0, originalOwner: 0, spent: {} };
    hexExecute(h, { kind: "play", owner: 0, card: hero, option: { slot: 0 } });
    hexPump(h);
    hexExecute(h, { kind: "play", owner: 0, card: other, option: { slot: 3 } });
    hexPump(h);
    hero.eq = { id: "LT-054", uid: "sandals", owner: 0 };
    hexExecute(h, { kind: "silkSwap", owner: 0, target: hero.uid });
    hexPump(h);
    check(
      h.players[0].hand.some((c) => c.uid === hero.uid),
      "movement equipment can bounce a creature onto incompatible terrain without crashing",
    );
    check(
      !hero.mods && h.players[0].discard.some((c) => c.uid === "sandals"),
      "bounced creature receives no battlefield buff and drops equipment",
    );
  }
  return { checks };
};
