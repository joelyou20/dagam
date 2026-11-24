# Hex — standalone Standard battle

Open **`Hex/project.godot`** in Godot 4.3 or newer, then press F6/F5. The original DaGam RPG project, scenes and managers are preserved at the repository root. Hex has its own project and save directory; it does not depend on the RPG's autoloads.

The player starts with the existing 20-card First Light starter deck, draws five cards and plays one Standard battle against the stronger tactical opponent. New Game lets you select any of the 28 existing preconstructed enemy decks. There are no points, purchases, collection economy, Blitz, drafts, tournaments, challenges or Legends.

## Native runtime

The battle rules run **inside Godot** using a small C GDExtension embedding QuickJS. This keeps all 160 cards' tested JavaScript effects, keywords, simultaneous damage, reactions, AI and serialization together while the screen, drag/drop, popups, audio and animations are native Godot controls. It is not a browser, WebView, Node subprocess or server. No external process or internet connection is needed to play.

A Linux x86-64 runtime is checked in. For Windows or macOS, download the matching **Hex-project** artifact from the repository's **Hex standalone** Actions workflow; it includes the project and the compiled runtime. Alternatively build locally:

```sh
bash Hex/native/build.sh
```

Linux requires a C compiler and libc development headers. macOS requires Xcode Command Line Tools. On Windows use MSYS2 MINGW64 with `mingw-w64-x86_64-gcc`, then run `HEX_PLATFORM=Windows CC=gcc bash Hex/native/build.sh`. Windows builds statically link the compiler/thread runtime. Godot will report a missing runtime instead of silently starting an incomplete match.

The native interface targets Godot 4.3's stable C GDExtension ABI. Each runtime instance has a 128 MiB allocation limit, bounded engine search, and a 12-second evaluation interrupt. It exposes no filesystem, networking or OS functions to JavaScript. UI commands are encoded as JSON.

## Playing

- Call the coin, choose first/second if you win, then keep or redraw your opening hand once.
- Click a hand card to see its legal placements/targets, or drag it onto a slot or creature.
- During combat, ready creatures pulse white. Click one and an enemy, or drag between them.
- **Board abilities** lists activations. Required choices show card images and identify your cards versus the enemy's cards.
- Reaction windows show the triggering card alongside your possible response; choose a response or skip.
- Click your deck to inspect it alphabetically, without revealing draw order. Opponent hands/decks stay hidden. Both discards and removed cards can be inspected.
- Hover a card for its enlarged image, rules and tags. **Starter deck** shows the player's starting cards.
- **Save & pause** stops AI activity. Matches also save after each action and resume on launch, including unresolved choices and reactions.
- Six counted creature deaths lose the match. Summons do not count and are removed when they leave play. Empty-field defeat and the 60-full-round draw rule match the source engine.

Saves live at Godot's `user://hex-match-v1.json`, use a versioned envelope and checksum, and preserve the previous save as a backup. An invalid save is reported and a new match is started. No lifestyle-app save data is read or modified.

## Data and assets

`data/cards.json` contains all three sets with stable IDs and Loriadre's revised 5/3 stats and effects. Regular, full-art and Illustration Rare variants share gameplay data. `assets/cards/*.hextex` are the existing compact WebP images with a neutral extension; Godot loads them directly to avoid generating hundreds of duplicate editor texture caches. They are explicitly included by the export presets. Original high-resolution artwork and frame-authoring sources remain in the source repository; this project imports the portable game assets, not Legend maps or shop banners.

`data/source-manifest.json` records the source revision and hashes. To refresh from the source checkout:

```sh
python Hex/tools/import_hex.py /path/to/lifestyleTracker-repo
python Hex/tools/build_engine.py
```

The importer removes the old app's challenge-tracking hook and extra format entry. `engine/platform.js` supplies Standard-only host adapters, without economy, ledger, Avatar or daily modifier dependencies. Rebuild `engine/battle.js` after editing engine files. Keep card rules changes in the catalogue and effect code together, then regenerate and test.

QuickJS is vendored under its MIT license in `native/vendor/LICENSE`. The Godot GDExtension header includes its upstream license notice. The C bridge is deliberately small and uses no godot-cpp build dependency.

## Verification

```sh
python Hex/tools/build_engine.py
godot --headless --path Hex --editor --import
godot --headless --path Hex --script res://tests/runtime_smoke.gd
godot --headless --path Hex --script res://tests/native_match.gd
godot --headless --path Hex --script res://tests/rules_test.gd
godot --headless --path Hex --script res://tests/ui_smoke.gd
```

The rules suite executes inside QuickJS through the same GDExtension as the game. It checks focused regressions, runs the starter against every authored opponent under the tactical AI, and forces every base card into coverage games. Conditional scenarios exercise response/recovery cards. Coverage does not imply every possible combination has been exhaustively tested. Results are written to `user://native-test-results.json`.

The Actions workflow builds native runtimes for Linux, Windows and macOS, runs the suite on Godot 4.3, and captures the UI under Xvfb. Export presets are included for Linux and Windows; install the matching Godot export templates and use the matching native artifact. Mobile and web exports require additional native builds and are outside this slice.
