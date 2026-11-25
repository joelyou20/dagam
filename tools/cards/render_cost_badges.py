"""Render transparent, resolution-independent-at-authoring cost/affinity overlays.

The game composites these onto every regular, full-art and Illustration Rare
texture at load time, keeping original artwork intact and all finishes in sync.
"""

import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
COLORS = {
    "Earth": "#338943",
    "Fire": "#d33a35",
    "Water": "#237bc1",
    "Sky": "#e8c83d",
    "Dark": "#171923",
    "Light": "#f3f1e8",
}


def render():
    cards = json.loads(
        (ROOT / "Resources/Hex/Data/cards.json").read_text(encoding="utf-8")
    )
    output = ROOT / "Assets/Hex/costs"
    output.mkdir(parents=True, exist_ok=True)
    font_dir = ROOT / "Artwork/Templates/fonts"
    number = ImageFont.truetype(str(font_dir / "DejaVuSans-Bold.ttf"), 53)
    small = ImageFont.truetype(str(font_dir / "DejaVuSans-Bold.ttf"), 23)
    for card in cards:
        image = Image.new("RGBA", (1024, 1536))
        draw = ImageDraw.Draw(image)
        for i, (terrain, amount) in enumerate(card.get("cost", {}).items()):
            x, y, radius = 968, 325 + i * 106, 47
            draw.ellipse(
                (x - radius, y - radius, x + radius, y + radius),
                fill=COLORS[terrain],
                outline="#f3eee0",
                width=5,
            )
            ink = "#121725" if terrain in ("Sky", "Light") else "white"
            draw.text(
                (x, y - 2),
                str(amount),
                font=number,
                anchor="mm",
                fill=ink,
                stroke_width=1,
            )
        if card.get("terrain_types") and card["card_type"] == "Creature":
            text = " / ".join(card["terrain_types"])
            box = draw.textbbox((0, 0), text, font=small)
            width = box[2] - box[0]
            draw.rounded_rectangle(
                (512 - width / 2 - 14, 1395, 512 + width / 2 + 14, 1435),
                radius=12,
                fill="#101622dd",
            )
            draw.text((512, 1415), text, font=small, anchor="mm", fill="white")
        image.save(output / (card["id"] + ".hextex"), format="WEBP", lossless=True)
    print(f"Rendered {len(cards)} cost and terrain overlays")


if __name__ == "__main__":
    render()
