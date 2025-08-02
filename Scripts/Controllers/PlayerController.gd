extends Node

@onready var movement = $Movement
@onready var interaction = $Interact
var inventory = Inventory.new()

func _ready():
	inventory.initialize(20)

func add_to_inventory(item: ItemResource, quantity: int) -> bool:
	return inventory.add_item(item, quantity)

func _physics_process(delta):
	movement.move(delta)
	interaction.check_input()
