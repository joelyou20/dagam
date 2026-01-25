extends Node

# BattleController - Attached to root node of CardBattleScene
# Initializes card battle when scene loads

@onready var BattleUIScene := preload("res://Scenes/UI/Battle/BattleUI.tscn")

var card_battle_system: CardBattleSystem = null
var battle_ui: BattleUI = null
var battle_data: BattleData = null

func _ready():
	# Initialize card battle system
	_initialize_card_battle()

func _initialize_card_battle():
	# Get or create CardBattleSystem
	card_battle_system = get_node_or_null("CardBattleSystem") as CardBattleSystem
	if not card_battle_system:
		# Create CardBattleSystem as a child of this node
		card_battle_system = CardBattleSystem.new()
		card_battle_system.name = "CardBattleSystem"
		add_child(card_battle_system)
	
	# Get battle data from BattleManager
	battle_data = BattleManager.current_battle_data
	if not battle_data:
		push_error("No battle data found! Battle cannot start.")
		return
	
	# Initialize the card battle
	card_battle_system.initialize_battle(battle_data)
	
	# Connect to battle end signal
	if not card_battle_system.battle_state_changed.is_connected(_on_battle_state_changed):
		card_battle_system.battle_state_changed.connect(_on_battle_state_changed)
	
	# Setup UI
	_setup_ui()
	
	# Disable overworld player
	_disable_overworld_player()

func _setup_ui():
	# Create and show BattleUI
	if BattleUIScene:
		battle_ui = BattleUIScene.instantiate() as BattleUI
		# Add to scene tree (usually under a UI layer or root)
		var ui_parent = get_tree().root
		ui_parent.add_child(battle_ui)
		battle_ui.show_ui()
		
		# Note: Card battles don't use units, so we don't populate enemy/ally info
		# The BattleUI is kept for compatibility but doesn't need unit data
	else:
		push_error("BattleUI scene not found at res://Scenes/UI/Battle/BattleUI.tscn!")

func _on_battle_state_changed(new_state: CardBattleSystem.BattleState):
	# Handle battle state changes
	if new_state == CardBattleSystem.BattleState.ENDED:
		_end_battle()

func _end_battle():
	# End the card battle
	InteractionHandler.unblock("battle")
	
	# Enable overworld player
	_enable_overworld_player()
	
	# Hide and cleanup UI
	if battle_ui:
		battle_ui.hide_ui()
		battle_ui.queue_free()
		battle_ui = null
	
	# Notify BattleManager that battle ended
	BattleManager.battle_ended.emit()
	
	# Return to previous scene
	if BattleManager.pre_battle_scene_path != "":
		SceneManager.load_scene(BattleManager.pre_battle_scene_path, true, true, "", 0.1)
		await SceneManager.scene_loaded
		
		# Restore player position
		var player_node := PlayerManager.get_player_node()
		if player_node:
			player_node.global_transform.origin = BattleManager.pre_battle_player_position
	else:
		push_error("No pre-battle scene path stored. Cannot return to previous scene.")

func _disable_overworld_player():
	var player_node := PlayerManager.get_player_node()
	if player_node:
		player_node.visible = false
		player_node.set_process(false)
		player_node.set_physics_process(false)
		player_node.set_collision_layer(0)
		player_node.set_collision_mask(0)

func _enable_overworld_player():
	var player_node := PlayerManager.get_player_node()
	if player_node:
		player_node.visible = true
		player_node.set_process(true)
		player_node.set_physics_process(true)
		# Restore collision layers from BattleManager
		if BattleManager.player_collision_layer:
			player_node.set_collision_layer(BattleManager.player_collision_layer)
		if BattleManager.player_collision_mask:
			player_node.set_collision_mask(BattleManager.player_collision_mask)
