extends Control
class_name StatBar

signal value_changed(value: float, max_value: float)

# --- Backing fields ---
var _min_value: float = 0.0
var _max_value: float = 100.0
var _value: float = 100.0

# --- Core values (export wrappers) ---
@export var min_value: float = 0.0:
	set(v):
		_min_value = v
		_reclamp_and_refresh()
	get:
		return _min_value

@export var max_value: float = 100.0:
	set(v):
		_max_value = maxf(v, 0.0001) # avoid div by zero
		_reclamp_and_refresh()
	get:
		return _max_value

@export var value: float = 100.0:
	set(v):
		_set_value_internal(v)
	get:
		return _value

# --- Behavior ---
@export var smooth: bool = true
@export var tween_time: float = 0.15
@export var chip_enabled: bool = false
@export var chip_delay: float = 0.15
@export var vertical: bool = false              # false = horizontal
@export var auto_hide_when_full: bool = false   # hide when ratio==1

# --- Appearance ---
@export var bar_size: Vector2 = Vector2(120, 12):
	set(v):
		bar_size = v
		_layout_now()
@export var color_fill: Color = Color(0.15, 0.8, 0.25)
@export var color_back: Color = Color(0, 0, 0, 0.5)
@export var color_chip: Color = Color(0.9, 0.2, 0.2)
@export var round_radius: int = 3  # (not used by ColorRect natively; keep for future)

# Each: {"t": 0.3, "color": Color(1,0.2,0.2)} -> when ratio <= t, use color
@export var color_thresholds: Array[Dictionary] = []

# Label
@export var show_label: bool = false
@export var label_format: String = "{value}/{max}"  # or "{percent}%"

# Internals
var _fill_tween: Tween
var _chip_tween: Tween
var _chip_timer: SceneTreeTimer
var _chip_request_id: int = 0  # to invalidate stale timer callbacks

@onready var _back: ColorRect = $Back
@onready var _fill: ColorRect = $Fill
@onready var _chip: ColorRect = $Chip
@onready var _label: Label = $Label

# ---------- Lifecycle ----------
func _ready():
	_back.color = color_back
	_fill.color = color_fill
	_chip.color = color_chip
	_chip.visible = chip_enabled
	size = bar_size
	_layout_now()
	_refresh_all(true)

# ---------- Public API ----------
func set_values(current: float, max_val: float) -> void:
	_max_value = maxf(max_val, 0.0001) # avoid div by zero
	_set_value_internal(current)       # clamps + refreshes

func _update_bar() -> void:
	if max_value <= 0:
		_fill.size.x = 0
		return

	var ratio := value / max_value
	# Use the BACKGROUND rect (or the container width) as the full width
	var full_width := _back.size.x
	_fill.size.x = full_width * ratio

func set_colors(fill: Color, back: Color = color_back, chip: Color = color_chip) -> void:
	color_fill = fill
	color_back = back
	color_chip = chip
	_back.color = color_back
	_fill.color = color_fill
	_chip.color = color_chip
	_refresh_all(true)

func set_vertical(is_vertical: bool) -> void:
	vertical = is_vertical
	_refresh_all(true)

func set_label_visible(v: bool) -> void:
	show_label = v
	_label.visible = v
	if v:
		_update_label()

func set_label_format(fmt: String) -> void:
	label_format = fmt
	_update_label()

# ---------- Private: value mgmt ----------
func _reclamp_and_refresh():
	var clamped = clampf(_value, _min_value, _max_value)
	if not is_equal_approx(clamped, _value):
		_value = clamped
	_refresh_all(true)

func _set_value_internal(v: float):
	var clamped = clampf(v, _min_value, _max_value)
	if is_equal_approx(clamped, _value):
		return
	_value = clamped
	_refresh_all()
	emit_signal("value_changed", _value, _max_value)

# ---------- Layout / Drawing ----------
func _layout_now():
	size = bar_size
	_back.position = Vector2.ZERO
	_back.size = size
	_chip.position = Vector2.ZERO
	_chip.size = size
	_fill.position = Vector2.ZERO
	_fill.size = size
	_label.visible = show_label
	_label.size = size      # use actual control width
	_label.position = Vector2.ZERO
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _refresh_all(immediate: bool = false):
	var r = _ratio()
	_apply_color_thresholds(r)
	_update_label()

	if auto_hide_when_full:
		visible = not is_equal_approx(r, 1.0)

	# Animate the main fill
	var target_size = _target_fill_size(r)
	if immediate or not smooth:
		_fill.size = target_size
	else:
		_tween_to_fill(_fill, "size", target_size, tween_time)

	# Chip effect
	if chip_enabled:
		_chip.visible = true
		var denom = maxf(1.0, bar_size.y) if vertical else maxf(1.0, bar_size.x)
		var current_chip_ratio = (_chip.size.y / denom) if vertical else (_chip.size.x / denom)

		if r < current_chip_ratio:
			# damage: chip lags behind after delay
			_chip_request_id += 1
			var req_id = _chip_request_id
			_chip_timer = get_tree().create_timer(chip_delay)
			_chip_timer.timeout.connect(func():
				# ignore if a newer request has been made
				if req_id == _chip_request_id:
					_animate_chip(r)
			)
		else:
			# heal: snap chip immediately up to new size
			_chip.size = _target_fill_size(r)
	else:
		_chip.visible = false

# ---------- Helpers ----------
func _ratio() -> float:
	return clampf((_value - _min_value) / (_max_value - _min_value), 0.0, 1.0)

func _target_fill_size(r: float) -> Vector2:
	var w = size.x   # actual control width assigned by container
	var h = size.y
	return Vector2(w * r, h) if vertical == false else Vector2(w, h * r)

func _update_label():
	if not show_label:
		return
	var percent = int(round(_ratio() * 100.0))
	var txt = label_format
	txt = txt.replace("{value}", str(int(round(_value))))
	txt = txt.replace("{max}", str(int(round(_max_value))))
	txt = txt.replace("{percent}", str(percent))
	_label.text = txt

func _apply_color_thresholds(r: float):
	var chosen: Color = color_fill
	var best_t: float = 2.0
	for entry in color_thresholds:
		if not entry.has("t") or not entry.has("color"):
			continue
		var t = float(entry["t"])
		if r <= t and t < best_t:
			best_t = t
			chosen = entry["color"]
	_fill.color = chosen

func _animate_chip(r: float):
	var target = _target_fill_size(r)
	_tween_to_chip(_chip, "size", target, tween_time)

# Separate tweens so chip anim doesn’t cancel fill anim (and vice versa)
func _tween_to_fill(obj: Object, prop, val, duration: float):
	if _fill_tween and _fill_tween.is_running():
		_fill_tween.kill()
	_fill_tween = create_tween()
	_fill_tween.tween_property(obj, NodePath(str(prop)), val, duration)

func _tween_to_chip(obj: Object, prop, val, duration: float):
	if _chip_tween and _chip_tween.is_running():
		_chip_tween.kill()
	_chip_tween = create_tween()
	_chip_tween.tween_property(obj, NodePath(str(prop)), val, duration)
