"use strict";
globalThis.runArchetypeTests = () => {
  let checks = 0;
  const check = (v, m) => {
    checks++;
    if (!v) throw Error(m);
  };
  check(HEX_ARCHETYPES.length === 16, "All archetype templates remain");
  for (const a of HEX_ARCHETYPES) {
    check(a.cards.length === 20, a.id + " has 20 cards");
    check(Hex.dispatch({ op: "deckcheck", cards: a.cards }).valid, a.id + " is a legal deck");
    for (const id of a.cards) {
      check(!hexDef(id).retired, a.id + " contains no inert Plane");
      check(!("cost" in hexDef(id)), id + " plays without cost");
    }
  }
  for (const [name, deck] of Object.entries(HEX_RESOURCE_DECKS)) {
    check(deck.length === 20, name + " has 20 cards");
    check(Hex.dispatch({ op: "deckcheck", cards: deck }).valid, name + " legal enemy deck");
    check(!deck.some((id) => hexDef(id).retired), name + " contains no inert Plane");
  }
  for (const c of HEX_CARDS.filter((c) => c.card_type === "Creature")) {
    check(hexTypes(c).length > 0, c.id + " retains creature types");
    if (HEX_CARD[c.id + "-IR"])
      check(!("cost" in HEX_CARD[c.id + "-IR"]), c.id + " rare print has no cost");
  }
  return { checks };
};
