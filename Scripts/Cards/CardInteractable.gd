extends Interactable

@export var card: CardResource

func _on_interact() -> void:
	DeckManager.add_card_to_collection(card)
