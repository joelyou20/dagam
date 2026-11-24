# Hex and exploration maintenance

The exploration menu contains Adventure, Decks, Inventory, Journal and Options.
Adventure shows the player’s duelist level, XP and selected deck. Journal keeps
quests and recruited story companions. Inventory retains consumables and older
items; older equipment is presented as a keepsake without equip controls.
Encounter victory awards all XP to the player. Level progression does not change
card stats.

## Compatibility boundary

`Scripts/Compatibility` retains the old autoload names and serialized resource
contracts so existing scenes and saves can still load. Party, equipment, unit
placement and speed-based turns no longer participate in live battles. All live
encounters use Hex through BattleManager. Legacy scenes and resource classes
remain on disk for compatibility; do not attach them to the active menu.

CompanionManager records story recruitment without creating combat units or
granting starting equipment. Farmer’s existing PartyJoinDialogAction still works
and recruitment is idempotent. Saves write companion records and the legacy party
key; old party-only saves migrate when loaded. Recruitment state loads before the
world scene so loading a checkpoint from before recruitment restores Farmer.

## Formatting and lint

Install the pinned tools once:

```sh
python -m pip install -r requirements-dev.txt
npm ci --ignore-scripts
```

Check the maintained scripts, native bridge and rule modules:

```sh
python tools/check_code_style.py
npm run check:js
```

Apply formatting:

```sh
python tools/check_code_style.py --fix
npm run format:js
python tools/hex/build_engine.py
```

Edit individual JavaScript modules in Resources/Hex/Engine, not generated
battle.js. Rebuild that bundle after edits. The formatter excludes vendored
QuickJS sources and legacy assets. GDScript uses gdtoolkit lint plus the AST-aware spacing pass in tools/gd_spacing.py.
Use one blank line between functions. Inside functions, separate declaration groups,
control-flow blocks and final returns with a blank line. Short single-step functions
remain compact. The physical file limit is 1,200 lines to accommodate readable
whitespace; all other gdtoolkit defaults remain enabled.
HexBattleEffects owns visual effect choreography; HexBattleController owns input
and battle presentation. Board shaders live in Resources/Hex/Shaders.

## Verification

The Hex GitHub workflow runs formatting/lint, native builds and battle/world
regressions. Tests/Hex/RpgTCG.tscn covers Farmer’s dialogue action, recruitment,
old/new saves, earlier checkpoints, inventory, menu navigation and solo XP.
Tests/Hex/rules_test.gd covers all 160 base cards and 56 simulated matches.
