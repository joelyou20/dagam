extends Node
class_name TurnOrderItem

@onready var portrait: TextureRect = $Panel/PortraitTextureRect

func set_portrait(texture: Texture2D):
	if texture:
		portrait.texture = texture
