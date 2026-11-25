class_name Shopkeeper
extends Interactable

func _on_interact() -> void:
	ShopManager.open_shop()
