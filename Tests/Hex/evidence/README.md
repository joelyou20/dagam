# Integrated Hex verification

Verified using Godot 4.6.3 on Linux against the existing root project.

- 19 integration checks start `Scenes/Root.tscn` and use the real MenuManager, MenuUI, UIBase, UIManager, InteractionHandler and GameStateManager.
- Checks cover lazy match creation, H and menu entry, dialog-first Escape handling, return to world input, pausing hidden AI, unchanged main scene, RPG inventory/scene preservation and shared save/load. Legacy saves without Hex data remain valid.
- 11 focused native rules regressions pass.
- 56 matches finish against all 28 preconstructed opponents (two seeds each).
- All 160 base cards are included in coverage games and played/resolved across those games plus seven conditional scenarios. Cosmetic variants share rules and stats. This does not exhaustively test every combination.
- A full match completes through the Godot battle controller in 68 actions; native save/restore and UI smoke checks pass.
- The integrated screen was rendered under Xvfb/software OpenGL and inspected. `battle-screen.png` shows Hex within the original menu navigation.
- The Windows runtime cross-compiles as a PE32+ x86-64 DLL and imports only Windows system libraries. Windows UI execution is not claimed here; CI rebuilds the runtime for each platform.

`native-results.json` contains seeds, outcomes and card coverage. Existing legacy GUT tests are retained; `Tests/test_uibase.gd` references an absent `UIBase.ensure_ui()` method and cannot compile on the baseline. No changes were made to UIBase to work around that unrelated test.
