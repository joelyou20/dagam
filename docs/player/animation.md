# Player movement artwork

The exploration player uses `Assets/Sprites/Player/adventurer.png`: a transparent
64-frame atlas of a chestnut-haired adventurer wearing a teal cape, cream shirt,
navy trousers, boots and a card satchel. The original generated image is retained
without raster edits.

The atlas has eight columns and eight rows. Rows, from top to bottom:

1. Idle down
2. Walk down
3. Idle left
4. Walk left
5. Idle right
6. Walk right
7. Idle up
8. Walk up

Each row loops through all eight columns. Idle runs at 5 FPS; walking runs at
10 FPS, scaled to actual travel speed. Movement is restricted to four cardinal directions. When two perpendicular keys
are held, the newest key wins; releasing it resumes the remaining held direction.
Simultaneous equal inputs keep the previous axis, and analogue input uses its
stronger axis. Stopping retains the last facing. Walls and interaction
blockers return the player to idle.

`Scenes/Player.tscn` keeps the existing CharacterBody3D, collision, camera and
movement/interaction nodes. Its Sprite child is now an AnimatedSprite3D using
nearest filtering and the existing billboard orientation. PlayerAnimation handles
presentation separately from PlayerMovement; PlayerController supplies actual
travel after movement resolves.

Regenerate the SpriteFrames resource after replacing the atlas with another 8x8
sheet with the same row layout:

```sh
python tools/player/build_player_frames.py
```

The resource uses fractional atlas regions if the source size is not divisible
by eight. Keep all characters centered with a consistent foot baseline. Adjust
`pixel_size` and Sprite position in the player scene if a replacement uses a
different frame scale. Do not resize the source sheet to build the resource.

Run the movement regression:

```sh
godot --headless --path . --script res://Tests/Player/player_animation_test.gd
```

The test checks animation loops and atlas bounds, all cardinal facings, idle
retention, playback, interaction blockers, actual player input and a physical wall.
