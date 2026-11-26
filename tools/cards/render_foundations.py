"""Compose Foundations art into existing rarity frames and full-art variants."""

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps
from frame_composer import artwork_mask, compose
from card_opacity import opaque_interior

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "Artwork/Foundations"
TEMPLATES = ROOT / "Artwork/Templates"
OUTPUT = ROOT / "Assets/Hex/cards"
FONT_DIR = TEMPLATES / "fonts"
LAYOUT = {
    "Common": {
        "title": (125, 91, 899, 164),
        "type": (110, 920, 914, 970),
        "body": (124, 1034, 900, 1305),
        "footer": (512, 1380),
    },
    "Uncommon": {
        "title": (120, 71, 904, 151),
        "type": (112, 944, 912, 999),
        "body": (116, 1051, 908, 1310),
        "footer": (512, 1370),
    },
    "Rare": {
        "title": (142, 101, 882, 164),
        "type": (121, 909, 903, 953),
        "body": (123, 1035, 901, 1295),
        "footer": (512, 1358),
    },
}


def font(size, serif=False, bold=False):
    name = (
        "DejaVuSerif-Bold.ttf"
        if serif
        else "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
    )
    return ImageFont.truetype(str(FONT_DIR / name), size)


def centered(draw, text, box, size, serif=False, fill="#f4efdf"):
    x1, y1, x2, y2 = box
    while font(size, serif).getlength(text) > x2 - x1 and size > 18:
        size -= 1
    assert font(size, serif).getlength(text) <= x2 - x1, text
    draw.text(
        ((x1 + x2) / 2, (y1 + y2) / 2),
        text,
        font=font(size, serif),
        fill=fill,
        anchor="mm",
        stroke_width=1,
        stroke_fill="#11121b",
    )


def wrap(text, face, width):
    lines = []
    for paragraph in text.splitlines():
        line = ""
        for word in paragraph.split():
            trial = (line + " " + word).strip()
            if line and face.getlength(trial) > width:
                lines.append(line)
                line = word
            else:
                line = trial
        if line:
            lines.append(line)
    return lines


def card_type(card):
    return card["card_type"]


def body(draw, card, box, centered_text=False):
    x1, y1, x2, y2 = box
    for size in range(34 if not centered_text else 31, 21, -1):
        lines = wrap(card["rules"], font(size), x2 - x1)
        height = len(lines) * (size + 8)
        if height <= y2 - y1:
            break
    else:
        raise ValueError("Rules overflow: " + card["id"])
    y = y1

    for line in lines:
        if centered_text:
            draw.text(
                ((x1 + x2) / 2, y),
                line,
                font=font(size),
                fill="#fff5df",
                anchor="mt",
                stroke_width=2,
                stroke_fill="#101018",
            )
        else:
            draw.text((x1, y), line, font=font(size), fill="#f0ede6")
        y += size + 8
    assert y <= y2, card["id"]
    return size


def regular(card, art, frames):
    frame, mask, bounds = frames[card["rarity"]]
    image = compose(art, frame, mask, bounds, "cover", {"position": [0.5, 0.42]})
    draw = ImageDraw.Draw(image)
    layout = LAYOUT[card["rarity"]]
    # The original blank frames contain faint placeholder lettering in this well.
    # Clear its interior before printing rules; basic Planes must stay text-free.
    x1, y1, x2, y2 = layout["body"]
    draw.rounded_rectangle(
        (x1 - 12, y1 - 12, x2 + 12, y2 + 12), radius=32, fill="#111b23"
    )
    centered(draw, card["name"], layout["title"], 44, serif=True)
    centered(draw, card_type(card), layout["type"], 28)
    size = body(draw, card, layout["body"])
    draw.text(
        layout["footer"],
        f'{card["rarity"].upper()} · {card["id"]} · FOUNDATIONS',
        font=font(15),
        fill="#c7c0b3",
        anchor="mm",
    )
    return image, size


def full_art(card, art, frame):
    image = ImageOps.fit(
        art.convert("RGBA"), frame.size, method=Image.Resampling.LANCZOS
    )
    scrim = Image.new("RGBA", frame.size)
    draw = ImageDraw.Draw(scrim)
    for y in range(frame.height):
        top = max(0, 1 - abs(y - 150) / 220) * 150
        bottom = max(0, min(1, (y - 1000) / 180)) * 205 if card["rules"] else 0
        draw.line((0, y, frame.width, y), fill=(7, 10, 17, round(max(top, bottom))))
    image = Image.alpha_composite(Image.alpha_composite(image, scrim), frame)
    draw = ImageDraw.Draw(image)
    centered(draw, card["name"], (142, 95, 882, 185), 62, serif=True)
    centered(draw, card_type(card), (130, 192, 894, 225), 24)
    size = body(draw, card, (140, 1100, 884, 1390), centered_text=True)
    draw.text(
        (512, 1465),
        f'FOUNDATIONS · {card["id"]} · FULL ART',
        font=font(18),
        anchor="mm",
        fill="#dfd0b8",
        stroke_width=1,
        stroke_fill="#101018",
    )
    mask = Image.new("L", frame.size)
    ImageDraw.Draw(mask).rounded_rectangle((12, 12, 1012, 1524), radius=55, fill=255)
    image.putalpha(mask)
    return image, size


def build(partial=False):
    cards = json.loads(
        (ROOT / "Resources/Hex/Data/foundations.json").read_text(encoding="utf-8")
    )["cards"]
    frames = {}
    records = []
    sources = set()
    OUTPUT.mkdir(parents=True, exist_ok=True)
    previews = SOURCE / "previews"
    previews.mkdir(exist_ok=True)
    for rarity in LAYOUT:
        frame = Image.open(TEMPLATES / (rarity.lower() + ".png")).convert("RGBA")
        mask, bounds = artwork_mask(frame)
        frames[rarity] = frame, mask, bounds
    full = Image.open(TEMPLATES / "full-art.png").convert("RGBA")
    for card in cards:
        path = SOURCE / "art" / (card["id"] + ".png")
        if not path.exists():
            if partial:
                continue
            raise FileNotFoundError(path)
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        assert digest not in sources, "Artwork reused: " + card["id"]
        sources.add(digest)
        art = Image.open(path)
        for suffix, render in [
            ("", lambda: regular(card, art, frames)),
            ("-FA", lambda: full_art(card, art, full)),
        ]:
            image, font_size = render()
            assert image.size == (1024, 1536)
            output = OUTPUT / (card["id"] + suffix + ".hextex")
            image = opaque_interior(image)
            image.save(output, format="WEBP", quality=94, method=4)
            thumb = ImageOps.contain(image, (240, 360))
            thumb.save(previews / (card["id"] + suffix + ".webp"), quality=90)
            records.append(
                {
                    "id": card["id"] + suffix,
                    "name": card["name"],
                    "rarity": card["rarity"],
                    "art_sha256": digest,
                    "sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
                    "font_size": font_size,
                    "size": list(image.size),
                }
            )
    (SOURCE / "render-report.json").write_text(json.dumps(records, indent=2) + "\n")
    for start in range(0, len(records), 16):
        subset = records[start : start + 16]
        sheet = Image.new("RGB", (1024, ((len(subset) + 3) // 4) * 410), "#101e27")
        draw = ImageDraw.Draw(sheet)
        for index, record in enumerate(subset):
            x, y = (index % 4) * 256 + 8, (index // 4) * 410 + 8
            thumb = Image.open(previews / (record["id"] + ".webp"))
            sheet.paste(thumb, (x, y), thumb)
            draw.text(
                (x, y + 366),
                record["id"] + " " + record["name"][:22],
                font=font(12),
                fill="white",
            )
        sheet.save(SOURCE / f"contact-sheet-{start//16+1}.jpg", quality=92)
    print(f"Rendered {len(records)} prints from {len(sources)} unique illustrations")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--partial", action="store_true")
    build(parser.parse_args().partial)
