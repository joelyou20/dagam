"use strict";
const HEX_FORMATS = {
  standard: {
    id: "standard",
    name: "Standard",
    deckSize: 30,
    opening: 5,
    columns: 3,
    slots: 6,
    artifactSlots: 2,
    losses: 6,
    minCreatures: 0,
  },
};
const hexFormat = (id) => HEX_FORMATS.standard;
const hexRules = (g) => g?.rules || HEX_FORMATS.standard;
const hexColumns = (g) => hexRules(g).columns;
function hexTrimDeck(cards, format = "standard") {
  const r = hexFormat(format);
  cards = hexCapDeck(cards);
  if (cards.length <= r.deckSize) return [...cards];
  const out = [],
    counts = {},
    prints = {},
    available = Object.fromEntries(cards.map((id) => [id, cards.filter((c) => c === id).length]));
  const creatures = cards.filter((id) => HEX_CARD[id]?.card_type === "Creature"),
    want = Math.max(
      r.minCreatures,
      Math.min(r.deckSize, Math.round((r.deckSize * creatures.length) / cards.length)),
    );
  for (const limit of [1, 2])
    for (const id of cards) {
      const base = HEX_CARD[id]?.baseId || id;
      if (
        !HEX_CARD[id] ||
        out.length >= r.deckSize ||
        (counts[base] || 0) >= Math.min(limit, HEX_CARD[id].deckLimit || 2) ||
        (prints[id] || 0) >= available[id]
      )
        continue;
      const n = out.filter((id) => HEX_CARD[id].card_type === "Creature").length,
        isCreature = HEX_CARD[id].card_type === "Creature";
      if (isCreature ? n >= want : out.length - n >= r.deckSize - want) continue;
      out.push(id);
      counts[base] = (counts[base] || 0) + 1;
      prints[id] = (prints[id] || 0) + 1;
    }
  for (const id of cards) {
    const base = HEX_CARD[id]?.baseId || id;
    if (out.length >= r.deckSize) break;
    if ((counts[base] || 0) < (HEX_CARD[id].deckLimit || 2) && (prints[id] || 0) < available[id]) {
      out.push(id);
      counts[base] = (counts[base] || 0) + 1;
      prints[id] = (prints[id] || 0) + 1;
    }
  }
  return out;
}

function hexTypes(card) {
  const c = typeof card === "string" ? HEX_CARD[card] : card?.card_type ? card : HEX_CARD[card?.id];
  if (!c) return [];
  return c.card_type === "Creature"
    ? [
        ...new Set([
          ...(c.types || c.subtype.split(/\s+[—–-]\s+/)),
          ...(card?.summoned ? ["Summon"] : []),
        ]),
      ]
    : [c.subtype];
}
const hexHasType = (card, type) =>
  hexTypes(card).some((t) => t.toLowerCase() === String(type).toLowerCase());
const hexTypeOptions = () =>
  [...new Set(HEX_CARDS.flatMap(hexTypes))].sort((a, b) => a.localeCompare(b));
function hexTypeLabel(card) {
  const c = typeof card === "string" ? HEX_CARD[card] : card?.card_type ? card : HEX_CARD[card?.id];
  return c
    ? c.card_type +
        (c.card_type === "Spell" && c.subtype === "Spell" ? "" : " · " + hexTypes(card).join(" · "))
    : "";
}

const hexKeywordList = (card) =>
  (typeof card === "string" ? HEX_CARD[card] : card?.card_type ? card : HEX_CARD[card?.id])
    ?.keywords || [];
const hexKeyword = (card, id) => {
  const k = hexKeywordList(card).find((k) => k.id === id);
  return k ? k.value || 1 : 0;
};
const hexKeywordLabel = (k) => {
  const t = HEX_KEYWORDS.find((t) => t.id === k.id);
  return t ? t.name.replace(" X", k.value ? " " + k.value : "") : k.id;
};
const hexKeywordText = (card) => hexKeywordList(card).map(hexKeywordLabel).join(" · ");
const hexIsReaction = (card) => hexType(card, "Spell") && hexDef(card).subtype === "Reaction";

function hexCapDeck(cards) {
  const counts = {};
  return cards.filter((id) => {
    const c = HEX_CARD[id];
    if (!c) return false;
    const base = c.baseId || id;
    if ((counts[base] || 0) >= (c.deckLimit || 2)) return false;
    counts[base] = (counts[base] || 0) + 1;
    return true;
  });
}

const HEX_SUMMON_RULE =
  "Creatures summoned by effects gain the Summon type in addition to their other types, unless the effect states otherwise. Summon deaths do not count toward the creature-defeat limit. When a Summon leaves the battlefield, including being destroyed, sacrificed or returned to hand, remove it from the game instead.";
