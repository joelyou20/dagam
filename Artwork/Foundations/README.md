# Foundations authoring sources

This set contains 26 unique illustrations and 52 framed prints: regular rarity
frames and full-art versions. Foundations is playable with the Plane/Power rules. Original source art lives in art/; its per-card art direction, costs,
terrain types and exact rules are in Resources/Hex/Data/foundations.json.

Reusable frames and licensed fonts are preserved in Artwork/Templates. The renderer
uses the existing masked-frame pipeline, proportional cover crops and measured text
wrapping. It asserts that every print is 1024x1536, source art is unique and rules
fit the text area. Basic and basic dual Planes deliberately have no rules text.
All Plane cards are free. Erupt costs 1 Earth and 1 Fire.

Install the Python dependencies in requirements-dev.txt, then run from the project:

    python tools/cards/render_foundations.py

Use --partial while authoring only a subset of illustrations. The renderer writes
Assets/Hex/cards/FD-*.hextex (WebP), small review previews, contact sheets and a
render-report.json containing source/output hashes and font sizes. Fonts are
bundled so the authoring pipeline works without a Linux-specific font location.

In the game, filter the deck catalog to Foundations, or use the shop's Foundations
tab to browse regular and full-art prints. All authored cards are in the native
catalog. Volcanic Vent is created by Erupt and cannot be added to decks or acquired
as stock. Foundations has no booster product yet; singles are free testing stock.

Cost and creature terrain labels are composited at texture load from transparent
overlays in Assets/Hex/costs. Rebuild them with:

    python tools/cards/render_cost_badges.py

See docs/hex-planes.md for implemented timing, terrain compatibility and deck rules.
