extends "res://addons/gut/test.gd"

const FadeLayer = preload("res://Scripts/FadeLayer.gd")

var fade: FadeLayer
var color_rect: ColorRect

func before_each():
	# Create the ColorRect that FadeLayer expects
	color_rect = ColorRect.new()
	color_rect.name = "ColorRect"
	color_rect.modulate.a = 0.0
	color_rect.visible = false

	# Instantiate FadeLayer and inject ColorRect before _ready
	fade = FadeLayer.new()
	fade.add_child(color_rect)

	add_child(fade)  # Triggers _ready()

func after_each():
	if is_instance_valid(fade):
		fade.queue_free()
	await get_tree().process_frame

func test_fade_in_sets_visible_and_alpha_1():
	fade.fade_in()
	await fade.get_tree().create_timer(fade.fade_duration + 0.1).timeout
	assert_true(color_rect.visible)
	assert_almost_eq(color_rect.modulate.a, 1.0, 0.01)

func test_fade_out_starts_tween_and_queues_free():
	var tween_count_before := fade.get_tree().get_processed_tweens().size()

	fade.fade_out()

	assert_true(fade.is_queued_for_deletion())

	# Optional: you could assert the tween started by checking modulate.a is increasing
	assert_true(fade.get_tree().get_processed_tweens().size() > tween_count_before)
