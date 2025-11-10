extends Node
class_name Unit

enum UnitType { UNSET, PLAYER, ALLY, ENEMY }

var resource: EntityResource
var type: UnitType
var is_player_controlled := false
var is_alive := true
var next_turn_time: int = -1

@onready var _rng := RandomNumberGenerator.new()

signal hp_change(amount: int)

func take_damage(amount: int) -> void:
	if not is_alive:
		return

	resource.current_hp = max(resource.current_hp - amount, 0)
	_play_hit_fx()

	if resource.current_hp <= 0:
		die()
		
	hp_change.emit(amount)

func die() -> void:
	is_alive = false
	resource.current_hp = 0
	print(resource.name, " has fallen.")

	var slot = get_parent()
	if slot and slot is UnitSlot:
		for child in slot.get_children():
			if child is Sprite3D:
				child.queue_free()
		slot.unit = null

	queue_free()

# --- FX helpers --------------------------------------------------------------

func _play_hit_fx() -> void:
	var visual : Node3D = _get_visual_node()
	if visual == null:
		return
		
	# 1) Flash red
	var original_mod : Color = visual.modulate
	var flash := visual.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	flash.tween_property(visual, "modulate", Color(1.0, 0.25, 0.25, original_mod.a), 0.06)
	flash.tween_property(visual, "modulate", original_mod, 0.14)

	# 2) Shake position (very small, very quick)
	var original_pos := visual.position
	var strength := 0.08      # tweak: how far it shakes
	var duration := 0.18      # total shake time
	var steps := 6

	_rng.randomize()
	var shake := visual.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in steps:
		var offset := Vector3(
			_rng.randf_range(-strength, strength),
			0.0, # or add a little Y jiggle if you like
			_rng.randf_range(-strength, strength)
		)
		shake.tween_property(visual, "position", original_pos + offset, duration / float(steps))
	# snap back to exact origin at the end
	shake.tween_property(visual, "position", original_pos, 0.05)

func _get_visual_node() -> Node3D:
	# Finds the instantiated visual under the UnitSlot (prefers Sprite3D)
	var slot := get_parent()
	if slot and slot is UnitSlot:
		# 1) Common name
		var n := slot.get_node_or_null("Sprite3D")
		if n: return n as Node3D
		# 2) First Sprite3D child
		for c in slot.get_children():
			if c is Sprite3D:
				return c
		# 3) Fallback: any Node3D child (e.g., your visual scene root)
		for c in slot.get_children():
			if c is Node3D:
				return c
	return null
