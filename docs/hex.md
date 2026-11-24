# Hex in DaGam

Open the root `project.godot`, run the existing `Scenes/Root.tscn`, and press **H** or select **Hex** from the menu. There is one project: no nested project or hidden Hex directory.

## Existing architecture

- `Scripts/Managers/HexManager.gd` owns the match as an autoload, alongside the other managers. The session initializes only when Hex is opened.
- `Scenes/Hex/HexMenuUI.tscn` and `Scripts/Hex/HexMenuUI.gd` extend the existing `UIBase`, live in `MenuUI`'s tab container, and use `UIManager` and `InteractionHandler` for navigation and world-input blocking.
- `MenuTabs.Tab.HEX` replaces the unused menu button. `WorldController` routes H through `MenuManager`. Escape first dismisses a Hex dialog, then closes the menu and returns control to the world.
- `GameStateManager` includes Hex in normal RPG saves/loads. Older saves without Hex remain valid. The current match also autosaves to checksum-protected `user://dagam-hex-match-v1.json`, keeping a backup of the previous file.
- Hiding the screen stops AI activity and music and saves the match. Reopening resumes it. The existing world, RPG managers and root scene remain in place.

Code follows the host layout: `Scripts/Hex`, `Scenes/Hex`, `Resources/Hex`, `Assets/Hex`, `Tests/Hex`, and `addons/hex_runtime`. A scaled SubViewport keeps the board readable within the existing menu without changing the RPG's window settings.

## Scope and controls

The player has the 20-card First Light starter deck and draws five cards. All 28 preconstructed opponents use the stronger tactical AI. There are no points, purchases, collection progression, Blitz, drafts, tournaments or Legends.

Click a hand card to choose legal placements/targets, or drag it onto a slot/creature. Ready attackers pulse white. Board abilities, friendly/enemy target labels and reaction dialogs are supported. Your deck is shown alphabetically; the opponent's hand/deck remain hidden. Rules include counted creature defeats, empty-field defeat, Summon removal, original ownership, and the 60-full-round draw.

The rules run in-process through a small C GDExtension embedding QuickJS, not through Node, a browser or a server. All 160 base cards and 345 game images retain stable IDs. Cosmetic variants share gameplay data. `.hextex` assets are compact WebP images loaded directly; root export presets include them and the JS/JSON data. Source hashes are in `Resources/Hex/Data/source-manifest.json`. High-resolution originals/templates remain in LifestyleTracker.

Refresh data with `python tools/hex/import_hex.py /path/to/lifestyleTracker-repo`, then `python tools/hex/build_engine.py`. Build native support with `bash addons/hex_runtime/build.sh`; Windows uses MSYS2 MINGW64 with `HEX_PLATFORM=Windows CC=gcc`, and macOS uses Xcode Command Line Tools. CI builds the complete integrated project for Linux, Windows and macOS. QuickJS and the Godot C header retain their upstream license notices.

## Verification

```sh
python tools/hex/build_engine.py
godot --headless --path . --editor --import
godot --headless --path . res://Tests/Hex/Integration.tscn
godot --headless --path . --script res://Tests/Hex/native_match.gd
godot --headless --path . --script res://Tests/Hex/rules_test.gd
godot --headless --path . --script res://Tests/Hex/ui_smoke.gd
godot --headless --path . --script res://Tests/Hex/ui_match.gd
```

The integration test runs the real root scene, menu and managers, including shared save/load, inventory/scene preservation, tab switching, Escape, H, UI-stack/input blocking and pause/resume. Native tests cover every opponent and all 160 cards. Existing GUT tests are preserved; the legacy `Tests/test_uibase.gd` references a missing `UIBase.ensure_ui()` method and cannot compile independently of these changes.
