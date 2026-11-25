"""Check or format the maintained Hex/RPG-TCG code without rewriting legacy assets."""

import argparse
from pathlib import Path
import subprocess
import sys

from gd_spacing import format_readable

ROOT = Path(__file__).resolve().parents[1]
GDSCRIPT = [
    "Scripts/Hex",
    "tools/terrain/build_terrain_tiles.gd",
    "Scripts/Player/PlayerAnimation.gd",
    "Scripts/Player/PlayerMovement.gd",
    "Scripts/Player/PlayerCamera.gd",
    "Tests/Player/player_animation_test.gd",
    "Tests/Player/terrain_tiles_test.gd",
    "Tests/Player/meadow_scene_test.gd",
    "Scripts/Controllers/PlayerController.gd",
    "Scripts/Compatibility",
    *[
        f"Scripts/Managers/{name}Manager.gd"
        for name in (
            "Hex",
            "Battle",
            "Enemy",
            "Menu",
            "GameState",
            "Companion",
            "Player",
            "Inventory",
        )
    ],
    "Scripts/Menu/MenuUI.gd",
    "Scripts/Menu/MenuTabs.gd",
    "Scripts/Menu/AdventureMenuUI.gd",
    "Scripts/Controllers/WorldController.gd",
    "Scripts/Enemy/Enemy.gd",
    "Scripts/Battle/BattleData.gd",
    "Scripts/NPC.gd",
    "Scripts/Dialog/Actions/PartyJoinDialogAction.gd",
]


def run(*arguments):
    subprocess.run([sys.executable, *arguments], cwd=ROOT, check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fix", action="store_true")
    arguments = parser.parse_args()
    check = [] if arguments.fix else ["--check"]
    files = set()
    for entry in [*GDSCRIPT, "Tests/Hex"]:
        path = ROOT / entry
        files.update(path.rglob("*.gd") if path.is_dir() else [path])
    failures = []
    for path in sorted(files):
        source = path.read_text()
        formatted = format_readable(source)
        if formatted != source:
            if arguments.fix:
                path.write_text(formatted)
            else:
                failures.append(str(path.relative_to(ROOT)))
    if failures:
        parser.exit(1, "Spacing/formatting required:\n" + "\n".join(failures) + "\n")
    run("-m", "gdtoolkit.linter", *GDSCRIPT)
    run(
        "-m",
        "black",
        *check,
        "tools/hex",
        "tools/player",
        "tools/terrain",
        "tools/check_code_style.py",
        "tools/gd_spacing.py",
    )
    native_options = ["-i"] if arguments.fix else ["--dry-run", "--Werror"]
    run(
        "-c",
        "from clang_format import clang_format; clang_format()",
        *native_options,
        "addons/hex_runtime/hex_runtime.c",
    )


if __name__ == "__main__":
    main()
