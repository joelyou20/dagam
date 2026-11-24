# Hex in DaGam

Open the root `project.godot`, run the existing `Scenes/Root.tscn`, and press **H** for the Hex deck builder or touch a world enemy for an encounter. There is one project: no nested project or hidden Hex directory.

## Existing architecture

- `Scripts/Managers/HexManager.gd` owns the match as an autoload, alongside the other managers. The session initializes only when Hex is opened.
- `Scenes/Hex/HexBattleUI.tscn` and `Scripts/Hex/HexBattleUI.gd` extend `UIBase` as a dedicated full-window root layer owned by `HexManager`. They use the existing `UIManager` and `InteractionHandler`, without instantiating the RPG menu.
- `WorldController` routes H to the Hex deck-builder tab in the existing menu; world encounters open the dedicated battle screen directly. Escape dismisses a battle dialog first, then closes practice or confirms leaving an encounter. Other menu hotkeys cannot cover an active battle.
- `GameStateManager` includes Hex in normal RPG saves/loads. Older saves without Hex remain valid. The current match also autosaves to checksum-protected `user://dagam-hex-match-v1.json`, keeping a backup of the previous file.
- Hiding the screen stops AI activity and music and saves the match. Reopening resumes it. The existing world, RPG managers and root scene remain in place.

Code follows the host layout: `Scripts/Hex`, `Scenes/Hex`, `Resources/Hex`, `Assets/Hex`, `Tests/Hex`, and `addons/hex_runtime`. Hex draws directly in the main viewport with linear mipmapped artwork. While open, canvas-item scaling preserves native window resolution; closing restores the RPG window scale mode.

## World encounters

Touching an active enemy now starts a Standard Hex match using the starter deck and tactical AI, within the current world. `EncounterData.hex_deck_id` selects an opponent (default `thornbound`); existing enemy resources still supply XP. Victory grants player XP once and removes the enemy. Defeat, draw or fleeing grants no XP and retains the enemy with its reactivation cooldown. Escape prompts before conceding. Other tabs and new-game controls cannot bypass an encounter. The previous practice match is restored afterward. Shared saves/autosaves retain the encounter, its original world enemy and the practice snapshot.

## Scope and controls

The player starts with the 20-card First Light starter deck and draws five cards. All 160 cards are available for custom Standard deck building. All 28 preconstructed opponents use the stronger tactical AI. There are no points, purchases, collection progression, Blitz, drafts, tournaments or Legends.

Click a hand card to choose legal placements/targets, or drag it onto a slot/creature. Ready attackers pulse white. Board abilities, friendly/enemy target labels and reaction dialogs are supported. Your deck is shown alphabetically; the opponent's hand/deck remain hidden. Rules include counted creature defeats, empty-field defeat, Summon removal, original ownership, and the 60-full-round draw.

The rules run in-process through a small C GDExtension embedding QuickJS, not through Node, a browser or a server. All 160 base cards and 345 game images retain stable IDs. Cosmetic variants share gameplay data. `.hextex` assets are 1024×1536 WebP images loaded directly with a bounded texture cache; root export presets include them and the JS/JSON data. Source hashes are in `Resources/Hex/Data/source-manifest.json`. Original artwork/templates remain in LifestyleTracker; `tools/hex/import_hd_art.py` reproducibly rebuilds the full-size prints and writes `hd-art-manifest.json`. Pillow is required for artwork imports.

Refresh data with `python tools/hex/import_hex.py /path/to/lifestyleTracker-repo`, then `python tools/hex/build_engine.py`. Linux and Windows x86-64 runtimes are included. Build native support with `bash addons/hex_runtime/build.sh`; Windows uses MSYS2 MINGW64 with `HEX_PLATFORM=Windows CC=gcc`, and macOS uses Xcode Command Line Tools. CI builds the complete integrated project for Linux, Windows and macOS. QuickJS and the Godot C header retain their upstream license notices.

## Verification

```sh
python tools/hex/build_engine.py
godot --headless --path . --editor --import
godot --headless --path . res://Tests/Hex/Integration.tscn
godot --headless --path . res://Tests/Hex/Encounter.tscn
godot --headless --path . --script res://Tests/Hex/native_match.gd
godot --headless --path . --script res://Tests/Hex/rules_test.gd
godot --headless --path . --script res://Tests/Hex/ui_smoke.gd
godot --headless --path . --script res://Tests/Hex/ui_match.gd
```

The integration test runs the real root scene, menu and managers, including shared save/load, inventory/scene preservation, tab switching, Escape, H, UI-stack/input blocking and pause/resume. Native tests cover every opponent and all 160 cards. Existing GUT tests are preserved; the legacy `Tests/test_uibase.gd` references a missing `UIBase.ensure_ui()` method and cannot compile independently of these changes.

## Hex deck builder

The **Hex** menu tab (or **H**) opens `HexDeckBuilderUI`, following the existing `MenuUI` / `UIBase` architecture. Opening it initializes only the catalogue and saved decks; it does not create or replace a match. All cards are available. Search includes names, rules, creature types and keyword abilities; filters cover sets, card categories, separate creature types and rarity. The deck list sits above the collection with copy controls, composition counts and average creature stats. Hover shows full-resolution cards.

Create, duplicate, rename, save and delete named decks. Card edits autosave as drafts; **Use for battles** requires exactly 20 cards, no more than two of a unique card, and each card's explicit limit (for example Loriadre's single-copy limit). There is no minimum creature requirement. The native engine validates these restrictions. The starter remains selected until a valid custom deck is explicitly chosen.

Selected deck snapshots are used for new practice games and world encounters. Existing matches and restored practice snapshots retain their original deck, including the battle-deck viewer. Decks and selection persist in `user://dagam-hex-decks-v1.json` and shared RPG saves under `hex_decks`; older saves still load. `Tests/Hex/DeckBuilder.tscn` covers menu routing, catalogue access, copy limits, all-spell decks, saved drafts, selection, persistence and match isolation.

[Deck-builder screenshot](hex-deck-builder/deck-builder.jpg)

## Scenic 3D battlefield

`Scripts/Hex/HexBoard3D.gd` presents the battle in an isolated 3D world inside the dedicated full-window battle layer: angled camera, mossy stone arena, woodland scenery, lanterns, physical card piles and a concealed opponent hand. It reuses the RPG's dirt and mossy-cliff textures. The 3D render target supersamples its displayed size at 1.5× with anisotropic card filtering and stops when hidden; the HUD, hand, dialogs and card inspector remain native-resolution UI.

Both sides' art faces the player. Projected controls preserve click/drag targeting, artifact placement, unordered deck inspection and discard inspection. The right-side combat button advances phases, while management controls remain along the top. Ready attackers pulse and legal targets highlight on selection. Drawing moves cards from the deck to the hand; placement lifts and settles onto stone slots; attacks lunge, damage numbers rise together, and removed cards shake and fade. These are presentation effects and never mutate engine rules or AI state.

Run `godot --headless --path . --script res://Tests/Hex/board_3d_test.gd` for framing, draw/placement animation cleanup, drag targeting, simultaneous feedback, state isolation and hidden-viewport checks. Running the same test with a display saves `user://hex-3d-board.png`.

The battlefield fills the window behind the overlapping hand, without menu offsets or a reserved bottom panel. Card names and empty-slot labels are omitted from the field. Attack/HP and protection counts use sharp screen-space UI that follows card movement; damage numbers use the same native-resolution approach. Hover shows the 1024×1536 card alone, with no description panel. A compact battle-options button holds secondary actions.

Closing the battle restores the RPG's rendering/scaling settings. While battle is open, only its own 3D viewport renders, avoiding a second render of the hidden overworld.

[Full-window battlefield](hex-fullscreen/battle.jpg) · [Card-only hover](hex-fullscreen/hover.jpg)

## Hex portraits and side piles

Creature slots use enlarged extruded hexagonal meshes and hex-shaped hit areas, spreading the three lanes across the space previously occupied by piles. Attack and HP appear in separate gold/red circular badges at the lower corners. Real cast shadows and soft contact shadows lift cards off the stone. Ready creatures gently bob on an independent visual child, so placement, lunges and hit reactions retain their own transforms; spent creatures settle back down.

Deck and discard controls sit outside the stone field along the right side, with unsquashed 2:3 portrait artwork and number-only counts. Hover/tooltips and click-to-browse still distinguish the piles. Draw animations start at the relocated player deck. Both sides use the same arrangement, clear of the phase button.

## Opening coin and mulligan

Battles begin with a centered, softly fading coin overlay. Heads and Tails trigger the native seeded toss; a vector gold coin rises and rotates through both faces, then settles on that exact result. Turn-order choices appear after landing. The winning player can go first or second; an opponent win automatically proceeds to the opening hand. Resuming an already resolved toss reveals its saved result without rerolling or replaying it. Hiding battle cancels animation and auto-advance callbacks.

Keeping the original hand still starts the selected first player. Mulliganing replaces the hand with five cards and immediately starts turn one, with no second Keep prompt. Legacy opening saves whose player already mulliganed are advanced once on load. `Tests/Hex/Opening.tscn` covers the overlay, animation/result agreement, both winners, first/second choices, save resume, interrupted animations and mulligan/Keep transitions.

[Opening coin screenshot](hex-opening/opening-coin.jpg)
