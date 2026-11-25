"""Keep exported card interiors solid without filling decorative outer corners."""

from PIL import Image, ImageChops, ImageDraw


def opaque_interior(image):
    result = image.convert("RGBA")
    width, height = result.size
    interior = Image.new("L", result.size)
    # All artwork, titles and rules wells lie inside this inset. Do not replace
    # RGB or alpha-composite onto black: either would darken existing artwork.
    ImageDraw.Draw(interior).rounded_rectangle(
        (
            round(width * 0.065),
            round(height * 0.035),
            round(width * 0.935),
            round(height * 0.965),
        ),
        radius=round(width * 0.03),
        fill=255,
    )
    result.putalpha(ImageChops.lighter(result.getchannel("A"), interior))
    return result
