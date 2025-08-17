extends CanvasLayer
class_name FadeLayer

var color_rect: ColorRect
var tween: Tween
var is_fading = false

# Fade settings
@export var fade_duration: float = 1.0
@export var wait_duration: float = 2.0
@export var fade_color: Color = Color.BLACK

# Signals
signal fade_completed
signal fade_in_started
signal fade_out_started
signal wait_started
signal ready_to_fade

func _ready():
	# Find the ColorRect child
	color_rect = get_node("ColorRect") as ColorRect
	if not color_rect:
		# Try to find any ColorRect child
		for child in get_children():
			if child is ColorRect:
				color_rect = child
				break
	
	# Make sure the ColorRect is properly set up
	if color_rect:
		# Ensure it's visible and covers the screen
		color_rect.visible = true
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Set up anchors to fill the screen
		color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		# Set the color with full opacity for the fade color, but start transparent
		color_rect.color = Color(fade_color.r, fade_color.g, fade_color.b, 0.0)
		
		# Make sure modulate is white (so color property works correctly)
		color_rect.modulate = Color.WHITE
		
		# Signal that we're ready to fade
		ready_to_fade.emit()
	else:
		push_error("FadeLayer: No ColorRect found as child!")

# Main fade function - fades out, waits, then fades in
func fade_transition(fade_out_time: float = fade_duration, wait_time: float = wait_duration, fade_in_time: float = fade_duration):
	if is_fading or not color_rect:
		return
	
	is_fading = true
	
	# Create new tween
	if tween:
		tween.kill()
	tween = create_tween()
	
	# Fade out (to opaque)
	fade_out_started.emit()
	tween.tween_property(color_rect, "color:a", 1.0, fade_out_time)
	
	# Wait
	await tween.finished
	wait_started.emit()
	tween = create_tween()
	tween.tween_interval(wait_time)
	
	# Fade in (to transparent)
	await tween.finished
	fade_in_started.emit()
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, fade_in_time)
	
	await tween.finished
	is_fading = false
	fade_completed.emit()

# Fade out only
func fade_out(duration: float = fade_duration):
	if is_fading or not color_rect:
		return
	
	is_fading = true
	fade_out_started.emit()
	
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, duration)
	
	await tween.finished
	is_fading = false
	fade_completed.emit()

# Fade in only
func fade_in(duration: float = fade_duration):
	if is_fading or not color_rect:
		return
	
	is_fading = true
	fade_in_started.emit()
	
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, duration)
	
	await tween.finished
	is_fading = false
	fade_completed.emit()

# Set the fade color
func set_fade_color(new_color: Color):
	fade_color = new_color
	if color_rect:
		color_rect.color = Color(fade_color.r, fade_color.g, fade_color.b, color_rect.color.a)

# Check if currently fading
func get_is_fading() -> bool:
	return is_fading

# Instantly set to black (or fade color)
func instant_fade_out():
	if color_rect:
		color_rect.visible = true
		color_rect.color = Color(fade_color.r, fade_color.g, fade_color.b, 1.0)
	fade_completed.emit()

# Instantly set to transparent
func instant_fade_in():
	if color_rect:
		color_rect.color = Color(fade_color.r, fade_color.g, fade_color.b, 0.0)
	fade_completed.emit()
