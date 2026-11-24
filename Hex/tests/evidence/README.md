# Native test evidence

Executed on 24 November 2026 with Godot 4.6.3 and the embedded QuickJS runtime through the C GDExtension.

- 11 focused rules regressions passed.
- 56 complete tactical-AI matches: the starter against all 28 preconstructed opponents, seeds 42 and 1337. No action stalls or exceptions.
- 160 base cards included in forced-opening coverage games. 155 played and resolved there; seven additional conditional scenarios cover the remaining cards. The union contains all **160/160 base cards played and resolved**. Cosmetic variants share their base card's rules and stats. This is not exhaustive ability-combination coverage.
- A full native match and versioned save/restore passed.
- The Godot battle scene, five-card opening hand, starter-deck viewer, unordered deck viewer, and save/pause passed automated UI smoke checks.
- A clean editor import finds the native extension; no Node executable or browser is used by the game.

`native-results.json` contains seeds, outcomes, card coverage, and conditional results. Match simulation drives both sides with the tactical AI for repeatability; the live player uses the Godot interface. CI repeats these tests on Godot 4.3 and captures the rendered UI under Xvfb.

A complete match was also driven through the actual Godot battle scene: 68 actions to a result, including hand placement, choices, AI actions, effects, and save updates. The screen was rendered with software OpenGL under Xvfb and visually checked; `battle-screen.png` records the board, hand and inspector. Cross-platform CI is configured but could not be launched because GitHub denied repository writes.
