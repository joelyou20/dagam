"use strict";
globalThis.HexTests = (() => {
  function assert(x, message) {
    if (!x) throw Error(message);
  }
  function fresh() {
    const g = hexNewGame(Hex.starter, Hex.starter, 42);
    Object.assign(g, {
      turn: 5,
      phase: "pre",
      active: 0,
      tasks: [],
      stack: [],
      choice: null,
      attacks: [],
      winner: null,
    });
    for (const p of g.players)
      Object.assign(p, {
        hand: [],
        deck: [],
        board: Array(6).fill(null),
        artifacts: [null, null],
        discard: [],
        losses: 0,
        power: Array.from({ length: 40 }, () => [...HEX_TERRAINS]),
        planes: Array.from({ length: 6 }, () => hexPlane(HEX_TERRAINS, 0)),
      });
    return g;
  }
  function card(g, id, p = 0) {
    return { id, owner: p, originalOwner: p, uid: "test-" + ++g.serial, spent: {} };
  }
  function unit(g, id, p = 0, slot = 0) {
    const c = card(g, id, p),
      d = hexDef(c);
    Object.assign(c, {
      slot,
      hp: d.hp,
      maxHp: d.hp,
      shield: 0,
      mods: [],
      playedTurn: 0,
      playedOwnerTurn: 0,
    });
    g.players[p].board[slot] = c;
    return c;
  }
  function settle(g, target) {
    for (
      let i = 0;
      i < 100 && g.winner === null && (g.choice || g.stack.length || g.tasks.length);
      i++
    ) {
      if (g.choice) {
        const index = g.choice.options.findIndex((o) => o.task.target === target);
        hexChoose(g, g.choice.player, index < 0 ? 0 : index);
      } else if (g.stack.length) hexPass(g, g.stack.at(-1).priority);
      else hexPump(g);
    }
    assert(!g.choice && !g.stack.length && !g.tasks.length, "unsettled effect");
  }
  function regressions() {
    let tests = 0;
    const test = (name, fn) => {
      fn();
      tests++;
    };
    test("catalogue", () => {
      assert(HEX_CARDS.length === 186, "186 base cards");
      for (const c of HEX_CARDS) {
        assert(HEX_CARD[c.id + "-FA"].rules === c.rules, "finish rules");
        assert(HEX_CARD[c.id + "-FA"].attack === c.attack, "finish stats");
      }
      assert(Hex.starter.length === 30, "starter");
      assert(!HEX_FORMATS.blitz, "standard only");
    });
    test("Loriadre", () => {
      assert(hexDef("WE-045").attack === 5 && hexDef("WE-045").hp === 3, "5/3");
      const g = fresh();
      unit(g, "WE-045");
      const ally = unit(g, "WE-008", 0, 1),
        enemy = unit(g, "WE-008", 1);
      hexArcanaKill(g, ally);
      settle(g, enemy.uid);
      assert(enemy.hp === 4, "one damage");
      const hurt = unit(g, "WE-008", 0, 1);
      hurt.hp = 2;
      g.players[0].deck = [card(g, "LT-001")];
      hexArcanaKill(g, enemy);
      settle(g, hurt.uid);
      assert(hurt.hp === 3 && g.players[0].hand.length === 0, "heal instead of draw");
    });
    test("Ward counts", () => {
      const g = fresh(),
        c = unit(g, "LT-001");
      assert(hexWardRemaining(c) === 1, "initial Ward");
      hexAffect(g, 1, c, () => hexHeal(g, c, 1));
      assert(hexWardRemaining(c) === 0, "Ward consumed");
      g.turn += 2;
      assert(hexWardRemaining(c) === 0, "Ward does not refresh");
    });
    test("summons and original owner", () => {
      const g = fresh(),
        c = unit(g, "WE-008");
      c.summoned = true;
      hexArcanaKill(g, c);
      settle(g);
      assert(
        g.players[0].losses === 0 &&
          g.players[0].discard.length === 0 &&
          g.players[0].exile.some((a) => a.uid === c.uid),
        "Summon removed",
      );
      const taken = unit(g, "WE-008", 0);
      taken.originalOwner = 1;
      hexArcanaKill(g, taken);
      settle(g);
      assert(
        g.players[1].discard.some((a) => a.uid === taken.uid),
        "original discard owner",
      );
    });
    test("Obelisk", () => {
      const g = fresh();
      g.players[1].artifacts[0] = card(g, "WE-028", 1);
      const c = card(g, "WE-008");
      g.players[0].hand = [c];
      hexPlay(g, 0, c.uid, 0);
      settle(g);
      g.turn = 7;
      assert(!hexReady(g, c), "skip eligible combat");
      g.turn = 9;
      assert(hexReady(g, c), "Stun expires");
    });
    test("mandatory attack", () => {
      const g = fresh();
      g.phase = "combat";
      const c = unit(g, "WE-013");
      c.hp = 1;
      unit(g, "LT-008", 1);
      assert(!hexNext(g, 0), "cannot skip forced attack");
      assert(hexAscendedStep(g, 0), "AI takes forced attack");
    });
    test("Hawk repeat", () => {
      const g = fresh();
      g.players[0].hand = [card(g, "WE-017")];
      for (let i = 0; i < 80 && g.phase === "pre"; i++)
        assert(hexAscendedStep(g, g.choice?.player ?? g.active), "bot moves");
      assert(g.phase !== "pre", "no Hawk loop");
    });
    test("round cap", () => {
      const g = fresh();
      g.turn = 119;
      hexBeginTurn(g);
      assert(g.turn === 120 && g.winner === null, "last full turn");
      hexBeginTurn(g);
      assert(g.winner === -1 && g.drawReason === "roundLimit", "draw");
    });
    test("empty fields", () => {
      const g = fresh();
      g.phase = "post";
      hexNext(g, 0);
      assert(g.winner === null, "both empty survives");
      const h = fresh();
      h.phase = "post";
      unit(h, "WE-008", 1);
      hexNext(h, 0);
      assert(
        h.winner === null && h.players[0].exposure === 1,
        "first empty turn gains Exposure instead of losing",
      );
    });
    test("post-combat play", () => {
      const g = fresh();
      g.phase = "post";
      const c = card(g, "LT-006");
      g.players[0].hand = [c];
      assert(hexPlayOptions(g, 0, c).length === 6, "six slots");
      assert(hexPlay(g, 0, c.uid, 0), "post play");
    });
    test("Decimate turn three", () => {
      const g = fresh(),
        c = card(g, "SA-029");
      g.players[0].hand = [c];
      g.turn = 3;
      assert(!hexPlayOptions(g, 0, c).length, "round two blocked");
      g.turn = 5;
      assert(hexPlayOptions(g, 0, c).length, "round three allowed");
    });
    return { passed: tests };
  }
  function match(enemy, seed) {
    const g = hexNewGame(Hex.starter, hexBotDeck(enemy), seed, {
      context: { opponentAI: "ascended" },
    });
    hexKeep(g);
    let steps = 0;
    while (g.winner === null && steps++ < 1800) {
      const side = g.choice?.player ?? g.stack.at(-1)?.priority ?? g.active;
      assert(hexAscendedStep(g, side), "no action: " + enemy);
      g.fx = [];
      g.log = g.log.slice(-5);
    }
    assert(g.winner !== null, "unfinished " + enemy);
    return { enemy, seed, steps, winner: g.winner, round: hexTurnNumber(g) };
  }
  function coverage(id, index) {
    if (id === "FD-025") {
      const h = fresh(),
        eruption = card(h, "FD-024");
      h.players[0].hand = [eruption];
      assert(hexPlay(h, 0, eruption.uid, 0), "Vent creation");
      settle(h);
      assert(h.players[1].planes[0].id === id, "Vent created by Erupt");
      return { id, included: true, played: true, resolved: true, generated: true };
    }
    const deck = Hex.starter.slice();
    if (!deck.includes(id)) deck[0] = id;
    const g = hexNewGame(deck, hexBotDeck("thornbound"), 81000 + index);
    g.first = g.active = 0;
    const p = g.players[0];
    if (!p.hand.some((c) => c.id === id)) {
      const i = p.deck.findIndex((c) => c.id === id);
      assert(i >= 0, "coverage card missing");
      p.deck.push(p.hand.pop());
      p.hand.push(p.deck.splice(i, 1)[0]);
    }
    hexKeep(g);
    let played = false,
      resolved = false,
      steps = 0;
    const play = hexPlay,
      execute = hexExecuteTask;
    hexPlay = function (h, side, uid, i) {
      const c = h.players[side].hand.find((c) => c.uid === uid),
        r = play(h, side, uid, i);
      if (h === g && side === 0 && c?.id === id && r) {
        played = true;
        if (hexType(c, "Plane")) resolved = true;
      }
      return r;
    };
    hexExecuteTask = function (h, j) {
      const r = execute(h, j);
      if (h === g && j.owner === 0 && j.card?.id === id && ["play", "special"].includes(j.kind))
        resolved = true;
      return r;
    };
    try {
      while (g.winner === null && steps++ < 1000) {
        const side = g.choice?.player ?? g.stack.at(-1)?.priority ?? g.active;
        for (const pl of g.players) {
          pl.power = Array.from({ length: 40 }, () => [...HEX_TERRAINS]);
          pl.planes = Array.from({ length: 6 }, () => hexPlane(HEX_TERRAINS, 0));
        }
        let acted = false;
        if (side === 0 && !played && !g.choice) {
          const c = p.hand.find((c) => c.id === id),
            options = c ? hexPlayOptions(g, 0, c) : [];
          if (options.length) acted = hexPlay(g, 0, c.uid, 0);
        }
        if (!acted) assert(hexClassicBotStep(g, side), "coverage action " + id);
        g.fx = [];
        g.log = g.log.slice(-5);
      }
    } finally {
      hexPlay = play;
      hexExecuteTask = execute;
    }
    return { id, included: true, played, resolved, winner: g.winner };
  }
  function conditionals() {
    const results = [];
    const respond = (g, c) => {
      const options = hexPlayOptions(g, c.owner, c);
      assert(options.length, "no response " + c.id);
      assert(hexPlay(g, c.owner, c.uid, 0), "response failed " + c.id);
      settle(g);
      assert(
        g.players[c.owner].discard.some((t) => t.uid === c.uid),
        "response unresolved " + c.id,
      );
      results.push({ id: c.id, played: true, resolved: true });
    };
    {
      const g = fresh(),
        c = card(g, "LT-033"),
        ally = unit(g, "WE-008"),
        source = card(g, "LT-028", 1);
      g.players[0].hand = [c];
      source.embers = 3;
      g.players[1].artifacts[0] = source;
      g.active = 1;
      hexExecute(g, { kind: "emberShot", owner: 1, source: source.uid, target: ally.uid });
      hexPump(g);
      respond(g, c);
    }
    {
      const g = fresh(),
        c = card(g, "LT-046"),
        spell = card(g, "SA-002", 1);
      unit(g, "WE-008");
      unit(g, "WE-010", 0, 1);
      g.players[0].hand = [c];
      g.players[1].hand = [spell];
      g.active = 1;
      hexPlay(g, 1, spell.uid, 0);
      respond(g, c);
    }
    {
      const g = fresh(),
        c = card(g, "LT-064"),
        artifact = card(g, "LT-025", 1);
      g.players[0].hand = [c];
      g.players[1].hand = [artifact];
      g.active = 1;
      hexPlay(g, 1, artifact.uid, 0);
      respond(g, c);
    }
    {
      const g = fresh(),
        c = card(g, "SA-004"),
        dead = unit(g, "WE-008");
      hexArcanaKill(g, dead);
      settle(g);
      g.players[0].hand = [c];
      respond(g, c);
    }
    {
      const g = fresh(),
        c = card(g, "WE-038"),
        artifact = card(g, "LT-025", 1);
      g.players[1].discard = [artifact];
      g.players[0].hand = [c];
      respond(g, c);
    }
    {
      const g = fresh(),
        c = card(g, "WE-041"),
        copy = card(g, "SA-010", 1);
      unit(g, "SA-038", 1);
      g.players[0].hand = [c];
      g.players[1].hand = [copy];
      g.active = 1;
      hexPlay(g, 1, copy.uid, 0);
      respond(g, c);
    }
    {
      const g = fresh(),
        c = card(g, "WE-036"),
        ally = unit(g, "WE-008");
      g.players[0].hand = [c];
      g.players[0].deck = [card(g, "LT-002"), card(g, "LT-004"), card(g, "LT-006")];
      respond(g, c);
      assert(ally.hp === 3 && g.players[0].hand.length === 3, "Blood for Blood damage/draw");
    }
    {
      const g = fresh(),
        c = card(g, "SA-016");
      unit(g, "WE-008");
      g.players[0].hand = [c];
      respond(g, c);
    }
    return results;
  }
  return { regressions, match, coverage, conditionals };
})();
("ready");
