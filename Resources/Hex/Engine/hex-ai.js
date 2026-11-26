"use strict";
/* A rule-based opponent: legal actions, public combat evaluation, own hand only. */
const HEX_BOT_DECKS = {
  thornbound: [
    1,
    6,
    10,
    10,
    11,
    11,
    "SA-037",
    17,
    24,
    29,
    29,
    31,
    34,
    47,
    "SA-009",
    57,
    58,
    "SA-032",
    "SA-018",
    1,
  ],
  stormcourt: [
    3,
    12,
    12,
    15,
    18,
    19,
    20,
    21,
    "SA-043",
    26,
    26,
    36,
    41,
    "SA-035",
    40,
    "SA-034",
    "SA-003",
    "SA-006",
    60,
    64,
  ],
  gravekeepers: [
    2,
    7,
    8,
    9,
    9,
    13,
    21,
    24,
    "SA-042",
    29,
    30,
    30,
    28,
    35,
    "SA-004",
    "SA-015",
    49,
    53,
    "SA-023",
    "SA-033",
  ],
  dawnchorus: [
    1,
    1,
    4,
    6,
    10,
    10,
    11,
    15,
    17,
    17,
    24,
    "SA-038",
    31,
    38,
    44,
    47,
    51,
    "SA-009",
    "SA-018",
    "SA-007",
  ],
  cinderforge: [
    2,
    7,
    7,
    8,
    13,
    13,
    14,
    16,
    "SA-040",
    24,
    26,
    32,
    32,
    28,
    34,
    45,
    49,
    "SA-017",
    "SA-033",
    "SA-002",
  ],
  tidecallers: [
    1,
    3,
    12,
    15,
    17,
    17,
    18,
    18,
    19,
    20,
    21,
    24,
    "SA-003",
    "SA-008",
    40,
    42,
    44,
    "SA-006",
    "SA-035",
    "SA-043",
  ],
  skyward: [
    1,
    4,
    5,
    11,
    12,
    15,
    18,
    18,
    "SA-038",
    26,
    36,
    36,
    41,
    34,
    38,
    40,
    47,
    "SA-014",
    "SA-028",
    "SA-009",
  ],
  ironclad: [
    1,
    2,
    "SA-046",
    6,
    8,
    8,
    10,
    11,
    16,
    24,
    24,
    26,
    23,
    34,
    38,
    "SA-024",
    47,
    53,
    "SA-016",
    "SA-030",
  ],
  hoardkeepers: [
    1,
    4,
    5,
    5,
    6,
    10,
    14,
    17,
    24,
    "SA-044",
    29,
    30,
    "SA-032",
    31,
    34,
    38,
    47,
    53,
    "SA-011",
    "SA-028",
  ],
  wildhunt: [
    1,
    "SA-040",
    5,
    6,
    7,
    11,
    13,
    13,
    14,
    14,
    16,
    20,
    "SA-046",
    22,
    26,
    34,
    "SA-014",
    "SA-002",
    "SA-005",
    1,
  ],
  meadowfolk: [
    4,
    4,
    9,
    9,
    10,
    10,
    17,
    17,
    27,
    27,
    29,
    51,
    51,
    23,
    "SA-007",
    35,
    "SA-009",
    43,
    "SA-006",
    29,
  ],
  reedwatch: [
    1,
    1,
    4,
    4,
    "SA-037",
    10,
    17,
    17,
    19,
    27,
    27,
    29,
    29,
    51,
    23,
    "SA-009",
    38,
    "SA-007",
    55,
    "SA-006",
  ],
  moonkeepers: [
    1,
    4,
    4,
    6,
    10,
    17,
    19,
    19,
    "SA-043",
    27,
    36,
    41,
    "SA-006",
    38,
    "SA-034",
    "SA-028",
    52,
    55,
    "SA-011",
    1,
  ],
  amberguard: [
    1,
    2,
    2,
    6,
    11,
    11,
    "SA-037",
    21,
    24,
    26,
    26,
    34,
    "SA-016",
    38,
    "SA-030",
    47,
    53,
    "SA-021",
    62,
    1,
  ],
  fuseworks: [
    1,
    "SA-040",
    7,
    11,
    13,
    13,
    14,
    24,
    26,
    32,
    32,
    28,
    34,
    "SA-002",
    45,
    "SA-012",
    53,
    "SA-033",
    "SA-020",
    1,
  ],
  mosskin: [
    29,
    29,
    10,
    10,
    17,
    17,
    1,
    1,
    11,
    11,
    "SA-037",
    6,
    31,
    31,
    47,
    47,
    "SA-018",
    "SA-024",
    59,
    "SA-009",
  ],
  auroracourt: [
    1,
    2,
    12,
    12,
    15,
    18,
    18,
    "SA-043",
    24,
    26,
    26,
    34,
    "SA-003",
    47,
    53,
    "SA-008",
    "SA-034",
    62,
    "SA-035",
    1,
  ],
  eternalcourt: [
    1,
    8,
    "SA-042",
    12,
    17,
    24,
    26,
    30,
    30,
    "SA-047",
    31,
    "SA-028",
    47,
    47,
    53,
    "SA-004",
    "SA-031",
    62,
    1,
    8,
  ],
  skytyrants: [
    8,
    8,
    12,
    12,
    15,
    15,
    "SA-047",
    18,
    24,
    "SA-044",
    "SA-033",
    53,
    47,
    47,
    53,
    "SA-035",
    "SA-029",
    24,
    26,
    34,
  ],
  crownimperium: [
    30,
    30,
    12,
    12,
    8,
    8,
    24,
    24,
    15,
    15,
    18,
    18,
    "SA-047",
    26,
    "SA-044",
    6,
    "SA-028",
    47,
    "SA-031",
    53,
  ],
};
const HEX_BOT_NAMES = {
  thornbound: "Thornbound",
  stormcourt: "Stormcourt",
  gravekeepers: "Gravekeepers",
  dawnchorus: "Dawn Chorus",
  cinderforge: "Cinderforge",
  tidecallers: "Tidecallers",
  skyward: "Skyward",
  ironclad: "Ironclad",
  hoardkeepers: "Hoardkeepers",
  wildhunt: "Wild Hunt",
  meadowfolk: "Meadowfolk",
  reedwatch: "Reedwatch",
  moonkeepers: "Moonkeepers",
  amberguard: "Amberguard",
  fuseworks: "Fuseworks",
  mosskin: "Mosskin",
  auroracourt: "Aurora Court",
  eternalcourt: "Eternal Court",
  skytyrants: "Sky Tyrants",
  crownimperium: "Crown Imperium",
};
function hexBotDeck(name = "thornbound", format = "standard") {
  if (HEX_RESOURCE_DECKS[name]) return [...HEX_RESOURCE_DECKS[name]];
  let cards = (HEX_BOT_DECKS[name] || HEX_BOT_DECKS.thornbound).map((n) =>
    typeof n === "number" ? hexId(n) : n,
  );
  if (format === "blitz" && cards.every((id) => HEX_CARD[id].set !== "war-on-elderberry")) {
    const arcana = cards.filter((id) => HEX_CARD[id].set === "shattered-arcana"),
      light = cards.filter((id) => HEX_CARD[id].set === "first-light");
    cards = [];
    for (let i = 0; i < Math.max(arcana.length, light.length); i++) {
      if (light[i]) cards.push(light[i]);
      if (arcana[i]) cards.push(arcana[i]);
    }
  }
  return hexDevelopDeck(hexTrimDeck(cards, format).slice(0, 20));
}
function hexBotView(g, side = 1) {
  const p = g.players[side],
    e = g.players[1 - side];
  return {
    hand: p.hand.map((c) => ({
      uid: c.uid,
      id: c.id,
      blockedUntil: c.blockedUntil,
    })),
    board: p.board,
    enemyBoard: e.board,
    artifacts: p.artifacts,
    enemyArtifacts: e.artifacts,
    enemyHandCount: e.hand.length,
    deckCount: p.deck.length,
    enemyDeckCount: e.deck.length,
    field: g.field,
    losses: [e.losses, p.losses],
    phase: g.phase,
  };
}
function hexBotChoiceScore(g, option) {
  const t = option.task || {},
    target = t.target ? hexFind(g, t.target) : null;
  if (option.label === "Skip") return -1;
  if (t.kind === "elderberry") return hexElderBotChoice(g, option);
  if (t.kind === "arcana") return hexArcanaChoiceScore(g, option);
  if (["emberShot", "eelDrain"].includes(t.kind))
    return target ? 8 + (target.hp <= 2 ? 12 : 0) + hexStats(g, target).attack : 0;
  if (["refresh", "fieldHeal", "garden", "dawnCleanse"].includes(t.kind))
    return target
      ? 3 +
          (target.maxHp - target.hp) +
          (target.burn ? 4 : 0) +
          (target.stunUntil >= g.turn ? 4 : 0)
      : 0;
  if (t.kind === "debuff") return target ? hexStats(g, target).attack * 3 : 0;
  if (t.kind === "shieldCurse") return target ? target.shield || 0 : 0;
  if (t.kind === "returnEnemy") return target ? hexStats(g, target).attack + target.hp : 0;
  if (t.kind === "hoardTake") return t.target ? 8 : 0;
  if (["scryPair", "reorderTop"].includes(t.kind)) {
    const c = hexCardUid(g, t.keep);
    return c ? hexBotCardValue(g, c) : 0;
  }
  if (t.kind === "bottomOne") return 0;
  if (t.kind === "raise") {
    const c = hexCardUid(g, t.target),
      cost = hexCardUid(g, t.discard);
    return (c ? hexBotCardValue(g, c) : 0) - (cost ? hexBotCardValue(g, cost) : 0);
  }
  if (t.kind === "cycle" || t.kind === "bell") {
    const cost = hexCardUid(g, t.discard);
    return 5 - (cost ? hexBotCardValue(g, cost) : 0) + (t.kind === "bell" ? 4 : 0);
  }
  if (t.kind === "swapEnemy") {
    const a = g.players[0].board[t.column],
      b = g.players[0].board[t.column + hexColumns(g)];
    return a && b ? a.hp - b.hp + hexStats(g, b).attack : 0;
  }
  return 1;
}
function hexBotCardValue(g, c) {
  const def = hexDef(c);
  if (def.card_type === "Plane") return 12;
  if (def.card_type === "Creature")
    return (
      hexDailyBase(g, c).attack * 1.5 +
      hexDailyBase(g, c).hp +
      (g.players[1].board.filter(Boolean).length < 3 ? 3 : 0)
    );
  if (def.subtype === "Equipment") return 5;
  if (def.subtype === "Artifact") return 4;
  return 3;
}
function hexClassicBotStep(g, side = 1) {
  if (g.winner !== null) return false;
  if (g.choice) {
    if (g.choice.player !== side) return false;
    const scores = g.choice.options.map((o) => hexBotChoiceScore(g, o)),
      best = scores.indexOf(Math.max(...scores));
    return hexChoose(g, side, best);
  }
  const response = g.stack.at(-1);
  if (response) {
    if (response.priority !== side) return false;
    const cards = hexReactionCards(g, side);
    if (cards.length) {
      const c = cards[0],
        options = hexSpecialOptions(g, side, c, response);
      let best = 0,
        score = -Infinity;
      options.forEach((o, i) => {
        const t = hexFind(g, o.target),
          value =
            o.mode === "damage"
              ? t && t.hp <= 1
                ? 20
                : 5
              : o.mode === "heal"
                ? t
                  ? t.maxHp - t.hp
                  : 0
                : 8;
        if (value > score) {
          score = value;
          best = i;
        }
      });
      return hexPlay(g, side, c.uid, best);
    }
    return hexPass(g, side);
  }
  if (g.phase === "opening" || g.active !== side) return false;
  if (g.phase === "combat") {
    const forced = g.players[side].board.find(
      (c) => c && hexElderNum(c) === 13 && hexReady(g, c) && hexLegalTargets(g, c).length,
    );
    if (forced) {
      const target = hexLegalTargets(g, forced).sort((a, b) => a.hp - b.hp)[0];
      return hexDeclare(g, side, forced.uid, target.uid);
    }
  }
  const view = hexBotView(g, side),
    pl = g.players[side];
  if (["pre", "post"].includes(g.phase)) {
    const actions = [];
    for (const c of view.hand) {
      if (hexIsReaction(c)) continue;
      // With no companion, Hawk can only return itself and lose its tempo.
      if (hexElderNum(c) === 17 && !g.players[side].board.some(Boolean)) continue;
      const options = hexPlayOptions(g, side, c);
      for (const [i, o] of options.entries()) {
        if (hexBotPlayRepeated(g, side, c.uid, i)) continue;
        let score = hexBotCardValue(g, c);
        if (hexType(c, "Spell")) score = hexArcanaBotScore(g, side, c, o);
        if (hexType(c, "Creature")) {
          const rear = [4, 15, 18, 22, 36, 219].includes(hexNum(c)),
            back = o.slot >= hexColumns(g);
          score += (rear === back ? 3 : 0) + (back && pl.board[o.slot - hexColumns(g)] ? 2 : 0);
        }
        if (hexDef(c).subtype === "Equipment") {
          const target = hexFind(g, o.target);
          score += target ? hexStats(g, target).attack + target.hp * 0.2 : 0;
          if (target?.eq) score -= 7;
        }
        if (hexDef(c).subtype === "Artifact" && pl.artifacts[o.slot]) score = -5;
        if (hexType(c, "Battlefield")) score = g.field && hexNum(g.field) === hexNum(c) ? -5 : 2;
        actions.push({ uid: c.uid, index: i, score });
      }
    }
    const active = hexActiveOptions(g, side);
    active.forEach((o, i) => {
      if (["raise", "shatter"].includes(o.task.kind) || o.task.kind === "elderberry")
        actions.push({ active: i, score: hexBotChoiceScore(g, o) + 5 });
    });
    const best = actions.sort((a, b) => b.score - a.score)[0];
    if (best && best.score > 0)
      return best.active != null
        ? hexActivate(g, side, best.active)
        : hexBotPlay(g, side, best.uid, best.index);
    return hexNext(g, side);
  }
  if (g.phase === "combat") {
    const attacks = [];
    for (const a of pl.board.filter((c) => c && hexReady(g, c)))
      for (const t of hexLegalTargets(g, a)) {
        if (hexNum(a) === 8 && t.slot >= hexColumns(g)) continue;
        const atk = hexStats(g, a).attack,
          def = hexStats(g, t).attack,
          allocated = g.attacks
            .filter((x) => x.target === t.uid && !x.canceled && !x.resolved)
            .reduce((n, x) => {
              const c = hexFind(g, x.attacker);
              return n + (c ? hexStats(g, c).attack : 0);
            }, 0),
          needed = t.hp + (t.shield || 0) - allocated;
        const kill = atk >= needed,
          survive = a.hp + (a.shield || 0) > def;
        let score =
          (kill ? 12 : 0) +
          (survive ? 4 : -3) +
          Math.min(atk, Math.max(0, needed)) +
          def * 0.2 -
          (needed <= 0 ? 20 : 0);
        attacks.push({ a: a.uid, t: t.uid, score });
      }
    const best = attacks
      .sort((a, b) => b.score - a.score)
      .find((a) => hexAttackWorthwhile(g, side, a.a, a.t));
    if (best) return hexDeclare(g, side, best.a, best.t);
    return hexNext(g, side);
  }
  if (g.phase === "post") return hexNext(g, side);
  return false;
}
