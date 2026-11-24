"use strict";
/* Godot command boundary: one mutation per command; UI never computes rules. */
globalThis.Hex = (() => {
  let game = null;
  const starter = [1, 2, 3, 4, 5, 6, 9, 10, 11, 13, 14, 17, 23, 25, 35, 37, 38, 40, 42, 47].map(
    (n) => "LT-" + String(n).padStart(3, "0"),
  );
  function enrich(c) {
    return c
      ? {
          ...c,
          ...(hexType(c, "Creature") && c.hp != null
            ? {
                attack: hexStats(game, c).attack,
                maxHp: hexStats(game, c).maxHp,
                ready: game.phase === "combat" && hexReady(game, c),
                ward: hexWardRemaining(c),
              }
            : {}),
        }
      : null;
  }
  function option(o, index) {
    const t = o.task || o,
      c = hexCardUid(game, t.target || t.take || t.discard || t.uid);
    return { ...o, index, card: c ? enrich(c) : null };
  }
  function view() {
    if (!game) return null;
    const g = game;
    return {
      playerDeck: g.context?.playerDeck || starter,
      encounter: g.context?.encounter || null,
      turn: hexTurnNumber(g),
      tick: g.turn,
      phase: g.phase,
      active: g.active,
      winner: g.winner,
      reason: g.lossReason || g.drawReason || "",
      log: g.log.slice(-40),
      coin: g.coin || null,
      first: g.first,
      players: g.players.map((p, side) => ({
        hand: side === 0 ? p.hand.map(enrich) : [],
        handCount: p.hand.length,
        deckCount: p.deck.length,
        board: p.board.map(enrich),
        artifacts: p.artifacts.map(enrich),
        discard: p.discard.map(enrich),
        exile: (p.exile || []).map(enrich),
        losses: p.losses,
        mulligan: p.mulligan,
      })),
      field: enrich(g.field),
      choice: g.choice ? { ...g.choice, options: g.choice.options.map(option) } : null,
      response: g.stack.length
        ? {
            priority: g.stack.at(-1).priority,
            card: enrich(g.stack.at(-1).job.card),
            trigger: enrich(g.stack.find((f) => f.job.card)?.job.card),
            reactions: hexReactionCards(g, 0).map(enrich),
          }
        : null,
      handOptions: Object.fromEntries(
        g.players[0].hand.map((c) => [c.uid, hexPlayOptions(g, 0, c).map(option)]),
      ),
      activeOptions: hexActiveOptions(g, 0).map(option),
      targets: Object.fromEntries(
        g.players[0].board
          .filter((c) => c && hexReady(g, c))
          .map((c) => [c.uid, hexLegalTargets(g, c).map((t) => t.uid)]),
      ),
      fx: g.fx.filter((f) => f.serial > (g.fxAck || 0)),
    };
  }
  function validate(g) {
    if (
      !g ||
      ![0, 1].includes(g.active) ||
      ![null, -1, 0, 1].includes(g.winner) ||
      ![
        "coin",
        "coinResult",
        "opening",
        "start",
        "pre",
        "combat",
        "resolve",
        "post",
        "end",
        "over",
      ].includes(g.phase) ||
      g.v !== 1 ||
      g.rules?.id !== "standard" ||
      !Array.isArray(g.players) ||
      g.players.length !== 2 ||
      !Array.isArray(g.stack) ||
      !Array.isArray(g.tasks) ||
      !Number.isInteger(g.turn) ||
      g.turn < 0
    )
      throw Error("Unsupported match save");
    for (const p of g.players) {
      if (
        p.board?.length !== 6 ||
        p.artifacts?.length !== 2 ||
        !Array.isArray(p.hand) ||
        !Array.isArray(p.deck) ||
        !Array.isArray(p.discard)
      )
        throw Error("Invalid match zones");
      for (const c of [
        ...p.hand,
        ...p.deck,
        ...p.board,
        ...p.artifacts,
        ...p.discard,
        ...(p.exile || []),
      ].filter(Boolean))
        if (!HEX_CARD[c.id] || !c.uid) throw Error("Unknown saved card");
    }
    return g;
  }
  function deckCheck(cards, draft = false) {
    const errors = [],
      counts = {};
    if (!Array.isArray(cards)) return { valid: false, errors: ["Deck must be a list of cards."] };
    if (draft ? cards.length > 20 : cards.length !== 20)
      errors.push("A Standard deck requires exactly 20 cards.");
    for (const id of cards) {
      const c = HEX_CARD[id];
      if (!c) {
        errors.push("Unknown card: " + id);
        continue;
      }
      const base = c.baseId || id;
      counts[base] = (counts[base] || 0) + 1;
      if (counts[base] > (c.deckLimit || 2))
        errors.push(c.name + ": maximum " + (c.deckLimit || 2) + " copies.");
    }
    return { valid: errors.length === 0, errors: [...new Set(errors)] };
  }
  function dispatch(c) {
    let ok = true;
    switch (c.op) {
      case "deckcheck":
        return deckCheck(c.cards, !!c.draft);
      case "new":
        if (!deckCheck(c.deck || starter).valid) throw Error(deckCheck(c.deck).errors.join(" "));
        game = hexNewGame(
          c.deck || starter,
          hexBotDeck(c.enemy || "thornbound"),
          c.seed ?? Date.now(),
          {
            format: "standard",
            interactiveCoin: true,
            context: {
              opponentAI: "ascended",
              playerDeck: [...(c.deck || starter)],
              ...(c.encounter ? { encounter: c.encounter, practice_game: c.practice || null } : {}),
            },
          },
        );
        break;
      case "load":
        game = validate(c.game);
        game.context = { ...(game.context || {}), opponentAI: "ascended" };
        game.fx = [];
        game.fxAck = game.fxSerial;
        if (game.phase === "opening" && game.players[0].mulligan) hexKeep(game);
        break;
      case "save":
        return { version: 1, game };
      case "catalog":
        return {
          cards: HEX_CARDS,
          keywords: HEX_KEYWORDS,
          starter,
          enemies: Object.keys(HEX_BOT_DECKS).map((id) => ({
            id,
            name: HEX_BOT_NAMES[id],
            rank: hexBotRating(id).rank,
          })),
        };
      case "coin":
        ok = hexCallCoin(game, c.call);
        break;
      case "first":
        ok = hexChooseFirst(game, c.side);
        break;
      case "mulligan":
        ok = hexMulligan(game, 0);
        break;
      case "keep":
        ok = hexKeep(game);
        break;
      case "next":
        ok = hexNext(game, 0);
        break;
      case "play":
        ok = hexPlay(game, 0, c.uid, c.index || 0);
        break;
      case "attack":
        ok = hexDeclare(game, 0, c.attacker, c.target);
        break;
      case "choice":
        ok = hexChoose(game, 0, c.index);
        break;
      case "active":
        ok = hexActivate(game, 0, c.index);
        break;
      case "pass":
        ok = hexPass(game, 0);
        break;
      case "concede":
        ok = hexConcede(game, 0);
        break;
      case "ai": {
        const side = game.choice?.player ?? game.stack.at(-1)?.priority ?? game.active;
        if (side !== 1 || game.winner !== null) ok = false;
        else ok = hexAscendedStep(game, 1);
        if (!ok && side === 1 && game.winner === null)
          throw Error("Opponent could not find a legal move");
        break;
      }
      case "ack":
        game.fxAck = game.fxSerial;
        game.fx = [];
        break;
      case "view":
        break;
      default:
        throw Error("Unknown command");
    }
    return { ok, state: view() };
  }
  return { dispatch, starter };
})();
