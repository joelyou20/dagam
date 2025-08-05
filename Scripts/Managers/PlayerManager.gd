extends Node

var player: PlayerData = PlayerData.new()
var inventory_slots: int = 10

func _ready():
	player.id = "player"
	player.name = "Felix"
	player.current_hp = player.max_hp
	player.attack_power = 20
	player.visual_scene = load("res://Scenes/Player_Battler.tscn")

func get_player_node() -> Node:
	return $"/root/World/Player"

func add_xp(amount: int):
	player.experience += amount
	print("XP: ", player.experience)

func set_hp(amount: int):
	player.current_hp = amount
	print("HP: ", player.current_hp)

func add_hp(amount: int):
	set_hp(player.current_hp + amount)
