extends Area3D
class_name UnitSlot

enum UnitSlotType {
	ALLY,
	ENEMY
}

@export var slot_number: int
@export var type: UnitSlotType
@export var arrow_scene: PackedScene = preload("res://Scenes/Arrow_Animated.tscn")

# Make this static so all slots share the same arrow reference
static var current_arrow: Node3D = null
var node: Node = null
var unit: Unit = null
var last_click_frame = -1

func _ready():
	node = self
	monitoring = true
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	if input_event.is_connected(_input_event):
		input_event.disconnect(_input_event)
	input_event.connect(_input_event)
	
func _on_mouse_entered():
	if BattleManager.is_targeting_mode and unit != null:
		# Clear any existing arrow
		clear_arrow()

		current_arrow = arrow_scene.instantiate()
		get_parent().add_child(current_arrow)
		current_arrow.global_position = global_position + Vector3(0, 0.25, 0)

		# Directly play animation since current_arrow *is* the AnimatedSprite3D
		current_arrow.animation = "default" # Optional, if it's not set
		current_arrow.play()

func _on_mouse_exited():
	clear_arrow()

func _input_event(_camera: Camera3D, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			
			# Frame-based debounce
			var current_frame = Engine.get_process_frames()
			if current_frame == last_click_frame:
				return
			last_click_frame = current_frame
			
			# Look for a Unit child in this slot
			var found_unit = null
			for child in get_children():
				if child is Unit:
					found_unit = child
					break
			
			if found_unit != null:
				# Only show arrow if we're in targeting mode
				if BattleManager.is_targeting_mode:
					# Clear any existing arrow first
					clear_arrow()
					
					current_arrow = arrow_scene.instantiate()
					get_parent().add_child(current_arrow)
					current_arrow.global_position = global_position + Vector3(0, 0.25, 0)

					# Directly play animation since current_arrow *is* the AnimatedSprite3D
					#current_arrow.animation = "default" # Optional, if it's not set
					current_arrow.play()
				
				# Always call select_target (it will handle targeting vs regular selection)
				BattleManager.select_target(found_unit)
			else:
				print("No unit in slot ", slot_number)

# Make this static so it can be called from anywhere
static func clear_arrow():
	if current_arrow != null and is_instance_valid(current_arrow):
		current_arrow.queue_free()
	current_arrow = null
		
# Add this function to get debug info
func debug_slot():
	print("=== Slot ", slot_number, " Debug Info ===")
	print("Type: ", type)
	print("Unit variable: ", unit.name if unit else "null")
	print("Children count: ", get_children().size())
	for i in range(get_children().size()):
		var child = get_children()[i]
		print("  Child ", i, ": ", child.name, " (", child.get_class(), ")")
	print("Monitoring: ", monitoring)
	print("Input pickable: ", input_ray_pickable)
	print("===========================")
