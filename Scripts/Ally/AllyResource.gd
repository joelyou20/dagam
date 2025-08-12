# AllyResource.gd
extends EntityResource
class_name AllyResource

@export var portrait_texture: Texture2D

# Experience/Levels
@export var experience: int = 0
@export var xp_to_next_level: int = 100
@export var xp_growth_rate: float = 1.2  # How much XP requirement grows per level

@export var head_equipment: EquipmentResource
@export var chest_equipment: EquipmentResource
@export var back_equipment: EquipmentResource
@export var feet_equipment: EquipmentResource
@export var hands_equipment: EquipmentResource
@export var main_weapon_equipment: EquipmentResource
@export var offhand_weapon_equipment: EquipmentResource
