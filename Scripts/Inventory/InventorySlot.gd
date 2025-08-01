extends Control
class_name InventorySlot

@export var item: ItemResource
@export var quantity: int = 1

signal slot_clicked(inventory_slot)

var textureRect: TextureRect
var label: Label
var hoverBorder: Panel

func _ready():
	hoverBorder.visible = false
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)
	set_mouse_filter(Control.MOUSE_FILTER_STOP)

func initialize():
	textureRect = $TextureRect
	label = $Label
	hoverBorder = $HoverBorder

	# Prevent children from intercepting mouse input
	textureRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hoverBorder.mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_item(item: ItemResource, quantity: int):
	self.item = item
	self.quantity = quantity
	textureRect.texture = item.icon
	label.text = str(quantity) if quantity > 1 else ""

func _gui_input(event):
	# TODO change this to a "select" button instead of mouse left
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("slot_clicked", self)

func _on_hover():
	hoverBorder.visible = true

func _on_unhover():
	hoverBorder.visible = false
