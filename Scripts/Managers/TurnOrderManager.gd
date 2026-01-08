extends Node

signal turn_advanced(prev: int, next: int)

var battle_time: float = 0.0

const PLAN_AHEAD := 10

# Just IDs, no Units here
var turn_order_queue: Array[String] = []

var _next_time: Dictionary = {}          # id -> float
var _interval: Dictionary = {}           # id -> float
var _last_picked_step: Dictionary = {}   # id -> int (lower = longer ago)

var _step := 0

func setup(units: Array[Unit]) -> void:
	battle_time = 0.0
	_step = 0
	turn_order_queue.clear()
	_next_time.clear()
	_interval.clear()
	_last_picked_step.clear()

	for u in units:
		var id := u.resource.id
		var spd : int = max(int(u.resource.speed), 1)

		_interval[id] = spd
		_next_time[id] = spd           # first action at its interval
		_last_picked_step[id] = -999999     # never acted -> very old

	_plan_up_to(PLAN_AHEAD)

func finish_turn(unit: Unit) -> String:
	if unit == null:
		return ""

	var finished_id := unit.resource.id

	# If unit died, remove it from future planning
	if not unit.is_alive:
		_remove_unit(finished_id)

	var prev_id := finished_id

	# Pop current (front) if it matches; otherwise just pop front defensively
	if not turn_order_queue.is_empty() and turn_order_queue.front() == finished_id:
		turn_order_queue.pop_front()
	elif not turn_order_queue.is_empty():
		turn_order_queue.pop_front()

	# Keep queue filled
	_plan_up_to(PLAN_AHEAD)

	var next_id : String = turn_order_queue.front() if not turn_order_queue.is_empty() else ""

	if next_id != "" and _next_time.has(next_id):
		battle_time = float(_next_time[next_id])

	emit_signal("turn_advanced", prev_id, next_id)
	return next_id

func _plan_up_to(count: int) -> void:
	while turn_order_queue.size() < count and _next_time.size() > 0:
		var id := _pick_next_id()
		if id == "":
			break

		turn_order_queue.append(id)

		# schedule this unit's next time
		_next_time[id] = float(_next_time[id]) + float(_interval[id])

		# record recency for tie-breaks
		_last_picked_step[id] = _step
		_step += 1

func _pick_next_id() -> String:
	var best_id := ""
	var best_time := INF
	var best_last := INF  # for tie-break: smaller last = longer ago, so we prefer smaller last

	for id in _next_time.keys():
		var t := float(_next_time[id])
		var last := int(_last_picked_step.get(id, -999999))

		if t < best_time:
			best_time = t
			best_last = last
			best_id = id
		elif is_equal_approx(t, best_time):
			# Tie-break: whoever acted least recently (smaller last step)
			if last < best_last:
				best_last = last
				best_id = id

	return best_id

func _remove_unit(id: String) -> void:
	_next_time.erase(id)
	_interval.erase(id)
	_last_picked_step.erase(id)

	# remove all future occurrences from the planned queue
	while true:
		var idx := turn_order_queue.find(id)
		if idx == -1:
			break
		turn_order_queue.remove_at(idx)
