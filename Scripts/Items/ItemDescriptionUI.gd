extends CanvasLayer
class_name ItemDescriptionUI

@onready var preview_sprite: Sprite2D = $Panel/GridContainer/HBoxContainer/SpritePlaceholder/Sprite2D
@onready var name_label: Label = $Panel/GridContainer/HBoxContainer/NameLabel
@onready var description_label: Label = $Panel/GridContainer/DescriptionLabel
@onready var effect_container: Container = $Panel/GridContainer/EffectContainer

var _item: ItemResource = null

func clear_ui():
	preview_sprite.texture = null
	name_label.text = ""
	for c in effect_container.get_children():
		c.queue_free()

func set_item(item: ItemResource):
	_item = item
	update_ui()

func update_ui():
	clear_ui()
	
	# Update right-hand preview box
	preview_sprite.texture = _item.icon
	preview_sprite.scale = Vector2(0.75, 0.75) # Adjust to your desired size
	name_label.text = _item.name
	description_label.text = _item.description
