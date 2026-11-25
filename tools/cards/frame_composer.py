"""Reusable masked-frame composition from the existing Hex authoring pipeline."""

from PIL import Image, ImageDraw, ImageOps


def artwork_mask(frame):
    # Extract the connected dark artwork well, preserving curved corners and trim.
    rgb = frame.convert("RGB")
    binary = Image.eval(rgb, lambda p: 255 if p < 80 else 0)
    red, green, blue = binary.split()
    from PIL import ImageChops

    binary = ImageChops.darker(ImageChops.darker(red, green), blue)
    seed = (frame.width // 2, frame.height // 3)
    # Use center scan lines to constrain detection to the art panel, excluding dark trim.
    x, y = seed
    left = right = x
    top = bottom = y
    while left > 0 and binary.getpixel((left - 1, y)) == 255:
        left -= 1
    while right < frame.width - 1 and binary.getpixel((right + 1, y)) == 255:
        right += 1
    while top > 0 and binary.getpixel((x, top - 1)) == 255:
        top -= 1
    while bottom < frame.height - 1 and binary.getpixel((x, bottom + 1)) == 255:
        bottom += 1
    bound = Image.new("L", frame.size)
    ImageDraw.Draw(bound).rectangle((left, top, right, bottom), fill=255)
    binary = ImageChops.darker(binary, bound)
    marked = binary.copy()
    assert marked.getpixel(seed) == 255, "Artwork seed must be inside blank well"
    ImageDraw.floodfill(marked, seed, 128, thresh=0)
    mask = marked.point(lambda p: 255 if p == 128 else 0)
    bbox = mask.getbbox()
    assert bbox and bbox[1] > frame.height * 0.1 and bbox[3] < frame.height * 0.65, bbox
    return mask, bbox


def compose(art, frame, mask, bbox, fit, framing=None):
    # Always scale proportionally to cover the ENTIRE artwork window.
    # Never letterbox, blur-fill, stretch or zoom out below cover scale.
    import math

    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    framing = framing or {}
    zoom = max(1, float(framing.get("zoom", 1)))
    position = tuple(framing.get("position", [0.5, 0.38]))
    scale = max(w / art.width, h / art.height) * zoom
    resized = art.convert("RGBA").resize(
        (math.ceil(art.width * scale), math.ceil(art.height * scale)),
        Image.Resampling.LANCZOS,
    )
    x = round((resized.width - w) * max(0, min(1, position[0])))
    y = round((resized.height - h) * max(0, min(1, position[1])))
    stage = resized.crop((x, y, x + w, y + h))
    assert stage.size == (w, h) and stage.getchannel("A").getextrema() == (
        255,
        255,
    ), "Artwork must completely cover its window"
    canvas = Image.new("RGBA", frame.size)
    canvas.paste(stage, bbox[:2])
    return Image.composite(canvas, frame.convert("RGBA"), mask)
