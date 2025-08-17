extends Node

var _stack: Array[UIBase] = []

func push(ui: UIBase) -> void:
	if _stack.has(ui):
		return
	_stack.append(ui)

func pop(ui: UIBase = null) -> void:
	if _stack.is_empty():
		return
	if ui == null:
		_stack.pop_back()
		return
	# Pop if it's the top, otherwise remove by value
	if _stack.back() == ui:
		_stack.pop_back()
	else:
		_stack.erase(ui)

func top() -> UIBase:
	return _stack.back() if not _stack.is_empty() else null

func has_open_ui() -> bool:
	return not _stack.is_empty()

# Central handler for Escape, if you want to route it globally
func handle_cancel() -> bool:
	if _stack.is_empty():
		return false
	var t : UIBase = _stack.back()
	if t and t.on_cancel():
		return true
	# Fallback: close the top if it didn’t handle cancel
	if t:
		t.hide_ui()
	return true
