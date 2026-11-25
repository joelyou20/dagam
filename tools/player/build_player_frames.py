"""Build Godot SpriteFrames from an unmodified directional 8x8 character atlas."""

import argparse
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[2]
ATLAS = ROOT / "Assets/Sprites/Player/adventurer.png"
OUTPUT = ROOT / "Resources/Player/adventurer_frames.tres"
ROWS = [
    (action, facing)
    for facing in ("down", "left", "right", "up")
    for action in ("idle", "walk")
]


def build(atlas=ATLAS, output=OUTPUT):
    atlas = atlas.resolve()
    output = output.resolve()
    atlas_path = atlas.relative_to(ROOT).as_posix()
    output.relative_to(ROOT)
    data = atlas.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("Expected a PNG atlas")
    width, height = struct.unpack(">II", data[16:24])
    if width < 8 or height < 8:
        raise ValueError("Atlas must be at least eight pixels on each axis")
    cell_width, cell_height = width / 8, height / 8
    lines = [
        '[gd_resource type="SpriteFrames" load_steps=66 format=3]',
        "",
        f'[ext_resource type="Texture2D" path="res://{atlas_path}" id="1_atlas"]',
    ]
    for row in range(8):
        for column in range(8):
            lines.extend(
                [
                    "",
                    f'[sub_resource type="AtlasTexture" id="Frame_{row}_{column}"]',
                    'atlas = ExtResource("1_atlas")',
                    f"region = Rect2({column * cell_width}, {row * cell_height}, {cell_width}, {cell_height})",
                    "filter_clip = true",
                ]
            )
    lines.extend(["", "[resource]", "animations = [{"])
    for row, (action, facing) in enumerate(ROWS):
        if row:
            lines.append("}, {")
        lines.append('"frames": [{')
        for column in range(8):
            if column:
                lines.append("}, {")
            lines.extend(
                ['"duration": 1.0,', f'"texture": SubResource("Frame_{row}_{column}")']
            )
        lines.extend(
            [
                "}],",
                '"loop": true,',
                f'"name": &"{action}_{facing}",',
                f'"speed": {5.0 if action == "idle" else 10.0}',
            ]
        )
    lines.append("}]")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines) + "\n")
    print(f"Built {output.relative_to(ROOT)} ({width}x{height}, 64 frames)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--atlas", type=Path, default=ATLAS)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    arguments = parser.parse_args()
    build(arguments.atlas, arguments.output)
