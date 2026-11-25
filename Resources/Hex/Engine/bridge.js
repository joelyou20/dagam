"use strict";
/* Godot command boundary: one mutation per command; UI never computes rules. */
globalThis.Hex = (() => {
  let game = null;
  const starter = hexDevelopDeck([
    "WE-001",
    "WE-001",
    "LT-001",
    "LT-001",
    "LT-006",
    "LT-006",
    "LT-010",
    "LT-010",
    "LT-014",
    "LT-014",
    "LT-029",
    "LT-029",
    "LT-027",
    "LT-027",
    "LT-047",
    "LT-047",
    "LT-034",
    "LT-034",
    "LT-059",
    "LT-059",
  ]);
  // Presentation metadata only: read current rules state without mutating it.
  function statuses(c) {
    if (c.hp == null) return [];
    const result = [];
    const add = (id, name, description, amount = 0) =>
      result.push({ id, name, description, amount });
    const active = (key) => c[key] != null && c[key] >= game.turn;
    if (c.shield > 0) add("shield", "Shield", "Absorbs incoming damage.", c.shield);
    const ward = hexWardRemaining(c);
    if (ward > 0) add("ward", "Ward", "Blocks this many hostile effects; does not refresh.", ward);
    if (active("stunUntil")) add("stun", "Stunned", "Cannot attack while stunned.");
    if (c.burn) add("burn", "Burning", "Takes 2 damage at the start of its next owner turn.");
    if (c.invisibleUntil != null)
      add("invisible", "Invisible", "Cannot be directly targeted by attacks or effects.");
    if (active("tauntUntil")) add("taunt", "Taunt", "Enemies must attack a creature with Taunt.");
    if (active("reflectUntil"))
      add("reflect", "Reflect", "Reflects damage absorbed by Shield back to its source.");
    if (active("noShieldUntil")) add("no-shield", "Shield blocked", "Cannot gain Shield.");
    if (active("zeroAttackUntil"))
      add("zero-attack", "Attack suppressed", "Attack is reduced to zero.");
    if (active("amberUntil") && active("stunUntil"))
      add("amber", "Amber protection", "Takes 1 less damage while stunned.");
    if (c.control) add("control", "Controlled", "Temporarily controlled by the opposing player.");
    if (c.sacrificeAtEnd != null)
      add("sacrifice", "Doomed", "Will be sacrificed at the end of the turn.");
    if (c.enraptureDue != null)
      add("delayed-stun", "Enraptured", "Will be stunned at the start of its next owner turn.");
    if (c.scars > 0) add("scars", "Scarred", "Maximum HP reduced.", c.scars);
    const attack = (c.mods || [])
      .filter((m) => m.until >= game.turn)
      .reduce((sum, m) => sum + (m.attack || 0), c.attackBonus || 0);
    const health = (c.mods || [])
      .filter((m) => m.until >= game.turn)
      .reduce((sum, m) => sum + (m.maxHp || 0), 0);
    if (attack) add("attack", "Attack modifier", "Current bonus or penalty to Attack.", attack);
    if (health) add("health", "Health modifier", "Current bonus or penalty to maximum HP.", health);
    for (const [key, name, description] of [
      ["fuses", "Fuse", "Explodes when a second Fuse is applied."],
      ["charge", "Charge", "Each charge may be spent for +2 damage on an attack."],
      ["pebbles", "Pebbles", "Remaining stones available to throw."],
      ["gold", "Gold", "Accumulated healing available on combat death."],
      ["channel", "Channel", "Growing Attack bonus granted to the creature in front."],
    ]) {
      if (c[key] > 0) add(key, name, description, c[key]);
    }
    const grants = new Map();
    for (const grant of c.grants || []) {
      if (grant.until >= game.turn)
        grants.set(grant.id, Math.max(grants.get(grant.id) || 0, grant.value || 1));
    }
    for (const [id, value] of grants) {
      const name = id
        .split("-")
        .map((word) => word[0].toUpperCase() + word.slice(1))
        .join(" ");
      const keyword = HEX_KEYWORDS.find((entry) => entry.id === id);
      add(
        "grant-" + id,
        name,
        keyword?.description || "Temporarily granted ability.",
        value > 1 ? value : 0,
      );
    }
    return result;
  }
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
                statuses: statuses(c),
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
        planes: p.planes,
        power: p.power,
        planePlayed: p.planePlayed,
        losses: p.losses,
        exposure: p.exposure || 0,
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
      handReasons: Object.fromEntries(
        g.players[0].hand.map((c) => [
          c.uid,
          hexPowerPayment(g, 0, c) === null
            ? "Not enough matching Power."
            : hexType(c, "Plane") && g.players[0].planePlayed
              ? "You have already played a Plane this turn."
              : hexType(c, "Creature") &&
                  !g.players[0].board.some((t, slot) => !t && hexCompatible(g, c, 0, slot))
                ? "No empty compatible hex. Change a Plane or free a matching hex."
                : "This card cannot be played in the current phase or response window.",
        ]),
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
        "power",
        "pre",
        "combat",
        "resolve",
        "post",
        "end",
        "over",
      ].includes(g.phase) ||
      g.v !== 2 ||
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
      // Saves from before Exposure start safely at zero; never infer past turns.
      if (p.exposure == null) p.exposure = 0;
      if (!Number.isInteger(p.exposure) || p.exposure < 0 || p.exposure > 3)
        throw Error("Invalid Exposure count");
      if (
        !Array.isArray(p.power) ||
        p.planes?.length !== 6 ||
        p.board?.length !== 6 ||
        p.artifacts?.length !== 2 ||
        !Array.isArray(p.hand) ||
        !Array.isArray(p.deck) ||
        !Array.isArray(p.discard)
      )
        throw Error("Invalid match zones");
      if (
        p.planes.some(
          (h) =>
            !h ||
            !Array.isArray(h.types) ||
            !h.types.length ||
            h.types.some((t) => !HEX_TERRAINS.includes(t)) ||
            !Number.isInteger(h.level) ||
            h.level < 0,
        ) ||
        p.power.some(
          (s) => !Array.isArray(s) || !s.length || s.some((t) => !HEX_TERRAINS.includes(t)),
        )
      )
        throw Error("Invalid Plane or Power state");
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
    if (draft ? cards.length > 30 : cards.length !== 30)
      errors.push("A Standard deck requires exactly 30 cards.");
    for (const id of cards) {
      const c = HEX_CARD[id];
      if (!c) {
        errors.push("Unknown card: " + id);
        continue;
      }
      if (c.generated_only)
        errors.push(c.name + " is created by an effect and cannot enter a deck.");
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
      case "developdeck":
        return { cards: hexDevelopDeck(c.cards) };
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
        game = validate(hexMigratePowerSave(c.game));
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
