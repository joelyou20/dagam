"""Build Godot's frame resource from the unmodified 8x8 adventurer atlas."""

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


def build():
    data = ATLAS.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("Expected a PNG atlas")
    width, height = struct.unpack(">II", data[16:24])
    if width < 8 or height < 8:
        raise ValueError("Atlas must be at least eight pixels on each axis")
    cell_width, cell_height = width / 8, height / 8
    lines = [
        '[gd_resource type="SpriteFrames" load_steps=66 format=3]',
        "",
        '[ext_resource type="Texture2D" path="res://Assets/Sprites/Player/adventurer.png" id="1_atlas"]',
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
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text("\n".join(lines) + "\n")
    print(f"Built {OUTPUT.relative_to(ROOT)} ({width}x{height}, 64 frames)")


if __name__ == "__main__":
    build()
