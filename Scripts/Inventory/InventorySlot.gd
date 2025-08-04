extends Control
class_name InventorySlot
@export var item: ItemResource
@export var quantity: int = 1
signal slot_clicked(inventory_slot)
@onready var textureRect: TextureRect = $TextureRect
@onready var label: Label = $Label
@onready var hoverBorder: Panel = $HoverBorder

func _ready():
	hoverBorder.visible = false
	
	# Connect signals
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)
	
	# Set mouse filter
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Prevent children from intercepting mouse input
	textureRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hoverBorder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Wait a frame to ensure layout is calculated
	await get_tree().process_frame

func set_item(item: ItemResource, quantity: int):
	self.item = item
	self.quantity = quantity
	
	if not textureRect:
		call_deferred("_update_ui")
	else:
		_update_ui()

func _update_ui():
	textureRect.texture = item.icon
	label.text = str(quantity) if quantity > 1 else ""

func _on_hover():
	hoverBorder.visible = true

func _on_unhover():
	hoverBorder.visible = false

# Alternative input detection method
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var global_rect = get_global_rect()
		if global_rect.has_point(event.global_position):
			if event.button_index == MOUSE_BUTTON_LEFT:
				slot_clicked.emit(self)
