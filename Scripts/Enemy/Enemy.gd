extends Area3D
class_name Enemy

@export var encounter: EncounterData
@export var id: String

var active := true
var fled_reactivate_cooldown: float = 100.0

func _ready():
	if id.is_empty():
		# Generate an ID if not set manually
		id = str(Engine.get_physics_frames()) + "_" + name
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node):
	if not active:
		return
	if body.is_in_group("Player"):
		InteractionHandler.block("Enemy")
		call_deferred("_start_battle")

func _start_battle():
	EnemyManager.start_battle_from_enemy(self)
