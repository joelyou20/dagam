extends CanvasLayer
class_name FadeLayer

@export var fade_time := 0.5
@onready var color_rect: ColorRect = $ColorRect

func fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, fade_time)
	tween.finished

func fade_in() -> void:
	color_rect.modulate.a = 1.0
	color_rect.visible = true

	var tween := create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, fade_time)
