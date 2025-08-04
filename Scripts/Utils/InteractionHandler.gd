extends Node

var _blockers: Dictionary = {}

func block(source: String):
	_blockers[source] = true
	var x = 1

func unblock(source: String):
	_blockers.erase(source)

func is_blocked() -> bool:
	return _blockers.size() > 0
