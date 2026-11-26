# Free play and effect Planes

Standard decks contain exactly 20 cards, with at most two copies of each card across cosmetic variants. All cards are free to play. There is no Power pool, Power phase, casting cost, or terrain compatibility restriction. Opening hands and subsequent draws remain random. Creature tribes and ability tags remain in place.

The six basic Planes and fifteen basic dual Planes have no effects and are retired from deck building. Historical IDs and illustrations remain readable for existing collections. Saved decks drop these cards; oversized decks are trimmed to 20 while retaining legal active cards. Complete legacy decks that become too short are filled from the starter deck within the two-copy limit. Incomplete drafts remain drafts.

Effect Planes remain: Sacred Spring heals its occupant at its controller's pre-combat phase; Wall of Light shields the friendly creature behind it at the opponent's combat phase; Door to Ashgar summons a Goblin Punk with Sprint and Doomed on an empty hex. Erupt creates Volcanic Vent, which damages its occupant at pre-combat. Vent is generated only and cannot be placed in a deck.

A Plane may be played onto an unlocked friendly hex in pre- or post-combat, at most once per owner turn. Replacing a Plane changes that hex's effect; it does not generate resources, restrict placement, or bounce its occupant. Explicit effects such as Erupt may change enemy hexes. Hex locks remain encounter restrictions on Plane replacement.

Match schema 3 removes old Power pools and inert Planes from saved hand/deck/discard zones, clears basic terrain, and preserves creature identity, damage, ownership and active Plane effects. Saved practice games within encounters migrate too. Future draw order is preserved when retired cards are removed.

Run `python tools/hex/build_engine.py` after editing rule modules or card data. Card textures load directly without resource overlays. `tools/cards/render_foundations.py` rebuilds regular and full-art Foundations frames with the card type alone.
