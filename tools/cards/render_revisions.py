"""Rebuild revised card rules from original art, frames, and canonical card data."""

from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw, ImageFont, ImageOps
from frame_composer import artwork_mask, compose
from card_opacity import opaque_interior

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "Artwork/CardRevisions"
FONTS = ROOT / "Artwork/Templates/fonts"


def details(card):
    return "", card["rules"]


def set_title(card):
    return (
        "SHATTERED ARCANA" if card["set"] == "shattered-arcana" else "WAR ON ELDERBERRY"
    )


LAYOUT = {
    "Common": {
        "title": (125, 91, 899, 164),
        "type": (110, 920, 914, 970),
        "body": (124, 1034, 900, 1305),
        "stats": [(143, 1385), (879, 1385)],
        "footer": (512, 1380),
    },
    "Uncommon": {
        "title": (120, 71, 904, 151),
        "type": (112, 944, 912, 999),
        "body": (116, 1051, 908, 1310),
        "stats": [(117, 1385), (910, 1385)],
        "footer": (512, 1370),
    },
    "Rare": {
        "title": (142, 101, 882, 164),
        "type": (121, 909, 903, 953),
        "body": (123, 1035, 901, 1295),
        "stats": [(148, 1372), (880, 1372)],
        "footer": (512, 1358),
    },
    "Epic": {
        "title": (151, 124, 873, 183),
        "type": (128, 916, 896, 969),
        "body": (125, 1037, 899, 1295),
        "stats": [(125, 1409), (901, 1409)],
        "footer": (512, 1350),
    },
    "Legendary": {
        "title": (144, 121, 880, 185),
        "type": (126, 916, 898, 965),
        "body": (125, 1016, 899, 1290),
        "stats": [(137, 1383), (888, 1383)],
        "footer": (512, 1330),
    },
}


def font(size, bold=False, serif=False):
    return ImageFont.truetype(
        str(
            FONTS
            / (
                "DejaVuSerif-Bold.ttf"
                if serif
                else "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
            )
        ),
        size,
    )


def wrap(text, f, width):
    out = []
    for para in text.split("\n"):
        line = ""
        for word in para.split():
            trial = (line + " " + word).strip()
            if line and f.getlength(trial) > width:
                out.append(line)
                line = word
            else:
                line = trial
        if line:
            out.append(line)
    return out


def center(d, text, box, size=44, bold=False, serif=False, fill="#f4efdf"):
    x1, y1, x2, y2 = box
    while font(size, bold, serif).getlength(text) > x2 - x1 and size > 18:
        size -= 1
    assert font(size, bold, serif).getlength(text) <= x2 - x1, text
    d.text(
        ((x1 + x2) / 2, (y1 + y2) / 2),
        text,
        font=font(size, bold, serif),
        fill=fill,
        anchor="mm",
        stroke_width=1,
        stroke_fill="#11121b",
    )
    return size


def regular(c, art, frames):
    frame, mask, bbox = frames[c["rarity"]]
    im = compose(
        art, frame, mask, bbox, "cover", c.get("framing", {"position": [0.5, 0.44]})
    )
    d = ImageDraw.Draw(im)
    lay = LAYOUT[c["rarity"]]
    center(d, c["name"], lay["title"], 44, serif=True)
    typ = c["card_type"] + (
        " · " + c["subtype"] if c["subtype"] != c["card_type"] else ""
    )
    center(d, typ, lay["type"], 30, bold=True, fill="#dedbd3")
    x1, y1, x2, y2 = lay["body"]
    tags, text = details(c)
    for size in range(35, 21, -1):
        heading = wrap(tags, font(size + 2, True), x2 - x1 - 6) if tags else []
        lines = wrap(text, font(size), x2 - x1 - 6)
        height = (
            len(heading) * (size + 8)
            + (12 if heading and lines else 0)
            + len(lines) * (size + 7)
        )
        if height <= y2 - y1:
            break
    else:
        raise ValueError("Rules overflow: " + c["name"])
    y = y1
    for line in heading:
        d.text(
            (x1 + 3, y),
            line,
            font=font(size + 2, True),
            fill="#ead29d",
            stroke_width=1,
            stroke_fill="#101214",
        )
        y += size + 8
    if heading and lines:
        y += 12
    for line in lines:
        d.text((x1 + 3, y), line, font=font(size), fill="#f0ede6")
        y += size + 7
    assert y <= y2, c["name"]
    if c["card_type"] == "Creature":
        for (x, y), value, label in zip(
            lay["stats"], [c["attack"], c["hp"]], ["ATK", "HP"]
        ):
            d.text((x, y - 24), label, font=font(17, True), fill="#d2c8b5", anchor="mm")
            d.text(
                (x, y + 13),
                str(value),
                font=font(56, True),
                fill="#faf4e8",
                anchor="mm",
                stroke_width=2,
                stroke_fill="#111",
            )
    d.text(
        lay["footer"],
        c["rarity"].upper() + " · " + c["id"] + " · " + set_title(c),
        font=font(15),
        fill="#c7c0b3",
        anchor="mm",
    )
    return im, {
        "font_size": size,
        "artwork_bounds": bbox,
        "crop": c.get("framing", {"position": [0.5, 0.44]}),
    }


def full(c, art, frame):
    w, h = frame.size
    im = ImageOps.fit(art.convert("RGBA"), (w, h), method=Image.Resampling.LANCZOS)
    scrim = Image.new("RGBA", (w, h))
    sd = ImageDraw.Draw(scrim)
    for y in range(h):
        top = max(0, 1 - abs(y - 155) / 200) * 120
        bottom = max(0, min(1, (y - 1030) / 180)) * 190
        sd.line((0, y, w, y), fill=(7, 10, 17, round(max(top, bottom))))
    im = Image.alpha_composite(Image.alpha_composite(im, scrim), frame)
    d = ImageDraw.Draw(im)
    center(d, c["name"], (142, 95, w - 142, 185), 62, serif=True)
    typ = c["card_type"] + (
        " · " + c["subtype"] if c["subtype"] != c["card_type"] else ""
    )
    center(d, typ, (130, 192, w - 130, 225), 24, fill="#e8d7b3")
    tags, text = details(c)
    width = 740
    end = 1400
    start = 1150
    for size in range(30, 21, -1):
        heading = wrap(tags, font(size + 4, True), width) if tags else []
        lines = wrap(text, font(size), width)
        height = (
            len(heading) * (size + 11)
            + (12 if heading and lines else 0)
            + len(lines) * (size + 7)
        )
        if start + height <= end:
            break
    else:
        raise ValueError("Full-art rules overflow: " + c["name"])
    y = start
    for line in heading:
        d.text(
            (w / 2, y),
            line,
            font=font(size + 4, True),
            fill="#f3d899",
            anchor="mt",
            stroke_width=2,
            stroke_fill="#101018",
        )
        y += size + 11
    if heading and lines:
        y += 12
    for line in lines:
        d.text(
            (w / 2, y),
            line,
            font=font(size),
            fill="#fff5df",
            anchor="mt",
            stroke_width=2,
            stroke_fill="#101018",
        )
        y += size + 7
    if c["card_type"] == "Creature":
        for x, value, label in [(105, c["attack"], "ATK"), (918, c["hp"], "HP")]:
            d.text(
                (x, 1404),
                label,
                font=font(20, True),
                anchor="mm",
                fill="#fff5df",
                stroke_width=2,
                stroke_fill="#101018",
            )
            d.text(
                (x, 1450),
                str(value),
                font=font(55, True),
                anchor="mm",
                fill="#fff5df",
                stroke_width=2,
                stroke_fill="#101018",
            )
    d.text(
        (w / 2, 1465),
        set_title(c) + " · " + c["id"] + " · FULL ART",
        font=font(18),
        anchor="mm",
        fill="#dfd0b8",
        stroke_width=1,
        stroke_fill="#101018",
    )
    mask = Image.new("L", (w, h))
    ImageDraw.Draw(mask).rounded_rectangle(
        (12, 12, w - 12, h - 12), radius=55, fill=255
    )
    im.putalpha(mask)
    return im, {"font_size": size, "text_end": y}


def illustration(card, art, frame):
    width, height = frame.size
    image = ImageOps.fit(
        art.convert("RGBA"), frame.size, method=Image.Resampling.LANCZOS
    )
    scrim = Image.new("RGBA", frame.size)
    shade = ImageDraw.Draw(scrim)
    for y in range(height):
        top = max(0, 1 - abs(y - 155) / 200) * 115
        bottom = max(0, min(1, (y - 1110) / 170)) * 170
        shade.line((0, y, width, y), fill=(7, 10, 17, round(max(top, bottom))))
    image = Image.alpha_composite(Image.alpha_composite(image, scrim), frame)
    draw = ImageDraw.Draw(image)
    center(draw, card["name"], (142, 95, width - 142, 185), 62, serif=True)
    types = card["card_type"] + (
        " · " + " · ".join(card.get("types", [card["subtype"]]))
        if card["subtype"] != card["card_type"]
        else ""
    )
    center(draw, types, (130, 192, width - 130, 225), 23, fill="#e8d7b3")
    for size in range(26, 19, -1):
        lines = wrap(card["rules"], font(size), 740)
        step = size + 6
        top = min(1270, 1360 - len(lines) * step + step / 2)
        if top >= 1160:
            break
    else:
        raise ValueError("Rule overflow: " + card["id"])
    for index, line in enumerate(lines):
        draw.text(
            (width / 2, top + index * step),
            line,
            font=font(size),
            fill="#f3efff",
            anchor="mm",
            stroke_width=2,
            stroke_fill="#101018",
        )
    if card["card_type"] == "Creature":
        for x, value, label in [(105, card["attack"], "ATK"), (918, card["hp"], "HP")]:
            draw.text(
                (x, 1404),
                label,
                font=font(20, True),
                anchor="mm",
                fill="#f3efff",
                stroke_width=2,
                stroke_fill="#101018",
            )
            draw.text(
                (x, 1450),
                str(value),
                font=font(55, True),
                anchor="mm",
                fill="#f3efff",
                stroke_width=2,
                stroke_fill="#101018",
            )
    draw.text(
        (width / 2, 1465),
        set_title(card) + "  ·  " + card["id"] + "  ·  ILLUSTRATION RARE",
        font=font(18),
        anchor="mm",
        fill="#ddd6ed",
        stroke_width=2,
        stroke_fill="#101018",
    )
    mask = Image.new("L", frame.size)
    ImageDraw.Draw(mask).rounded_rectangle(
        (12, 12, width - 12, height - 12), radius=55, fill=255
    )
    image.putalpha(mask)
    return image, {"font_size": size, "text_end": top + len(lines) * step}


def build():
    metadata = json.loads((SOURCE / "sources.json").read_text())
    definitions = {
        c["id"]: c
        for c in json.loads((ROOT / "Resources/Hex/Data/cards.json").read_text())
    }
    frames = {}
    for rarity in ["Rare", "Legendary"]:
        frame = Image.open(SOURCE / "templates" / (rarity.lower() + ".png")).convert(
            "RGBA"
        )
        mask, bounds = artwork_mask(frame)
        frames[rarity] = frame, mask, bounds
    full_frame = Image.open(SOURCE / "templates/full-art.png").convert("RGBA")
    silver = Image.open(SOURCE / "templates/illustration-rare.png").convert("RGBA")
    records = []
    for id, framing in metadata["framing"].items():
        card = {**definitions[id], "framing": framing}
        art = Image.open(SOURCE / "art" / (id + ".png"))
        variants = [
            ("", regular(card, art, frames)),
            ("-FA", full(card, art, full_frame)),
        ]
        rare_art = SOURCE / "illustration" / (id + ".png")
        if rare_art.exists():
            variants.append(("-IR", illustration(card, Image.open(rare_art), silver)))
        for suffix, (image, proof) in variants:
            assert image.size == (1024, 1536)
            output = ROOT / "Assets/Hex/cards" / (id + suffix + ".hextex")
            opaque_interior(image).save(output, format="WEBP", lossless=True, method=4)
            records.append(
                {
                    "id": id + suffix,
                    "rules": card["rules"],
                    "sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
                    **proof,
                }
            )
    (SOURCE / "render-report.json").write_text(json.dumps(records, indent=2) + "\n")
    manifest_path = ROOT / "Resources/Hex/Data/hd-art-manifest.json"
    manifest = json.loads(manifest_path.read_text())
    hashes = {r["id"]: r["sha256"] for r in records}
    for record in manifest["cards"]:
        if record["id"] in hashes:
            record["sha256"] = hashes[record["id"]]
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    print("Rendered", len(records), "revised card prints")


if __name__ == "__main__":
    build()
