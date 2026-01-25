extends Resource
class_name CardRarity

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

static func get_rarity_name(rarity: Rarity) -> String:
	match rarity:
		Rarity.COMMON:
			return "Common"
		Rarity.UNCOMMON:
			return "Uncommon"
		Rarity.RARE:
			return "Rare"
		Rarity.EPIC:
			return "Epic"
		Rarity.LEGENDARY:
			return "Legendary"
		_:
			return "Unknown"

static func get_rarity_color(rarity: Rarity) -> Color:
	match rarity:
		Rarity.COMMON:
			return Color(0.7, 0.7, 0.7)  # Gray
		Rarity.UNCOMMON:
			return Color(0.2, 0.8, 0.2)  # Green
		Rarity.RARE:
			return Color(0.2, 0.4, 0.9)  # Blue
		Rarity.EPIC:
			return Color(0.7, 0.2, 0.8)  # Purple
		Rarity.LEGENDARY:
			return Color(0.9, 0.6, 0.1)  # Gold
		_:
			return Color.WHITE
