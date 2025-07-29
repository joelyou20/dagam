extends Node

var inventory: Array[String]
var experience: int = 0

func add_to_inventory(item: String, quantity: int):
	for i in range(0, quantity):
		inventory.append(item)
	
func add_xp(amount: int):
	experience += amount
