# Applied card repricing

These are live catalog prices, not a hypothetical simulation. All 160 existing cards were reviewed; 128 prices changed. Planes remain free, Erupt retains its Earth/Fire cost, and the existing colours, stats, abilities, terrain compatibility, deck sizes, Plane counts, random draws and defeat rules remain unchanged.

The new distribution is 105 cards at 1 Power, 43 at 2, and 12 at 3. Ordinary creatures and small spells are affordable early; scaling engines, powerful disruption and repeatable value generally cost 2; major board swings and substantial engines cost 3.

Cerulean Sprite is **1 Water**. Other Mage examples: Mystical Woolie 1 Light, Animated Tome 1 Dark, Realmskipper 1 Sky, Delve 1 Water, Countermagic 1 Sky, Professor Riddledum 2 Light, Soultorn Recluse 2 Dark, and Orator of the Void 3 Dark.

## Representative deck checks

These are representative decks, not the user’s exact saved deck list. Each retains 30 cards and ten Planes. Before/after comparisons use identical deck lists, seeds and engine rules, changing only price values from the audit. Both sides use the tactical AI; all hands and draws are random. Each row has twelve matches against Stormcourt, Gravekeepers and Bloodfist Horde.

| Deck | Average battle-card cost before → after | Total spells played before → after |
|---|---:|---:|
| Water Sky Mages | 2.6 → 1.3 | 25 → 45 |
| Dark Light Mages | 3.1 → 1.5 | 8 → 32 |
| Prismatic Mages | 3.1 → 1.4 | 0 → 14 |

The tactical AI now also avoids casting Messenger Hawk into an empty friendly field, where its mandatory return could only bounce itself and waste Power. Cheaper prices exposed that unproductive loop in an existing regression.

These tests establish actual affordable plays and improved participation, not final competitive balance. The unchanged instant empty-field defeat can still produce early losses from poor resource draws. No new resource-access rules were introduced.

## Complete price audit

| Card | Colour | Previous | Applied |
|---|---|---:|---:|
| LT-001 Loyal Pup | Light | 2 | 1 |
| LT-002 Amberstinger | Earth | 3 | 2 |
| LT-003 Abysscoil | Dark | 3 | 2 |
| LT-004 Moonface Owl | Sky | 1 | 1 |
| LT-005 Hatchling of the Hoard | Fire | 2 | 1 |
| LT-006 Gym Mouse | Earth | 2 | 2 |
| LT-007 Ashwing | Fire | 4 | 2 |
| LT-008 Amethyst Colossus | Dark | 5 | 2 |
| LT-009 Bonecaller | Dark | 2 | 1 |
| LT-010 Bloomstone | Earth | 3 | 1 |
| LT-011 Azure Myconid | Water | 2 | 1 |
| LT-012 Aurora Stag | Light | 4 | 2 |
| LT-013 Cinder Jelly | Fire | 2 | 1 |
| LT-014 Bramble Shiv | Earth | 2 | 1 |
| LT-015 Cloud Sovereign | Sky | 4 | 2 |
| LT-016 Cindermaw | Fire | 5 | 2 |
| LT-017 Dewdrop Ooze | Water | 1 | 1 |
| LT-018 Crimson Fletcher | Fire | 3 | 1 |
| LT-019 Dustdancer | Earth | 3 | 1 |
| LT-020 Crystal Gale | Sky | 4 | 2 |
| LT-021 Dustbound | Earth | 3 | 1 |
| LT-022 Velvet Bat | Dark | 1 | 1 |
| LT-023 Moonweave Cloak | Dark | 1 | 1 |
| LT-024 Coralcrusher | Water | 3 | 2 |
| LT-025 Hoardkeeper Coin | Earth | 1 | 1 |
| LT-026 Glacier Cube | Water | 3 | 2 |
| LT-027 Dawnwing | Light | 1 | 1 |
| LT-028 Hourglass of Embers | Fire | 3 | 1 |
| LT-029 Mossgrub | Earth | 1 | 1 |
| LT-030 Crownless Lich | Dark | 5 | 3 |
| LT-031 Heart of the Grove | Earth | 3 | 1 |
| LT-032 Fizzlewick | Fire | 2 | 1 |
| LT-033 Prism of Echoes | Sky | 1 | 1 |
| LT-034 Sunforged Blade | Light | 2 | 1 |
| LT-035 Moonstone Bell | Light | 1 | 1 |
| LT-036 Thunderhead | Sky | 3 | 1 |
| LT-037 Rootbound Idol | Earth | 2 | 1 |
| LT-038 Frostwalker Boots | Water | 2 | 1 |
| LT-039 Phoenix Feather | Fire | 2 | 1 |
| LT-040 Tideglass Bow | Water | 2 | 1 |
| LT-041 Snowswirl | Sky | 2 | 1 |
| LT-042 Sunken Compass | Water | 1 | 1 |
| LT-043 Starlight Locket | Light | 2 | 1 |
| LT-044 Rainbow Vale | Light | 2 | 1 |
| LT-045 Stormcaller Hammer | Sky | 2 | 1 |
| LT-046 Obsidian Mirror | Dark | 2 | 1 |
| LT-047 Brambleguard Shield | Earth | 2 | 1 |
| LT-048 Dragonwatch Crags | Earth | 2 | 1 |
| LT-049 Dragonbone Spear | Fire | 3 | 1 |
| LT-050 Astral Lens | Sky | 1 | 1 |
| LT-051 Lantern Tortoise | Light | 3 | 2 |
| LT-052 Starlit Expanse | Sky | 2 | 1 |
| LT-053 Emberheart Armor | Fire | 2 | 1 |
| LT-054 Silkstep Sandals | Sky | 1 | 1 |
| LT-055 Wayfarer Satchel | Earth | 1 | 1 |
| LT-056 Runesmith Gauntlets | Earth | 2 | 1 |
| LT-057 Hearthkeeper Apron | Light | 1 | 1 |
| LT-058 Garden of Stars | Light | 3 | 1 |
| LT-059 Wildflower Crown | Earth | 1 | 1 |
| LT-060 Cloud Kingdom | Sky | 3 | 2 |
| LT-061 Ocean Pearl Ring | Water | 2 | 1 |
| LT-062 Amber Memory | Earth | 1 | 1 |
| LT-063 Thunderseed | Sky | 2 | 1 |
| LT-064 Hollow Crown | Dark | 2 | 1 |
| SA-001 Transposition | Sky | 1 | 1 |
| SA-002 Zap | Fire | 1 | 1 |
| SA-003 Bounce Back | Water | 2 | 1 |
| SA-004 Unbury | Dark | 2 | 1 |
| SA-005 Quicken | Fire | 1 | 1 |
| SA-006 Foresight | Sky | 1 | 1 |
| SA-007 Sooth Wounds | Light | 1 | 1 |
| SA-008 Mind Control | Dark | 6 | 3 |
| SA-009 Willful Protection | Light | 1 | 1 |
| SA-010 Duplicate | Sky | 4 | 2 |
| SA-011 Delve | Water | 3 | 1 |
| SA-012 Esoteric Implosion | Earth | 2 | 1 |
| SA-013 Dismay | Dark | 2 | 1 |
| SA-014 Pierce the Veil | Sky | 1 | 1 |
| SA-015 Suffer the Dead | Dark | 3 | 2 |
| SA-016 Directed Ire | Light | 1 | 1 |
| SA-017 Bring it On! | Fire | 2 | 1 |
| SA-018 Spring to Life | Light | 3 | 2 |
| SA-019 Choices, Choices | Water | 1 | 1 |
| SA-020 Set the Trap | Earth | 3 | 2 |
| SA-021 Fade to Nothing | Dark | 5 | 2 |
| SA-022 Benevolent Infection | Dark | 2 | 1 |
| SA-023 Disruption Pact | Dark | 3 | 2 |
| SA-024 Vanguard | Light | 3 | 2 |
| SA-025 Control the Future | Water | 3 | 2 |
| SA-026 In Fate's Hands | Dark | 4 | 2 |
| SA-027 Begin Anew | Sky | 4 | 2 |
| SA-028 Search the Archives | Sky | 3 | 2 |
| SA-029 Decimate | Dark | 7 | 3 |
| SA-030 Spellproof Cowl | Light | 2 | 1 |
| SA-031 Mirror Plate | Sky | 4 | 2 |
| SA-032 Liquid Magic | Water | 3 | 1 |
| SA-033 Arcane Amplifier | Fire | 3 | 2 |
| SA-034 Portal to the Shattered Realms | Sky | 3 | 1 |
| SA-035 Countermagic | Sky | 2 | 1 |
| SA-036 Realmskipper | Sky | 2 | 1 |
| SA-037 Mystical Woolie | Light | 3 | 1 |
| SA-038 Cerulean Sprite | Water | 3 | 1 |
| SA-039 Animated Tome | Dark | 3 | 1 |
| SA-040 Feverish Academic | Fire | 2 | 1 |
| SA-041 Dirge Scuttler | Dark | 3 | 1 |
| SA-042 Gifted Aspirant | Water | 3 | 1 |
| SA-043 Seer of the Realms | Sky | 4 | 2 |
| SA-044 Professor Riddledum | Light | 4 | 2 |
| SA-045 Soultorn Recluse | Dark | 3 | 2 |
| SA-046 Rhodovan | Earth | 4 | 2 |
| SA-047 The Orator of the Void | Dark | 6 | 3 |
| WE-001 Pebble Slinger | Earth | 1 | 1 |
| WE-002 Fireback Basilisk | Fire | 3 | 1 |
| WE-003 Flamebrew Witch | Fire | 1 | 1 |
| WE-004 Goblin Punk | Fire | 1 | 1 |
| WE-005 Warg Runt | Earth | 2 | 1 |
| WE-006 Flamespark Elemental | Fire | 2 | 1 |
| WE-007 Riggel, Gold Glutton | Fire | 2 | 1 |
| WE-008 Soldier of Edelberry | Earth | 3 | 1 |
| WE-009 Rebel Rouser | Earth | 2 | 1 |
| WE-010 Greyfur Physician | Light | 2 | 1 |
| WE-011 Burrowborn Magikitten | Dark | 3 | 2 |
| WE-012 Wiskin Bannerling | Light | 2 | 1 |
| WE-013 Prodfoot Steer | Earth | 3 | 1 |
| WE-014 Makeshift Battering Ram | Earth | 4 | 2 |
| WE-015 Gobskin Sympathizer | Fire | 3 | 2 |
| WE-016 Solblade Cutthroat | Dark | 3 | 1 |
| WE-017 Messenger Hawk | Sky | 2 | 1 |
| WE-018 The Bullseye Brothers | Earth | 5 | 3 |
| WE-019 Goblin Channeler | Fire | 2 | 1 |
| WE-020 Edelberry Burrow | Earth | 3 | 2 |
| WE-021 The Vicious Maw | Fire | 4 | 2 |
| WE-022 Goblin Totem | Dark | 3 | 2 |
| WE-023 Wiskin Cutlass | Earth | 2 | 1 |
| WE-024 Urkjaw Bloodfist | Fire | 4 | 2 |
| WE-025 Royal Knight Eklo | Light | 4 | 2 |
| WE-026 Fireback Rider | Fire | 5 | 3 |
| WE-027 Cloudcarriage Captain | Sky | 6 | 3 |
| WE-028 Obelisk of Fis'Duum | Dark | 6 | 3 |
| WE-029 Shackles of Nim | Dark | 2 | 1 |
| WE-030 Champion's Tunic | Light | 3 | 2 |
| WE-031 Brooch of the Ancients | Earth | 3 | 1 |
| WE-032 Torn Banner | Earth | 3 | 2 |
| WE-033 Ring of Disassociation | Sky | 1 | 1 |
| WE-034 Dissect | Dark | 2 | 1 |
| WE-035 Share the Pain | Fire | 2 | 1 |
| WE-036 Blood for Blood | Dark | 3 | 1 |
| WE-037 Cure All | Light | 1 | 1 |
| WE-038 Unearth Antiquities | Earth | 2 | 1 |
| WE-039 Invisibility | Dark | 2 | 1 |
| WE-040 Back in Action | Light | 3 | 2 |
| WE-041 Unsummon | Sky | 1 | 1 |
| WE-042 Demotivate | Dark | 2 | 1 |
| WE-043 Level the Field | Dark | 4 | 2 |
| WE-044 Raise the Dead | Light | 6 | 3 |
| WE-045 Loriadre, Angel of War | Light | 6 | 3 |
| WE-046 Enrapture | Light | 4 | 2 |
| WE-047 Seraphim Scepter | Dark | 7 | 3 |
| WE-048 Spelltwine Altar | Water | 4 | 1 |
| WE-049 Momentary Allegiance | Dark | 5 | 3 |

## Rebuild

Edit `Resources/Hex/Data/cards.json`, then run:

```sh
python tools/cards/render_cost_badges.py
python tools/hex/build_engine.py
```

The shared cost overlays apply to regular, full-art and Illustration Rare textures. Card images keep their original artwork and frames. The native rules read the same catalog costs, including when loading existing match saves.

Run `node tools/hex/check_repriced_decks.cjs` to reproduce the themed comparisons. The prior prices come from `repricing.json`, so the check works without a historical Git checkout.
