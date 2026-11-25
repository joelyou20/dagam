"use strict";
const HEX_TERRAINS = ["Earth", "Sky", "Fire", "Water", "Dark", "Light"];
const hexFoundation = (c) => (hexDef(c)?.set === "foundations" ? hexDef(c).number : 0);
const hexPlane = (types = ["Earth"], level = 0, extra = {}) => ({
  types: [...types],
  level,
  ...extra,
});
const hexCompatible = (g, c, side, slot) => {
  const needs = hexDef(c).terrain_types || HEX_TERRAINS;
  return needs.some((t) => g.players[side].planes[slot].types.includes(t));
};
// Flexible spheres are individual resources. Backtracking avoids spending a dual
// sphere when a single-colour sphere can pay the same part of the cost.
function hexPowerPayment(g, side, card) {
  const pool = g.players[side].power;
  const needs = Object.entries(hexDef(card).cost || {}).flatMap(([type, count]) =>
    Array(count).fill(type),
  );
  if (
    pool.length < needs.length ||
    needs.some(
      (t) => pool.filter((s) => s.includes(t)).length < needs.filter((n) => n === t).length,
    )
  )
    return null;
  needs.sort(
    (a, b) => pool.filter((s) => s.includes(a)).length - pool.filter((s) => s.includes(b)).length,
  );
  function pay(i, used) {
    if (i === needs.length) return used;
    const candidates = pool
      .map((s, index) => ({ s, index }))
      .filter(({ s, index }) => !used.includes(index) && s.includes(needs[i]))
      .sort((a, b) => a.s.length - b.s.length);
    for (const { index } of candidates) {
      const result = pay(i + 1, [...used, index]);
      if (result) return result;
    }
    return null;
  }
  return pay(0, []);
}
function hexGeneratePower(g, side) {
  const pl = g.players[side];
  pl.power = pl.planes.flatMap((h) => Array.from({ length: h.level }, () => [...h.types]));
  pl.planePlayed = false;
  hexLog(g, hexOwnerLabel(side) + " generated " + pl.power.length + " Power.");
}
function hexPlaneOptions(g, side, card) {
  const pl = g.players[side];
  if (pl.planePlayed) return [];
  return pl.planes.flatMap((h, slot) =>
    !h.locked || hexSameTerrain(h.types, hexDef(card).terrain_types)
      ? [
          {
            slot,
            label:
              "Plane · " +
              (slot < 3 ? "Front" : "Back") +
              " " +
              ((slot % 3) + 1) +
              " · " +
              h.types.join(" / ") +
              " " +
              h.level,
          },
        ]
      : [],
  );
}
const hexSameTerrain = (a, b) => a.length === b.length && a.every((t) => b.includes(t));
function hexSetPlane(g, side, slot, card, played = false) {
  const pl = g.players[side],
    old = pl.planes[slot],
    def = hexDef(card);
  const same = hexSameTerrain(old.types, def.terrain_types);
  // A hex has one current Plane ability, even when its matching level grows.
  pl.planes[slot] = hexPlane(def.terrain_types, played && same ? old.level + 1 : 1, {
    id: def.baseId || def.id,
    locked: !!old.locked,
  });
  if (played) {
    pl.planePlayed = true;
    pl.power.push([...def.terrain_types]);
  }
  hexCheckTerrain(g);
  hexLog(
    g,
    def.name +
      " · " +
      (slot < 3 ? "front" : "back") +
      " " +
      ((slot % 3) + 1) +
      " · level " +
      pl.planes[slot].level,
  );
}
function hexCheckTerrain(g) {
  for (let side = 0; side < 2; side++)
    for (let slot = 0; slot < 6; slot++) {
      const c = g.players[side].board[slot];
      if (c && !hexCompatible(g, c, side, slot)) hexReturn(g, c);
    }
}
function hexPlanePre(g, side) {
  const jobs = g.players[side].planes.flatMap((h, slot) => {
    const c = g.players[side].board[slot];
    if (!c) return [];
    if (h.id === "FD-022") return [{ kind: "planeHeal", owner: side, target: c.uid }];
    if (h.id === "FD-025") return [{ kind: "planeDamage", owner: side, target: c.uid }];
    return [];
  });
  g.tasks.unshift(...jobs);
}
function hexPlaneCombat(g, active) {
  const defender = 1 - active;
  for (let slot = 0; slot < 3; slot++) {
    const p = g.players[defender];
    if (p.planes[slot].id === "FD-023" && p.board[slot + 3]) hexShield(g, p.board[slot + 3], 1);
  }
  for (let slot = 0; slot < 6; slot++) {
    const pl = g.players[active];
    if (pl.planes[slot].id !== "FD-026" || pl.board[slot]) continue;
    if (!hexCompatible(g, { id: "WE-004" }, active, slot)) continue;
    const c = hexElderSummon(g, active, "WE-004", slot);
    if (c) {
      hexElderGrant(g, c, "sprint", 1, g.turn);
      c.sacrificeAtEnd = g.turn;
    }
  }
}
// Preserve old 20-card builds by adding ten suitable Planes. Duals bridge
// otherwise incompatible encounter decks without changing their existing cards.
function hexDevelopDeck(cards) {
  if (cards.length !== 20 || cards.some((id) => !HEX_CARD[id] || hexType(id, "Plane")))
    return [...cards];
  const demand = {};
  for (const id of cards)
    for (const [t, n] of Object.entries(hexDef(id).cost || {})) demand[t] = (demand[t] || 0) + n;
  const remaining = { ...demand },
    planes = [];
  const choices = HEX_CARDS.filter((c) => c.card_type === "Plane" && c.number <= 21);
  for (let i = 0; i < 10; i++) {
    const scored = choices
      .filter((c) => c.basic_plane || planes.filter((id) => id === c.id).length < 2)
      .map((c) => ({ c, score: c.terrain_types.reduce((v, t) => v + (remaining[t] || 0), 0) }))
      .sort((a, b) => b.score - a.score);
    const best = scored[0].c;
    planes.push(best.id);
    for (const t of best.terrain_types)
      remaining[t] = Math.max(0, (remaining[t] || 0) - (demand[t] || 0) / 4);
  }
  return [...cards, ...planes];
}

function hexMigratePowerSave(saved) {
  const g = JSON.parse(JSON.stringify(saved));
  if (g?.v !== 1) return g;
  for (let side = 0; side < 2; side++) {
    const pl = g.players?.[side];
    if (!pl || !Array.isArray(pl.deck) || !Array.isArray(pl.hand))
      throw Error("Invalid legacy match zones");
    const originals = [
      ...pl.deck,
      ...pl.hand,
      ...(pl.board || []),
      ...(pl.artifacts || []),
      ...(pl.discard || []),
    ]
      .filter(Boolean)
      .map((c) => c.id)
      .slice(0, 20);
    const seedDeck =
      originals.length === 20 ? originals : Hex.starter.filter((id) => !hexType(id, "Plane"));
    const planes = hexDevelopDeck(seedDeck).slice(20);
    pl.deck.push(
      ...planes.map((id) => ({
        id,
        uid: "hc-" + ++g.serial,
        owner: side,
        originalOwner: side,
        spent: {},
      })),
    );
    pl.deck = hexShuffle(g, pl.deck);
    pl.planes = Array.from({ length: 6 }, (_, slot) =>
      hexPlane(
        [pl.board?.[slot] ? hexDef(pl.board[slot]).terrain_types[0] : HEX_TERRAINS[slot]],
        0,
      ),
    );
    pl.power = [];
    pl.planePlayed = false;
  }
  g.v = 2;
  g.rules = { ...hexFormat("standard") };
  if (g.context?.playerDeck) g.context.playerDeck = hexDevelopDeck(g.context.playerDeck);
  return g;
}
