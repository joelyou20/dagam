"""Regression coverage for ability wells accidentally exported with alpha holes."""

import unittest
from pathlib import Path
from PIL import Image, ImageChops
from card_opacity import opaque_interior


class CardOpacityTests(unittest.TestCase):
    def test_interior_repairs_alpha_without_darkening_rgb(self):
        source = Image.new("RGBA", (256, 384), (130, 95, 170, 7))
        fixed = opaque_interior(source)
        self.assertEqual(fixed.getpixel((128, 290)), (130, 95, 170, 255))
        self.assertIsNone(
            ImageChops.difference(source.convert("RGB"), fixed.convert("RGB")).getbbox()
        )

    def test_outer_corners_and_existing_opaque_pixels_are_preserved(self):
        source = Image.new("RGBA", (256, 384), (25, 30, 40, 0))
        source.putpixel((128, 200), (230, 210, 200, 255))
        fixed = opaque_interior(source)
        self.assertEqual(fixed.getpixel((0, 0)), source.getpixel((0, 0)))
        self.assertEqual(fixed.getpixel((128, 200)), source.getpixel((128, 200)))

    def test_all_exported_cards_have_opaque_interiors(self):
        root = Path(__file__).resolve().parents[2]
        cards = list((root / "Assets/Hex/cards").glob("*.hextex"))
        self.assertGreater(len(cards), 300)
        for path in cards:
            with self.subTest(card=path.stem), Image.open(path) as source:
                source = source.convert("RGBA")
                difference = ImageChops.difference(
                    source.getchannel("A"), opaque_interior(source).getchannel("A")
                )
                self.assertIsNone(difference.getbbox())


if __name__ == "__main__":
    unittest.main()
