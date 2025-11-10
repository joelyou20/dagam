extends Node
class_name AllyBattleInfo

@onready var portrait: TextureRect = $GridContainer/HBoxContainer/PortraitTextureRect
@onready var member_name: Label = $GridContainer/HBoxContainer/PartyMemberNameLabel
@onready var health_bar: StatBar = $GridContainer/HealthBar
@onready var mana_bar: StatBar = $GridContainer/ManaBar

var _unit: Unit = null

func update_ally_info(unit: Unit):
	if not unit or not unit.resource:
		push_error("Unit is not set")
		return
	
	if not _unit:
		_unit = unit
		_unit.hp_change.connect(_set_hp_stat_bar)
	
	var ally_resource: AllyResource = unit.resource
	portrait.texture = ally_resource.portrait_texture
	member_name.text = ally_resource.name
	health_bar.set_values(ally_resource.current_hp, ally_resource.max_hp)
	mana_bar.set_values(ally_resource.current_hp, ally_resource.max_hp)
	
func _set_hp_stat_bar(amount: int):
	health_bar.set_values(health_bar.value - amount, _unit.resource.max_hp)
