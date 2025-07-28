extends TextureButton

@export var hover_tint: Color = Color(0.8, 0.8, 0.8)  # Slightly darker
@export var normal_tint: Color = Color(1, 1, 1)       # Default color

func _ready():
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)
	pressed.connect(_on_load_pressed)
	modulate = normal_tint

func _on_hover():
	modulate = hover_tint

func _on_unhover():
	modulate = normal_tint

func _on_exit():
	modulate = Color(1, 1, 1)

func _on_load_pressed():
	print("Load button clicked!")
	# TODO: add actual load logic here (scene change, file dialog, etc.)
	# TEST STUFF
	get_tree().quit()
