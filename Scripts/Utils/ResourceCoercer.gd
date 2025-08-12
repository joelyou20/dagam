# ResUtil.gd
extends Node
class_name ResUtil

static func _is_of_class(obj: Object, expected: StringName) -> bool:
	if obj == null:
		return false

	if ClassDB.class_exists(expected) and ClassDB.is_parent_class(obj.get_class(), expected):
		return true

	if obj is Resource:
		var scr : Script = (obj as Resource).get_script()
		if scr and scr.has_method("get_global_name"):
			return scr.get_global_name() == String(expected)

	return false

static func coerce_resource(raw, expected_class: StringName, path_keys: Array = ["resource_path", "item_path", "path"]) -> Resource:
	if raw == null:
		return null

	if raw is Resource and _is_of_class(raw, expected_class):
		return raw

	if raw is String and raw != "":
		var r := load(raw)
		return r if _is_of_class(r, expected_class) else null

	if raw is Dictionary:
		for k in path_keys:
			if raw.has(k):
				var p : String = raw[k]
				if typeof(p) == TYPE_STRING and p != "":
					var r := load(p)
					return r if _is_of_class(r, expected_class) else null

	return null

static func coerce_array(raw: Array, expected_class: StringName, path_keys: Array = ["resource_path", "item_path", "path"]) -> Array:
	var out: Array = []
	for v in raw:
		var r := coerce_resource(v, expected_class, path_keys)
		if r != null:
			out.append(r)
	return out

static func to_item_array(raw: Array) -> Array[ItemResource]:
	var out: Array[ItemResource] = []
	for v in raw:
		var r := coerce_resource(v, &"ItemResource")
		if r:
			out.append(r as ItemResource)
	return out

static func to_equipment(raw) -> EquipmentResource:
	return coerce_resource(raw, &"EquipmentResource") as EquipmentResource

static func to_equipment_array(raw: Array) -> Array[EquipmentResource]:
	var out: Array[EquipmentResource] = []
	for v in raw:
		var r := coerce_resource(v, &"EquipmentResource")
		if r:
			out.append(r as EquipmentResource)
	return out

static func resources_to_path_array(items: Array) -> Array:
	var arr: Array = []
	for it in items:
		if it is Resource:
			arr.append(it.resource_path)
	return arr

static func resource_to_path_or_empty(res: Resource) -> String:
	return res.resource_path if res else ""
