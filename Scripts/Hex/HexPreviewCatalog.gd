class_name HexPreviewCatalog
extends RefCounted
## Read-only authored cards, deliberately separate from the native playable table.

static func cards() -> Array:
	var source = JSON.parse_string(
		FileAccess.get_file_as_string("res://Resources/Hex/Data/foundations.json")
	)

	return source.get("cards", []).duplicate(true) if source is Dictionary else []
