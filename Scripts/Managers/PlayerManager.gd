extends Node

var player: PlayerData = PlayerData.new()
var inventory_slots: int = 10

func _ready():
	player.name = "Felix"
	player.current_hp = player.max_hp
	player.visual_scene = load("res://Scenes/MainCharacter.tscn")

func add_xp(amount: int):
	player.experience += amount
	print("XP: ", player.experience)

func set_hp(amount: int):
	player.current_hp = clamp(amount, 0, player.max_hp)
	print("HP: ", player.current_hp)

func add_hp(amount: int):
	set_hp(player.current_hp + amount)
