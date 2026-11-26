"use strict";
const HEX_TERRAINS = ["Earth", "Sky", "Fire", "Water", "Dark", "Light"];
const hexFoundation = (c) => (hexDef(c)?.set === "foundations" ? hexDef(c).number : 0);
const hexPlane = (types = [], level = 0, extra = {}) => ({
  types: [...types],
  level,
  ...extra,
});
// Compatibility remains a stable hook for movement effects; all creatures fit every hex.
const hexCompatible = () => true;
function hexPlaneOptions(g, side, card) {
  const pl = g.players[side];
  if (pl.planePlayed) return [];
  return pl.planes.flatMap((h, slot) =>
    !h.locked
      ? [{ slot, label: "Plane · " + (slot < 3 ? "Front" : "Back") + " " + ((slot % 3) + 1) }]
      : [],
  );
}
function hexSetPlane(g, side, slot, card, played = false) {
  const pl = g.players[side],
    old = pl.planes[slot],
    def = hexDef(card);
  pl.planes[slot] = hexPlane([], 1, { id: def.baseId || def.id, locked: !!old.locked });
  if (played) pl.planePlayed = true;
  hexLog(g, def.name + " · hex " + (slot + 1));
}
function hexCheckTerrain() {
  // Changing a Plane never evicts or restricts its occupant.
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
// Strip retired resource Planes from saved decks, preserving active cards and prints.
function hexDevelopDeck(cards) {
  if (cards.some((id) => !HEX_CARD[id])) return [...cards];
  const active = cards.filter((id) => !hexDef(id)?.retired),
    counts = {};
  for (const id of active) {
    const def = hexDef(id),
      base = def.baseId || id;
    counts[base] = (counts[base] || 0) + 1;
    // Migration must not turn an invalid profile into an apparently legal deck.
    if (def.generated_only || counts[base] > (def.deckLimit || 2)) return active;
  }
  const kept = hexTrimDeck(active);
  if (cards.length >= 20 && kept.length < 20)
    for (const id of Hex.starter) {
      if (kept.length >= 20) break;
      if (kept.filter((c) => (HEX_CARD[c].baseId || c) === id).length < 2) kept.push(id);
    }
  return kept;
}
function hexMigrateMatch(saved) {
  const g = JSON.parse(JSON.stringify(saved));
  if (![1, 2, 3].includes(g?.v)) return g;
  for (const pl of g.players || []) {
    for (const zone of ["deck", "hand", "discard", "exile"])
      if (Array.isArray(pl[zone])) pl[zone] = pl[zone].filter((c) => !hexDef(c)?.retired);
    delete pl.power;
    pl.planePlayed = !!pl.planePlayed;
    pl.planes = Array.from({ length: 6 }, (_, slot) => {
      const h = pl.planes?.[slot];
      return hexPlane([], h?.id && !hexDef(h.id)?.retired ? 1 : 0, {
        ...(h?.id && !hexDef(h.id)?.retired ? { id: h.id } : {}),
        locked: !!h?.locked,
      });
    });
  }
  g.tasks = (g.tasks || []).map((j) =>
    j.kind === "power"
      ? { ...j, kind: "planeReset" }
      : j.kind === "phase" && j.phase === "power"
        ? { ...j, phase: "pre" }
        : j,
  );
  if (g.phase === "power") g.phase = "pre";
  g.v = 3;
  g.rules = { ...hexFormat("standard") };
  if (g.context?.playerDeck) g.context.playerDeck = hexDevelopDeck(g.context.playerDeck);
  if (g.context?.practice_game) g.context.practice_game = hexMigrateMatch(g.context.practice_game);
  return g;
}
