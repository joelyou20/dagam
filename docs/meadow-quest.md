# A Dance for the Meadow

Run the existing project / `Scenes/TerrainTest.tscn`. Captain Rowan stands beside the steps, just north-west of the player spawn. Interact and accept his request. Speak to Liora at the flower patch on the eastern side of the lower meadow, take her invitation back to Rowan, then return to Liora and ask to see her encore. Completion grants 25 player XP once.

The quest uses the existing `NPC`, `DialogResource`, `DialogEntry`, `DialogCondition`, `QuestTask`, `FlagTask`, `StartQuestDialogAction`, `QuestResource`, `QuestObjective` and `QuestRewardXP` classes. The journal displays the three resource-authored objectives and checkmarks. Both NPCs have follow-up dialogue, and visiting Liora before accepting the quest is supported.

Progress, dialog and rewards use the normal world save. Quest completion is recorded before rewards are applied, repeated visits cannot repeat XP, and loading a completed save does not apply rewards again. Older saves reset absent Meadow flags/dialog to their defaults. Existing quest IDs/flag indices are preserved by appending the new entries; unrelated locked quest defaults remain locked.

## Character sheets

- `Assets/Sprites/Characters/soldier.png`: Captain Rowan, navy/silver armor and a crimson cape.
- `Assets/Sprites/Characters/dancer.png`: Liora, coral/cream dance dress, teal sash and floral hair ornament.

Both original generated transparent PNGs are retained unchanged. Each has 64 cells: eight columns and eight rows. Rows are idle down, walk down, idle left, walk left, idle right, walk right, idle up, walk up. The associated scenes use idle animation, nearest filtering, billboard rendering and alpha discard for clean edges. All four walking directions are available for future movement.

Rebuild resources with:

```sh
python tools/player/build_player_frames.py --atlas Assets/Sprites/Characters/soldier.png --output Resources/Characters/soldier_frames.tres
python tools/player/build_player_frames.py --atlas Assets/Sprites/Characters/dancer.png --output Resources/Characters/dancer_frames.tres
python tools/quests/build_meadow_quest.py
python tools/terrain/build_meadow_scene.py
```

Run `godot --headless --path . res://Tests/Quests/MeadowQuest.tscn` to verify NPC proximity/input, all animation frames, decline/accept, objective ordering, journal progress, save/resume, completion, duplicate-reward protection and legacy-save defaults. Existing Farmer recruitment, Meadow elevation/rival battles, shop, and root-project save integration are also regression-tested.
