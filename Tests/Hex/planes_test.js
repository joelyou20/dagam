"use strict";
// Runs unchanged in Node and the game's native QuickJS runtime.
globalThis.runPlaneTests = () => {
  let checks = 0;
  const check = (value, message) => {
    checks++;
    if (!value) throw Error(message);
  };
  const card = (g, id, owner = 0) => ({
    id,
    owner,
    originalOwner: owner,
    uid: "p-" + ++g.serial,
    spent: {},
  });
  const fresh = () => {
    const g = hexNewGame(Hex.starter, hexBotDeck("thornbound"), 42);
    Object.assign(g, { turn: 1, active: 0, phase: "pre", tasks: [], stack: [], choice: null });
    for (const p of g.players)
      Object.assign(p, {
        hand: [],
        board: Array(6).fill(null),
        power: [],
        planePlayed: false,
        planes: Array.from({ length: 6 }, () => hexPlane(["Earth"], 0)),
      });
    return g;
  };
  const put = (g, id, side = 0, slot = 0) => {
    const c = card(g, id, side);
    hexExecute(g, { kind: "play", owner: side, card: c, option: { slot } });
    hexPump(g);
    return c;
  };
  check(HEX_CARDS.length === 186, "186 playable definitions");
  check(Hex.starter.length === 30, "30-card starter");
  check(Hex.dispatch({ op: "deckcheck", cards: Hex.starter }).valid, "legal starter");
  for (const def of HEX_CARDS) {
    check(
      def.card_type === "Plane"
        ? !Object.keys(def.cost).length
        : Object.values(def.cost).reduce((a, b) => a + b, 0) > 0,
      def.id + " has correct cost policy",
    );
    if (def.card_type === "Creature")
      check(def.terrain_types?.length > 0, def.id + " has compatibility");
    check(
      JSON.stringify(HEX_CARD[def.id + "-FA"].cost) === JSON.stringify(def.cost),
      "finish cost equality",
    );
  }
  {
    const g = fresh();
    hexGeneratePower(g, 0);
    check(g.players[0].power.length === 0, "natural terrain produces no Power");
    const fire = card(g, "FD-003");
    g.players[0].hand = [fire, card(g, "FD-004")];
    check(hexPlay(g, 0, fire.uid, 0), "first Fire Plane can be played");
    check(
      g.players[0].power.length === 1 && g.players[0].power[0][0] === "Fire",
      "Fire generates immediately",
    );
    check(!hexPlayOptions(g, 0, g.players[0].hand[0]).length, "only one Plane per turn");
    hexGeneratePower(g, 0);
    check(g.players[0].power.length === 1, "next generation refreshes not accumulates");
    check(hexPlay(g, 0, g.players[0].hand[0].uid, 1), "Water in separate hex");
    check(
      JSON.stringify(g.players[0].power) === '[["Fire"],["Water"]]',
      "Fire plus Water as requested",
    );
    const zap = card(g, "SA-002");
    g.players[0].hand.push(zap);
    g.players[1].planes[0] = hexPlane(["Fire"], 0);
    put(g, "WE-004", 1);
    check(hexPlay(g, 0, zap.uid, 0), "spend Fire on Zap");
    check(JSON.stringify(g.players[0].power) === '[["Water"]]', "only matching sphere spent");
  }
  {
    const g = fresh();
    g.players[0].power = [["Earth", "Fire"], ["Earth"]];
    const erupt = card(g, "FD-024");
    g.players[0].hand = [erupt];
    check(hexPlay(g, 0, erupt.uid, 0), "dual payment backtracks to preserve Fire");
    check(g.players[0].power.length === 0, "each sphere spends once");
    check(g.players[1].planes[0].id === "FD-025", "Erupt creates enemy Vent");
    hexSetPlane(g, 1, 0, { id: "FD-008" }, true);
    check(g.players[1].planes[0].level === 2, "matching hand-play upgrades dual hex");
    hexSetPlane(g, 1, 0, { id: "FD-025" });
    check(g.players[1].planes[0].level === 1, "Erupt replacement does not upgrade a matching hex");
    g.players[1].power = [];

    check(g.players[1].power.length === 0, "Erupt grants no immediate Power to either side");
    hexGeneratePower(g, 1);
    check(g.players[1].power.length === 1, "hex controller receives Vent production");
    g.players[0].power = [["Earth", "Fire"]];
    check(hexPowerPayment(g, 0, erupt) === null, "one dual sphere cannot pay twice");
  }
  {
    const g = fresh();
    hexSetPlane(g, 0, 0, { id: "FD-003" }, true);
    hexGeneratePower(g, 0);
    hexSetPlane(g, 0, 0, { id: "FD-003" }, true);
    check(
      g.players[0].planes[0].level === 2 && g.players[0].power.length === 2,
      "upgrade adds only one immediate sphere",
    );
    hexGeneratePower(g, 0);
    check(g.players[0].power.length === 2, "level two produces two next turn");
    hexSetPlane(g, 0, 0, { id: "FD-004" }, true);
    check(
      g.players[0].planes[0].level === 1 && g.players[0].power.length === 3,
      "replacement resets level, retains old pool, adds one",
    );
    g.active = 1;
    check(g.players[0].power.length === 3, "Power survives enemy turn");
    hexGeneratePower(g, 0);
    check(
      JSON.stringify(g.players[0].power) === '[["Water"]]',
      "next refresh reflects replacement",
    );
  }
  {
    const g = fresh(),
      unit = put(g, "LT-006");
    check(!!hexFind(g, unit.uid), "compatible creature enters natural level zero");
    hexSetPlane(g, 0, 0, { id: "FD-003" }, true);
    check(
      !hexFind(g, unit.uid) && g.players[0].hand.some((c) => c.uid === unit.uid),
      "incompatible creature bounces",
    );
    check(g.players[0].losses === 0, "bounce does not count a death");
    const c = card(g, "LT-006");
    g.players[0].hand = [c];
    g.players[0].power = [["Earth"], ["Earth"]];
    check(!hexPlayOptions(g, 0, c).some((o) => o.slot === 0), "cannot play into incompatible hex");
    g.players[0].planes[1] = hexPlane(["Earth"], 0);
    const summoned = hexElderSummon(g, 0, "LT-006", 1);
    hexSetPlane(g, 0, 1, { id: "FD-003" }, true);
    check(
      g.players[0].exile.some((c) => c.uid === summoned.uid),
      "incompatible Summon removed",
    );
  }
  {
    const g = fresh();
    g.players[0].planes[0].locked = true;
    g.players[0].hand = [card(g, "FD-003"), card(g, "FD-001")];
    check(
      !hexPlayOptions(g, 0, g.players[0].hand[0]).some((o) => o.slot === 0),
      "locked terrain cannot be replaced",
    );
    check(
      hexPlayOptions(g, 0, g.players[0].hand[1]).some((o) => o.slot === 0),
      "locked terrain allows matching upgrade",
    );
    const summon = put(g, "LT-006");
    summon.hp = 2;
    g.players[0].planes[0] = { ...hexPlane(["Earth", "Water"], 1), id: "FD-022" };
    hexPlanePre(g, 0);
    hexPump(g);
    check(summon.hp === 3, "Sacred Spring heals on owner pre-combat");
    g.players[0].planes[0] = { ...hexPlane(["Earth", "Fire"], 1), id: "FD-025" };
    hexPlanePre(g, 0);
    hexPump(g);
    check(summon.hp === 2, "Vent damages on owner pre-combat");
  }
  {
    const g = fresh();
    g.players[0].planes[3] = hexPlane(["Light"], 0);
    const c = put(g, "LT-001", 0, 3);
    g.players[0].planes[0] = { ...hexPlane(["Light"], 1), id: "FD-023" };
    hexPlaneCombat(g, 1);
    check(c.shield === 1, "Wall shields creature directly behind");
    g.players[1].planes[0] = { ...hexPlane(["Fire"], 1), id: "FD-026" };
    hexPlaneCombat(g, 1);
    const goblin = g.players[1].board[0];
    check(goblin?.id === "WE-004" && hexHasType(goblin, "Summon"), "Door summons Goblin Punk");
    check(
      hexRuntimeKeyword(g, goblin, "sprint") && goblin.sacrificeAtEnd === g.turn,
      "Door grants Sprint and Doomed",
    );
    hexArcanaEnd(g);
    check(
      !hexFind(g, goblin.uid) && g.players[1].losses === 0,
      "Doomed Summon exiled without defeat count",
    );
  }
  {
    const basics = Array(30).fill("FD-001");
    check(
      Hex.dispatch({ op: "deckcheck", cards: basics }).valid,
      "unlimited basics within deck size",
    );
    check(
      !Hex.dispatch({
        op: "deckcheck",
        cards: [...basics.slice(0, 27), "FD-007", "FD-007", "FD-007"],
      }).valid,
      "dual copy limit",
    );
    check(
      !Hex.dispatch({ op: "deckcheck", cards: [...basics.slice(0, 29), "FD-025"] }).valid,
      "Vent excluded from deck construction",
    );
    check(
      !Hex.dispatch({ op: "deckcheck", cards: basics.slice(0, 20) }).valid,
      "20-card complete decks rejected",
    );
    for (const name of Object.keys(HEX_BOT_DECKS))
      check(
        Hex.dispatch({ op: "deckcheck", cards: hexBotDeck(name) }).valid,
        name + " legal developed enemy deck",
      );
  }
  {
    const g = fresh(),
      reaction = card(g, "SA-035", 1),
      zap = card(g, "SA-002");
    g.players[1].planes[0] = hexPlane(["Earth"], 0);
    put(g, "LT-006", 1);
    g.players[0].power = [["Fire"]];
    g.players[0].hand = [zap];
    g.players[1].hand = [reaction];
    g.players[1].power = [["Sky"]];
    check(hexPlay(g, 0, zap.uid, 0), "cast spell into response window");
    check(hexReactionCards(g, 1).length === 0, "unaffordable Reaction is unavailable");
    const h = fresh(),
      c = put(h, "LT-006");
    h.players[0].planes[1] = hexPlane(["Fire"], 0);
    const other = card(h, "WE-004");
    hexExecute(h, { kind: "play", owner: 0, card: other, option: { slot: 1 } });
    hexPump(h);
    check(hexSwap(h, 0, 0, 1), "forced swap resolves");
    check(
      h.players[0].hand.some((t) => t.uid === c.uid),
      "movement into incompatible terrain bounces",
    );
  }
  {
    Hex.dispatch({ op: "new", seed: 123 });
    let saved = Hex.dispatch({ op: "save" }).game;
    saved.players[0].power = [["Fire", "Earth"], ["Light"]];
    saved.players[0].planes[0] = hexPlane(["Fire", "Earth"], 3);
    check(Hex.dispatch({ op: "load", game: saved }).ok, "save accepts resource state");
    const loaded = Hex.dispatch({ op: "save" }).game;
    check(
      JSON.stringify(loaded.players[0].power) === JSON.stringify(saved.players[0].power),
      "loading does not regenerate Power",
    );
    const legacy = JSON.parse(JSON.stringify(saved));
    legacy.v = 1;
    for (const p of legacy.players) {
      delete p.planes;
      delete p.power;
      delete p.planePlayed;
    }
    check(Hex.dispatch({ op: "load", game: legacy }).ok, "legacy matches migrate");
    check(Hex.dispatch({ op: "save" }).game.v === 2, "migrated match uses resource schema");
    const forest = hexNewGame(Hex.starter, Hex.starter, 44, {
      context: {
        encounter: {
          planes: Array.from({ length: 2 }, () =>
            Array.from({ length: 6 }, () => ({ types: ["Earth"] })),
          ),
        },
      },
    });
    hexGeneratePower(forest, 0);
    hexGeneratePower(forest, 1);
    check(
      forest.players.every((p) => p.power.length === 0),
      "forest encounter gives neither side free opening Power",
    );
    for (const name of Object.keys(HEX_RESOURCE_DECKS)) {
      const deck = hexBotDeck(name);
      check(deck.filter((id) => hexType(id, "Plane")).length === 10, name + " has ten Planes");
      check(
        new Set(deck.flatMap((id) => Object.keys(hexDef(id).cost))).size <= 2,
        name + " has coherent two-colour costs",
      );
    }
  }

  {
    const g = fresh();
    g.players[1].planes[0] = hexPlane(["Earth"], 0);
    put(g, "LT-006", 1);
    const zap = card(g, "SA-002"),
      counter = card(g, "SA-035", 1);
    g.players[0].hand = [zap];
    g.players[0].power = [["Fire"]];
    g.players[1].hand = [counter];
    g.players[1].power = [["Sky"], ["Sky"]];
    check(hexPlay(g, 0, zap.uid, 0), "paid spell opens affordable reaction window");
    check(hexReactionCards(g, 1).length === 1, "affordable Reaction offered");
    check(hexPlay(g, 1, counter.uid, 0), "Reaction can spend Power during enemy turn");
    check(g.players[1].power.length === 0, "Reaction spends its printed cost");
    check(g.players[1].board[0].hp === 4, "countered spell has no damage effect");
  }
  return { checks };
};
