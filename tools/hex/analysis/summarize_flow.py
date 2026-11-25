"""Summarize isolated resource-flow experiments; no game rules are changed."""

import argparse
import hashlib
import gzip
import json
import statistics
from math import comb
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
OUTPUT = ROOT / "docs/resource-flow"


def percent(numerator, denominator):
    return round(100 * numerator / denominator, 1) if denominator else None


def summarize(source):
    games = source["games"]
    turns = [t for g in games for t in g["records"] if t["pre"]]
    early = [t for t in turns if t["round"] <= 3]
    developing = [t for t in turns if 2 <= t["round"] <= 5]
    completed = [g for g in games if g["winner"] is not None]
    losses = [g for g in games if g["winner"] in [0, 1]]
    return {
        "games": len(games),
        "errors": sum(bool(g["error"]) for g in games),
        "censored_at_round_25_pct": percent(len(games) - len(completed), len(games)),
        "median_completed_round": (
            statistics.median(g["round"] for g in completed) if completed else None
        ),
        "end_by_round_3_pct": percent(
            sum(g["winner"] is not None and g["round"] <= 3 for g in games), len(games)
        ),
        "empty_field_loss_pct": percent(
            sum(g["reason"] == "emptyField" for g in games), len(games)
        ),
        "loser_never_fielded_creature_pct": percent(
            sum(g["firstCreature"][1 - g["winner"]] is None for g in losses),
            len(losses),
        ),
        "early_idle_turn_pct": percent(
            sum(t["plays"] + t["attacks"] + t["abilities"] == 0 for t in early),
            len(early),
        ),
        "idle_turns_2_to_5_pct": percent(
            sum(t["plays"] + t["attacks"] + t["abilities"] == 0 for t in developing),
            len(developing),
        ),
        "early_resource_locked_main_pct": percent(
            sum(t["locked"] for t in early), len(early)
        ),
        "early_no_legal_main_play_pct": percent(
            sum(t["playable"] == 0 for t in early), len(early)
        ),
        "median_nonplane_plays_per_game": statistics.median(
            sum(t["plays"] for t in g["records"]) for g in games
        ),
        "median_attacks_per_game": statistics.median(
            sum(t["attacks"] for t in g["records"]) for g in games
        ),
        "first_player_win_pct": percent(
            sum(g["winner"] == g["first"] for g in losses), len(losses)
        ),
        "starter_win_pct": percent(sum(g["winner"] == 0 for g in losses), len(losses)),
        "median_first_creature_round": statistics.median(
            r for g in games for r in g["firstCreature"] if r is not None
        ),
    }


def main():
    results = {}
    unique = {}
    for path in sorted([*OUTPUT.glob("*.json"), *OUTPUT.glob("*.json.gz")]):
        if path.name == "summary.json":
            continue
        source = json.loads(
            gzip.decompress(path.read_bytes())
            if path.name.endswith(".gz")
            else path.read_text()
        )
        if "games" in source and isinstance(source["games"], list):
            name = path.name.removesuffix(".gz").removesuffix(".json")
            results[name] = summarize(source)
            for game in source["games"]:
                if game["error"]:
                    raise RuntimeError(f"Simulation failed: {name}: {game['error']}")
                key = (source["variant"], game["enemy"], game["seed"])
                result = (game["winner"], game["round"], game["reason"])
                if key in unique and unique[key] != result:
                    raise RuntimeError(f"Repeated matchup changed result: {key}")
                unique[key] = result
    odds = {
        str(planes): {
            str(seen): round(
                100
                * sum(comb(planes, i) * comb(30 - planes, seen - i) for i in [0, 1])
                / comb(30, seen),
                2,
            )
            for seen in [5, 9]
        }
        for planes in [10, 12, 14]
    }
    output = {
        "unique_matchups": len(unique),
        "engine_sha256": hashlib.sha256(
            (ROOT / "Resources/Hex/Engine/battle.js").read_bytes()
        ).hexdigest(),
        "variants": results,
        "probability_of_at_most_one_plane_pct": odds,
        "definitions": {
            "idle_turn": "No non-Plane hand play, attack declaration or activated ability on that owner's turn. Plane-only development is counted idle.",
            "resource_locked": "At the first pre-combat main phase observation, no non-Plane card in hand has an affordable Power cost, independently of target availability.",
            "early": "Owner turns in rounds 1–3, among games still running. Rates are conditional on observed turns and not estimates for censored future turns.",
            "limit": "25 full rounds or 1,800 actions; unfinished matches are censored, not treated as draws or victories.",
        },
    }
    (OUTPUT / "summary.json").write_text(json.dumps(output, indent=2) + "\n")
    columns = [
        "variant",
        "games",
        "median_completed_round",
        "end_by_round_3_pct",
        "early_idle_turn_pct",
        "early_resource_locked_main_pct",
        "median_nonplane_plays_per_game",
        "median_attacks_per_game",
        "censored_at_round_25_pct",
    ]
    print(" | ".join(columns))
    for name, row in results.items():
        print(
            " | ".join(str(name if col == "variant" else row[col]) for col in columns)
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--archive",
        action="store_true",
        help="Compress raw match logs after summary validation",
    )
    args = parser.parse_args()
    main()
    if args.archive:
        for path in OUTPUT.glob("*.json"):
            if path.name == "summary.json":
                continue
            source = json.loads(path.read_text())
            if isinstance(source.get("games"), list):
                payload = json.dumps(source, separators=(",", ":")).encode()
                path.with_suffix(".json.gz").write_bytes(
                    gzip.compress(payload, mtime=0)
                )
                path.unlink()
