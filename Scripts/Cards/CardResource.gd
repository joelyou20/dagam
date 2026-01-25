extends Resource
class_name CardResource

# Basic Card Information
@export var id: String
@export var name: String
@export var description: String
@export var card_image: Texture2D
@export var rarity: CardRarity.Rarity = CardRarity.Rarity.COMMON

# Card Type - determines how the card can be used
enum CardType {
	CREATURE,      # Summonable creatures
	SPELL,         # One-time effects
	EQUIPMENT,     # Persistent effects/equipment
	TERRAIN        # Field effects
}
@export var card_type: CardType = CardType.CREATURE

# Card Cost - elemental resources needed to play
enum Element {
	WATER,
	FIRE,
	EARTH,
	AIR
}
@export var water_cost: int = 0
@export var fire_cost: int = 0
@export var earth_cost: int = 0
@export var air_cost: int = 0

# Card Information (for UI display)
@export var tags: Array[String] = []  # Card tags
@export var card_set: String = ""  # Card set name (renamed from "set" to avoid shadowing base class)
@export var ability: String = ""  # Card ability/effect description
@export var strength: int = 0  # Card strength/power (typically attack for creatures)
@export var scene_path: String = "res://Scenes/Cards/TestAttackCard.tscn"  # Path to the card scene for instantiation

# Capture Information - if this card was captured from something
@export var captured_from_id: String = ""  # ID of the entity/object this was captured from
@export var capture_date: String = ""  # When this card was captured

# Card Level/Experience (for progression)
@export var level: int = 1
@export var experience: int = 0
@export var experience_to_next_level: int = 100

# Card Abilities/Skills
@export var abilities: Array[String] = []  # List of ability IDs or names

func _init():
	if id.is_empty():
		id = name.to_lower().replace(" ", "_")
