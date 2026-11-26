"use strict";
globalThis.runPlaneTests = () => {
  let checks = 0;
  const check = (ok, message) => {
    checks++;
    if (!ok) throw Error(message);
  };
  const fresh = () => {
    const g = hexNewGame(Hex.starter, Hex.starter, 42);
    Object.assign(g, { turn: 1, active: 0, phase: "pre", tasks: [], stack: [], choice: null });
    for (const p of g.players)
      Object.assign(p, {
        hand: [],
        board: Array(6).fill(null),
        planes: Array.from({ length: 6 }, () => hexPlane([], 0)),
      });
    return g;
  };
  const card = (g, id, owner = 0) => ({
    id,
    owner,
    originalOwner: owner,
    uid: "free-" + ++g.serial,
    spent: {},
  });
  const put = (g, id, side = 0, slot = 0) => {
    const c = card(g, id, side);
    hexExecute(g, { kind: "play", owner: side, card: c, option: { slot } });
    hexPump(g);
    return c;
  };
  check(Hex.starter.length === 20, "Starter returns to 20 cards");
  check(!Hex.starter.some((id) => hexDef(id).retired), "Starter contains no inert Planes");
  for (const def of HEX_CARDS) {
    check(!("cost" in def), def.id + " has no cost");
    check(!("terrain_types" in def), def.id + " has no terrain requirement");
    check(!("cost" in HEX_CARD[def.id + "-FA"]), def.id + " full art has no cost");
    if (def.retired)
      check(def.card_type === "Plane" && !def.rules.trim(), def.id + " is an inert Plane");
  }
  {
    const g = fresh(),
      c = card(g, "SA-038");
    g.players[0].hand = [c];
    check(
      hexPlayOptions(g, 0, c).length === 6,
      "Sprite fits every empty hex without terrain or Power",
    );
    check(hexPlay(g, 0, c.uid, 4), "Sprite plays for free");
    check(g.players[0].board[4]?.uid === c.uid, "Free creature occupies chosen hex");
    const mage = card(g, "SA-044");
    g.players[0].hand.push(mage);
    check(hexPlay(g, 0, mage.uid, 0), "A second creature plays immediately on turn one");
    check(!("power" in g.players[0]), "Playing cards does not introduce a Power pool");
    const before = c.hp;
    hexSetPlane(g, 0, 4, { id: "FD-022" }, true);
    check(g.players[0].board[4] === c, "Plane replacement never bounces its occupant");
    c.hp = before - 1;
    hexPlanePre(g, 0);
    hexPump(g);
    check(c.hp === before, "Sacred Spring still heals at pre-combat");
    hexSetPlane(g, 0, 4, { id: "FD-025" });
    hexPlanePre(g, 0);
    hexPump(g);
    check(c.hp === before - 1, "Volcanic Vent still damages its occupant");
  }
  {
    const g = fresh(),
      c = put(g, "LT-006", 0, 3);
    const shield = c.shield || 0;
    hexSetPlane(g, 0, 0, { id: "FD-023" });
    hexPlaneCombat(g, 1);
    check(c.shield === shield + 1, "Wall of Light protects the creature behind it");
    hexSetPlane(g, 0, 1, { id: "FD-026" });
    hexPlaneCombat(g, 0);
    const summon = g.players[0].board[1];
    check(
      summon?.id === "WE-004" && hexHasType(summon, "Summon"),
      "Door still summons a Goblin Punk",
    );
    check(
      hexRuntimeKeyword(g, summon, "sprint") > 0 && summon.sacrificeAtEnd === g.turn,
      "Door summon retains Sprint and Doomed",
    );
  }
  {
    const g = fresh(),
      p = g.players[0],
      plane = card(g, "FD-022");
    p.hand = [plane];
    check(hexPlay(g, 0, plane.uid, 0), "Effect Plane plays for free");
    const second = card(g, "FD-023");
    p.hand.push(second);
    check(hexPlayOptions(g, 0, second).length === 0, "Effect Planes retain one play per turn");
    p.planePlayed = false;
    g.phase = "post";
    check(hexPlayOptions(g, 0, second).length === 6, "Plane plays remain legal post-combat");
    g.phase = "combat";
    check(hexPlayOptions(g, 0, second).length === 0, "Plane plays remain outside combat");
    g.phase = "pre";
    const erupt = card(g, "FD-024");
    p.hand = [erupt];
    check(hexPlay(g, 0, erupt.uid, 2), "Erupt casts without resources");
    check(g.players[1].planes[2].id === "FD-025", "Erupt still creates an enemy Vent");
    const inert = card(g, "FD-001");
    p.hand = [inert];
    p.planePlayed = false;
    check(hexPlayOptions(g, 0, inert).length === 0, "Retired Planes cannot be played");
  }
  {
    const old = [...Hex.starter, ...Array(10).fill("FD-001")];
    check(
      JSON.stringify(hexDevelopDeck(old)) === JSON.stringify(Hex.starter),
      "Old 30-card deck loses resource Planes only",
    );
    check(hexDevelopDeck(Hex.starter).length === 20, "20-card decks are not expanded");
    check(!Hex.dispatch({ op: "deckcheck", cards: old }).valid, "30-card decks are rejected");
    check(
      !Hex.dispatch({ op: "deckcheck", cards: ["FD-001", ...Hex.starter.slice(1)] }).valid,
      "Inert Planes cannot enter a deck",
    );
    const saved = fresh();
    saved.v = 2;
    saved.phase = "power";
    saved.players[0].power = [["Fire"]];
    saved.players[0].deck.push(card(saved, "FD-001"));
    saved.players[0].hand = [card(saved, "FD-007")];
    const c = put(saved, "SA-038");
    saved.players[0].planes[0] = hexPlane(["Fire"], 6, { id: "FD-001" });
    const upgraded = hexMigrateMatch(saved);
    check(
      upgraded.v === 3 && upgraded.phase === "pre",
      "Old match advances to the free-play schema",
    );
    check(!("power" in upgraded.players[0]), "Old Power is removed");
    check(
      !upgraded.players[0].hand.some((c) => hexDef(c).retired) &&
        !upgraded.players[0].deck.some((c) => hexDef(c).retired),
      "Retired Planes leave saved draw/hand zones",
    );
    check(upgraded.players[0].board[0].uid === c.uid, "Migration preserves creatures and identity");
    check(!upgraded.players[0].planes[0].id, "Old basic terrain is cleared");
    check(
      Hex.dispatch({ op: "load", game: upgraded }).state.phase === "pre",
      "Migrated match validates and loads",
    );
  }
  return { checks };
};
