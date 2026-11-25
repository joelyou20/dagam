"""Repair existing exports losslessly, or audit them with --check."""

import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageChops
from card_opacity import opaque_interior

ROOT = Path(__file__).resolve().parents[2]


def repair(check=False):
    changed = []
    for path in sorted((ROOT / "Assets/Hex/cards").glob("*.hextex")):
        with Image.open(path) as source:
            source = source.convert("RGBA")
        fixed = opaque_interior(source)
        if ImageChops.difference(
            source.getchannel("A"), fixed.getchannel("A")
        ).getbbox():
            changed.append(path.stem)
            if not check:
                fixed.save(path, format="WEBP", lossless=True, exact=True, method=4)
    if check and changed:
        raise SystemExit("Transparent card interiors: " + ", ".join(changed))
    if not check:
        manifest = ROOT / "Resources/Hex/Data/hd-art-manifest.json"
        data = json.loads(manifest.read_text())
        for row in data["cards"]:
            if row["id"] in changed:
                row["sha256"] = hashlib.sha256(
                    (ROOT / "Assets/Hex/cards" / (row["id"] + ".hextex")).read_bytes()
                ).hexdigest()
        manifest.write_text(json.dumps(data, indent=2) + "\n")
    print(
        f"{'Audit found' if check else 'Repaired'} {len(changed)} transparent interiors"
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    repair(parser.parse_args().check)
