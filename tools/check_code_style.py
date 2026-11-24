"""Check or format the maintained Hex/RPG-TCG code without rewriting legacy assets."""

import argparse
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
GDSCRIPT = [
    "Scripts/Hex",
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
    run("-m", "gdtoolkit.formatter", *check, *GDSCRIPT, "Tests/Hex")
    run("-m", "gdtoolkit.linter", *GDSCRIPT)
    run("-m", "black", *check, "tools/hex", "tools/check_code_style.py")
    native_options = ["-i"] if arguments.fix else ["--dry-run", "--Werror"]
    run(
        "-c",
        "from clang_format import clang_format; clang_format()",
        *native_options,
        "addons/hex_runtime/hex_runtime.c",
    )


if __name__ == "__main__":
    main()
