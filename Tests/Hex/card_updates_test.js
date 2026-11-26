"use strict";
globalThis.runCardUpdateTests = () => {
  let checks = 0;
  const check = (ok, message) => {
    checks++;
    if (!ok) throw Error(message);
  };
  const fresh = () => {
    const g = hexNewGame(Hex.starter, Hex.starter, 42);
    Object.assign(g, { turn: 5, active: 0, phase: "pre", tasks: [], stack: [], choice: null });
    for (const p of g.players)
      Object.assign(p, {
        board: Array(6).fill(null),
        hand: [],
        deck: [],
        discard: [],
        artifacts: [null, null],
        losses: 0,
      });
    return g;
  };
  const unit = (g, id, side = 0, slot = 0) => {
    const c = {
      id,
      uid: "changed-" + ++g.serial,
      owner: side,
      originalOwner: side,
      spent: {},
      mods: [],
      shield: 0,
      slot,
      hp: hexDef(id).hp,
      maxHp: hexDef(id).hp,
      playedTurn: 0,
      playedOwnerTurn: 0,
    };
    g.players[side].board[slot] = c;
    return c;
  };
  const settle = (g) => {
    for (
      let n = 0;
      n < 100 && (g.choice || g.stack.length || g.tasks.length) && g.winner === null;
      n++
    ) {
      if (g.choice) hexChoose(g, g.choice.player, 0);
      else if (g.stack.length) hexPass(g, g.stack.at(-1).priority);
      else hexPump(g);
    }
  };
  {
    const g = fresh();
    g.players[0].losses = g.players[1].losses = 5;
    const a = unit(g, "LT-006"),
      b = unit(g, "LT-006", 1),
      protectedMage = unit(g, "SA-037", 1, 1);
    hexArcanaSpell(g, 0, { id: "SA-029" }, {});
    check(
      g.players.every((p) => p.losses === 5) && g.winner === null,
      "Decimate cannot win through defeat count",
    );
    check(
      g.players[0].discard.includes(a) && g.players[1].discard.includes(b),
      "Decimate victims enter normal discard piles",
    );
    check(hexFind(g, protectedMage.uid) === protectedMage, "Ward still blocks Decimate");
    check(
      !hexHasType(a, "Summon") && !hexHasType(b, "Summon"),
      "Loss exemption does not turn real creatures into Summons",
    );
    hexArcanaKill(g, protectedMage);
    check(
      g.players[1].losses === 6 && g.winner === 0,
      "A later ordinary death still counts and can win",
    );
  }
  {
    const g = fresh(),
      victim = unit(g, "LT-006", 1);
    g.players[1].losses = 5;
    hexArcanaSpell(g, 0, { id: "SA-021" }, { target: victim.uid });
    check(
      g.players[1].losses === 5 && g.winner === null,
      "Fade to Nothing does not advance defeat count",
    );
    check(g.players[1].discard.includes(victim), "Fade victim is discarded, not exiled");
    const warded = unit(g, "SA-037", 1);
    hexArcanaSpell(g, 0, { id: "SA-021" }, { target: warded.uid });
    check(hexFind(g, warded.uid) === warded, "Ward still blocks Fade to Nothing");
    hexArcanaSpell(g, 0, { id: "SA-021" }, { target: warded.uid });
    check(
      !hexFind(g, warded.uid) && g.players[1].losses === 5,
      "Successful Fade after Ward expires still exempts the death",
    );
  }
  {
    const g = fresh(),
      jelly = unit(g, "LT-003", 1);
    // Generic death-trigger observers still see deaths exempted from the goal.
    const professor = unit(g, "SA-044", 1, 1),
      mage = unit(g, "SA-045", 1, 2);
    g.players[1].deck = [{ id: "LT-001", uid: "death-draw", owner: 1, spent: {} }];
    hexArcanaSpell(g, 0, { id: "SA-021" }, { target: mage.uid });
    settle(g);
    check(
      g.players[1].hand.some((c) => c.uid === "death-draw"),
      "Professor still draws for an exempted Mage death",
    );
    check(g.players[1].losses === 0, "Triggered card draw does not negate the loss exemption");
    check(
      hexFind(g, professor.uid) && hexFind(g, jelly.uid),
      "Unrelated creatures survive a targeted destruction",
    );
  }
  {
    const g = fresh(),
      a = unit(g, "LT-006"),
      b = unit(g, "LT-006", 0, 1);
    hexArcanaKill(g, a);
    hexArcanaKill(g, b);
    settle(g);
    const before = g.players[0].losses;
    hexElderSpell(g, 0, { id: "WE-044" }, {});
    settle(g);
    const revived = g.players[0].board.filter(Boolean);
    check(revived.length === 2, "Raise the Dead returns all eligible friendly creatures");
    check(
      revived.every((c) => !hexHasType(c, "Summon")),
      "Raise the Dead creatures are not Summons",
    );
    const survivor = revived[1];
    hexArcanaKill(g, revived[0]);
    settle(g);
    check(
      g.players[0].losses === before + 1,
      "A reanimated real creature counts on its next death",
    );
    hexReturn(g, survivor);
    check(g.players[0].hand.includes(survivor), "A reanimated real creature can return to hand");
    check(
      !(g.players[0].exile || []).includes(survivor),
      "Raise the Dead does not cause Summon exile behavior",
    );
  }
  {
    const g = fresh(),
      recluse = unit(g, "SA-045");
    const enemy = unit(g, "SA-044", 1);
    hexArcanaEntry(g, enemy);
    check(!recluse.attackBonus && !recluse.shield, "Enemy Mages do not buff Recluse");
    const friend = unit(g, "SA-044", 0, 1);
    hexArcanaEntry(g, friend);
    check(recluse.attackBonus === 1 && recluse.shield === 1, "Another friendly Mage buffs Recluse");
    hexArcanaEntry(g, recluse);
    check(recluse.attackBonus === 1 && recluse.shield === 1, "Recluse does not trigger itself");
  }
  for (const id of ["SA-021", "SA-029", "SA-045", "WE-044"]) {
    check(HEX_CARD[id + "-FA"].rules === HEX_CARD[id].rules, id + " full art shares revised rules");
    if (HEX_CARD[id + "-IR"])
      check(HEX_CARD[id + "-IR"].rules === HEX_CARD[id].rules, id + " IR shares revised rules");
  }
  return { checks };
};
