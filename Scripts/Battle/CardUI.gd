extends Node
class_name CardUI

# CardUI - Displays a single card in the UI

# Node references (should match scene structure)
@onready var name_label: Label = $NameLabelText
@onready var ability_label: Label = $AbilityLabelText
@onready var tags_label: Label = $TagsLabelText
@onready var set_label: Label = $SetLabelText
@onready var strength_label: Label = $StrengthLabelText
@onready var card_image_sprite: TextureRect = $CardImageSprite

var card_resource: CardResource = null

signal card_clicked(card: CardResource)
signal card_hovered(card: CardResource)

func set_card(card: CardResource):
	# Update UI with card data
	card_resource = card
	_update_ui()

func _update_ui():
	if not card_resource:
		return
	
	# Update name
	if name_label:
		name_label.text = card_resource.name
	
	# Update ability (use ability field, fallback to description)
	if ability_label:
		var ability_text = card_resource.ability
		if ability_text.is_empty():
			ability_text = card_resource.description
		ability_label.text = ability_text
	
	# Update tags (join array into comma-separated string)
	if tags_label:
		var tags_text = ""
		if card_resource.tags.size() > 0:
			tags_text = ", ".join(card_resource.tags)
		tags_label.text = tags_text
	
	# Update set
	if set_label:
		set_label.text = card_resource.card_set
	
	# Update strength (use strength field, fallback to attack from creature_stats)
	if strength_label:
		var strength_value = card_resource.strength
		if strength_value == 0 and card_resource.creature_stats.has("attack"):
			strength_value = card_resource.creature_stats["attack"]
		strength_label.text = str(strength_value)
	
	# Update card image
	if card_image_sprite and card_resource.card_image:
		card_image_sprite.texture = card_resource.card_image

func get_card() -> CardResource:
	return card_resource

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if card_resource:
			card_clicked.emit(card_resource)

func _on_mouse_entered():
	if card_resource:
		card_hovered.emit(card_resource)

func _on_mouse_exited():
	pass
