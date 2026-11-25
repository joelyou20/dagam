# Foundations authoring sources

This set contains 26 unique illustrations and 52 framed prints: regular rarity
frames and full-art versions. The cards are preview-only until Plane gameplay is
implemented. Original source art lives in art/; its per-card art direction, costs,
terrain types and exact rules are in Resources/Hex/Data/foundations.json.

Reusable frames and licensed fonts are preserved in Artwork/Templates. The renderer
uses the existing masked-frame pipeline, proportional cover crops and measured text
wrapping. It asserts that every print is 1024x1536, source art is unique and rules
fit the text area. Basic and basic dual Planes deliberately have no rules text.
No costs are invented for cards whose cost was not specified.

Install the Python dependencies in requirements-dev.txt, then run from the project:

    python tools/cards/render_foundations.py

Use --partial while authoring only a subset of illustrations. The renderer writes
Assets/Hex/cards/FD-*.hextex (WebP), small review previews, contact sheets and a
render-report.json containing source/output hashes and font sizes. Fonts are
bundled so the authoring pipeline works without a Linux-specific font location.

In the game, filter the deck catalog to Foundations, or use the shop's Foundations
preview tab. The shop preview tab also displays the full-art prints. Preview IDs
are excluded from native card definitions, battle decks, booster pools and shop
acquisitions. Gameplay, resource spending, deck size and Plane effects are unchanged.

Volcanic Vent is marked generated_only for the future Erupt implementation. The
printed references to Sprint and Doomed preserve the requested wording; their new
Plane interactions will be implemented with the Plane rules in a later change.
