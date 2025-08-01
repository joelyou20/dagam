extends Resource
class_name ItemResource

@export var id: String
@export var name: String
@export var description: String
@export var icon: Texture2D
@export var stackable: bool = false
@export var max_stack: int = 1
@export var item_type: ItemData.ItemType
@export var effect_script: Script 
