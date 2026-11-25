# Test-area terrain

`Assets/Sprites/Terrain/test_area.png` is the original generated terrain artwork.
It includes grass variations, flowers, clover, dirt, sand, gravel, cobblestone,
water, cliff rock, soil and path shapes in a 4x4 source sheet.

`test_area_autotiles.png` is the 1024x1024 transition sheet used by the game:
64 tiles, 128x128 pixels each, arranged in eight columns and eight rows.
Every two rows form one complete 16-pattern corner set:

| Rows | Transition |
| --- | --- |
| 1–2 | Grass ↔ dirt |
| 3–4 | Grass ↔ water |
| 5–6 | Grass ↔ stone |
| 7–8 | Grass ↔ sand |

Within each set, tile indices 0–15 encode top-left, top-right, bottom-left and
bottom-right corners as bits 1, 2, 4 and 8. Matching corner values give matching
border pixels. The exporter renders periodic source sampling and shared masks,
then checks compatible edges pixel by pixel. Corners, straight edges, isolated
patches and concave joins are included.

## Painting

Open `Scenes/Environments/TerrainPainting.tscn` and select the Terrain layer.
In Godot's TileMap editor, use Terrains / Connect with Grass, Dirt, Water, Stone
or Sand. Start with a grass area, then paint paths and patches with the other
brushes. The TileSet includes metadata for both grass-centred and material-centred
transitions, plus empty map boundaries. Each transition family connects through
grass; use grass between different non-grass materials.

The existing 3D test area uses these same atlas tiles through
`Resources/Terrain/test_area_ground.tres`. Its material paints a grass meadow and
crossing paths over the original ground mesh; actor positions and collision shapes
are unchanged. `tile_count` controls ground tile density, and the corner layout is
in `test_area_ground.gdshader`.

## Rebuilding

After importing the original source artwork, export the transition atlas using a
render-capable Godot instance:

```sh
godot --path . --rendering-method gl_compatibility --script res://tools/terrain/build_terrain_tiles.gd
```

Then let the editor reimport the PNG. Commit both PNGs, their import files, the
TileSet and shader resources. The exporter requires rendering; normal validation
of the committed assets works headlessly:

```sh
godot --headless --path . --script res://Tests/Player/terrain_tiles_test.gd
```

The regression verifies all 896 compatible horizontal/vertical edge pairs,
corner metadata and editor-style painting for all five terrains without holes.
