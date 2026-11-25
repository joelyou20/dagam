"use strict";
globalThis.runExposureTests = () => {
  let checks = 0;
  const check = (value, message) => {
    checks++;
    if (!value) throw Error(message);
  };
  const fresh = () => {
    const g = hexNewGame(Hex.starter, Hex.starter, 42);
    Object.assign(g, {
      active: 0,
      turn: 5,
      phase: "post",
      winner: null,
      choice: null,
      stack: [],
      tasks: [],
      attacks: [],
    });
    for (const p of g.players)
      Object.assign(p, {
        hand: [],
        board: Array(6).fill(null),
        artifacts: [null, null],
        discard: [],
        exile: [],
        losses: 0,
        exposure: 0,
        power: [],
        planes: Array.from({ length: 6 }, () => hexPlane(["Earth"], 0)),
      });
    return g;
  };
  const unit = (g, side = 1, slot = 0) => {
    const c = {
      id: "LT-006",
      owner: side,
      originalOwner: side,
      slot,
      uid: "ex-" + ++g.serial,
      hp: 4,
      maxHp: 4,
      shield: 0,
      mods: [],
      spent: {},
      playedTurn: 0,
    };
    g.players[side].board[slot] = c;
    return c;
  };
  const end = (g, side) => {
    g.active = side;
    g.phase = "post";
    check(hexNext(g, side), "owner can end turn");
  };
  {
    const g = fresh();
    unit(g);
    for (let n = 1; n <= 3; n++) {
      end(g, 0);
      check(g.players[0].exposure === n, "one Exposure per qualifying owner end");
      check(g.players[0].losses === 0, "Exposure never increases creature deaths");
      if (n < 3) {
        check(g.winner === null, "first two empty ends survive");
        end(g, 1);
        check(g.players[0].exposure === n, "enemy turn does not advance your Exposure");
      }
    }
    check(
      g.winner === 1 && g.lossReason === "exposure" && g.phase === "over",
      "third exposed end loses",
    );
    check(!g.choice && !g.tasks.length && !g.stack.length, "Exposure defeat clears pending work");
  }
  {
    const g = fresh();
    g.players[0].exposure = 2;
    unit(g, 0);
    unit(g, 1);
    end(g, 0);
    check(
      g.players[0].exposure === 0 && g.winner === null,
      "ending with a creature resets all Exposure",
    );
    g.players[0].board[0] = null;
    end(g, 0);
    check(g.players[0].exposure === 1, "next empty streak starts at one");
  }
  {
    const g = fresh();
    g.players[0].exposure = 2;
    g.players[1].exposure = 1;
    end(g, 0);
    check(g.players[0].exposure === 2 && g.winner === null, "both empty holds existing Exposure");
    end(g, 1);
    check(g.players[1].exposure === 1, "both empty holds each owner's count");
  }
  {
    const g = fresh();
    g.players[0].exposure = 2;
    unit(g, 1);
    const c = unit(g, 0);
    c.summoned = true;
    end(g, 0);
    check(g.players[0].exposure === 0, "a surviving Summon can hold the field");
  }
  {
    const g = fresh();
    g.players[0].exposure = 2;
    unit(g, 1);
    const c = unit(g, 0);
    c.summoned = true;
    c.sacrificeAtEnd = g.turn;
    end(g, 0);
    check(
      g.winner === 1 && g.lossReason === "exposure",
      "Doomed Summon disappears before the Exposure check",
    );
    check(g.players[0].losses === 0, "Doomed Summon and Exposure do not count as deaths");
  }
  {
    const g = fresh();
    g.players[0].exposure = 2;
    const enemy = unit(g, 1);
    enemy.hp = 1;
    const original = hexArcanaEnd;
    hexArcanaEnd = function (h) {
      original(h);
      if (h === g) h.tasks.push({ kind: "planeDamage", owner: 1, target: enemy.uid });
    };
    try {
      end(g, 0);
    } finally {
      hexArcanaEnd = original;
    }
    check(!g.players[1].board.some(Boolean), "queued end damage resolves");
    check(
      g.players[0].exposure === 2 && g.winner === null,
      "end triggers can leave both fields empty before Exposure is checked",
    );
  }
  {
    const g = fresh();
    g.players[0].losses = 5;
    g.players[0].exposure = 0;
    const c = unit(g, 0);
    hexArcanaKill(g, c);
    hexPump(g);
    check(
      g.winner === 1 && g.players[0].losses === 6,
      "six non-Summon deaths still lose independently",
    );
    check(g.players[0].exposure === 0, "death defeat does not manufacture Exposure");
  }
  {
    Hex.dispatch({ op: "new", seed: 42 });
    let saved = Hex.dispatch({ op: "save" }).game;
    saved.players[0].exposure = 2;
    saved.players[1].exposure = 1;
    check(
      Hex.dispatch({ op: "load", game: saved }).state.players[0].exposure === 2,
      "save/load preserves two-counter warning",
    );
    saved = Hex.dispatch({ op: "save" }).game;
    for (const p of saved.players) delete p.exposure;
    const state = Hex.dispatch({ op: "load", game: saved }).state;
    check(
      state.players.every((p) => p.exposure === 0),
      "older saves initialize Exposure to zero",
    );
    for (const invalid of [-1, 0.5, 4, "2"]) {
      saved.players[0].exposure = invalid;
      let rejected = false;
      try {
        Hex.dispatch({ op: "load", game: saved });
      } catch (_) {
        rejected = true;
      }
      check(rejected, "invalid Exposure save is rejected: " + invalid);
    }
  }
  {
    const g = fresh();
    g.active = 1;
    g.players[1].exposure = 2;
    unit(g, 0);
    g.players[1].planes = Array.from({ length: 6 }, () => hexPlane(["Light"], 0));
    g.players[1].power = [["Light"]];
    g.players[1].hand = [{ id: "LT-001", uid: "rescue", owner: 1, originalOwner: 1, spent: {} }];
    check(hexAscendedStep(g, 1), "AI can act with Exposure two");
    check(
      g.players[1].board.some(Boolean) && g.winner === null,
      "AI deploys an affordable creature instead of accepting Exposure defeat",
    );
    end(g, 1);
    check(g.players[1].exposure === 0, "AI rescue resets Exposure at turn end");
  }
  {
    const g = fresh();
    g.players[0].losses = 5;
    g.players[0].exposure = 1;
    unit(g, 1);
    end(g, 0);
    check(
      g.winner === null && g.players[0].exposure === 2 && g.players[0].losses === 5,
      "death and Exposure thresholds are never added together",
    );
  }
  return { checks };
};
