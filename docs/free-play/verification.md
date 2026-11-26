# Restore free play

Cards have no casting costs or terrain affinities. Standard decks contain 20 cards; original creature tribes, stats, abilities, six-defeat victory, Exposure and random draws remain unchanged. Existing single-copy exceptions remain unchanged.

The 21 inert Foundations Planes are retired from decks. All 28 enemy lists and 16 templates contain 20 active cards. Functional Planes and Erupt remain playable; generated Volcanic Vent remains excluded from decks. Power HUD, generation, payments and shared cost/affinity texture overlays are removed. Foundations frames were regenerated from the same original illustrations without terrain labels.

Legacy profiles remove retired Planes and migrate to 20 cards while preserving names and print IDs. Invalid duplicate/unknown-card profiles still fail validation. Match migration preserves existing creatures and active Plane effects, removes old resource Planes from card zones, and clears Power. Encounter practice snapshots migrate recursively.

Validation on Godot 4.6.3:

- 609 free-play/Plane checks; 840 archetype checks; 13 interaction checks; 47 Exposure checks.
- 56 native matches across all 28 enemies and resolution coverage for all 165 active definitions (21 inert definitions retained for historical artwork).
- 96 random-draw template matches across all 16 templates; see `archetype-matches.json`. Simulation uses the ordinary optional mulligan when its opening hand has no creatures.
- Complete UI battle, UI smoke, direct targeting, 3D board and status suites passed.
- World integration, encounters, deck building, template selection, opening flow, RPG navigation/Farmer compatibility, Foundations metadata/artwork and free-shop persistence suites passed.
- Godot import, project readability/style checks, JavaScript lint/formatting, card opacity unit checks and diff whitespace checks passed.

These are regression and completion checks, not a claim of equal deck win rates.
