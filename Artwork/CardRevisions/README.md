# Revised card print sources

These are the original approved illustrations and matching card frames, recovered from the source repository revision recorded in `sources.json`. No new illustrations were generated.

Canonical rules and stats come from `Resources/Hex/Data/cards.json`. Rebuild the four regular/full-art cards and the two existing Illustration Rare variants with:

    python tools/cards/render_revisions.py

The renderer uses bundled fonts, preserves the original crops, measures rules against the available text area, normalizes interior opacity, and updates output hashes in `render-report.json` and the HD-art manifest.
