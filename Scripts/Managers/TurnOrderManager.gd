extends Node

signal turn_advanced(prev: int, next: int)

var battle_time: float = 0.0

# Just IDs, no Units here
var turn_order_queue: Array[String] = []

# Per-ID timing: id -> next_turn_time
var _next_turn_times: Dictionary = {} # { int: float }

func setup(units: Array[Unit]) -> void:
	# speeds: { id: speed_int }
	battle_time = 0.0
	_next_turn_times.clear()
	
	update(units)
	
func update(units: Array[Unit]):
	turn_order_queue.clear()
	for unit in units:
		var speed : int = unit.resource.speed
		speed = max(speed, 1)

		_next_turn_times[unit.resource.id] = _compute_initial_time(speed)
		turn_order_queue.append(unit.resource.id)

	_sort_turn_order()

func _compute_initial_time(speed: int) -> float:
	# Lower result = acts sooner
	var spd : int = max(speed, 1)
	return 100.0 / float(spd)

func _compute_turn_cost(speed: int) -> float:
	var spd : int = max(speed, 1)
	return 100.0 / float(spd)

func _sort_turn_order() -> void:
	turn_order_queue.sort_custom(func(a: int, b: int) -> bool:
		return _next_turn_times[a] < _next_turn_times[b]
	)

func finish_turn(unit: Unit) -> String:
	if unit == null:
		return ""
	var id: String = unit.resource.id

	if not unit.is_alive:
		remove_from_turn_order(id)
		_next_turn_times.erase(id)
	else:
		_next_turn_times[id] += _compute_turn_cost(unit.resource.speed)

		# Ensure ID is still in the queue (e.g. if re-added after revival)
		if not turn_order_queue.has(id):
			turn_order_queue.append(id)

	if not turn_order_queue.is_empty():
		_sort_turn_order()
	
	var prev : String = turn_order_queue.front()
	var next_id: String = turn_order_queue.pop_front()

	# Advance global battle time to this unit's time
	if _next_turn_times.has(next_id):
		battle_time = _next_turn_times[next_id]

	emit_signal("turn_advanced", prev, next_id)
	return next_id

func remove_from_turn_order(id: String) -> void:
	var idx := turn_order_queue.find(id)
	if idx != -1:
		turn_order_queue.remove_at(idx)
	_next_turn_times.erase(id)
