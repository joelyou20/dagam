extends CanvasLayer
class_name FadeLayer

@export var fade_time := 0.5

@onready var color_rect: ColorRect

func initialize():
	color_rect = $ColorRect

func fade_out() -> void:
	if not color_rect:
		push_error("ColorRect is null!")
		return

	color_rect.modulate.a = 0.0
	color_rect.visible = true

	var tween := create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, fade_time)
	tween.finished

func fade_in() -> void:
	color_rect.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, fade_time)
	tween.finished
