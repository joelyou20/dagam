# Foundations artwork

Foundations uses regular rarity frames and full-art variants. Original illustrations live in `art/`; the canonical card metadata is in `Resources/Hex/Data/foundations.json`.

All cards play for free, without Power or terrain requirements. The 21 inert basic and dual Planes are retired from decks. Sacred Spring, Wall of Light, Door to Ashgar, Erupt and the generated Volcanic Vent retain their effects. Creature tribes and abilities remain in place.

Rebuild card frames and full-art variants with:

    python tools/cards/render_foundations.py

The renderer prints the card category and rules without terrain types or casting costs. Original art and frame templates remain unchanged. Card textures load directly; no resource overlays are composited.

See `docs/hex-planes.md` for current rules and save migration. `render-report.json` records per-print hashes and original-art hashes.
