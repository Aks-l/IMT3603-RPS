extends Control

@onready var container: HBoxContainer = $HBoxContainer
const HAND_SCENE: PackedScene = preload("res://scenes/battleUI/hand_card.tscn")

const CARD_SIZE  := Vector2(160, 220)   # all cards same size
const IMAGE_SIZE := Vector2(144, 144)   # square art inside

func set_inventory(hand_list: Array[HandData]) -> void:
	for c in container.get_children():
		c.queue_free()

	for hand in hand_list:
		var card := HAND_SCENE.instantiate() as Control
		card.custom_minimum_size = CARD_SIZE
		card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
		container.add_child(card)

		var img := card.get_node("VBoxContainer/Image") as TextureRect
		img.texture = hand.sprite
		img.custom_minimum_size = IMAGE_SIZE
		img.size_flags_horizontal = Control.SIZE_FILL
		img.size_flags_vertical   = Control.SIZE_FILL
		# important: let it scale down to the rect instead of keeping source pixels
		img.ignore_texture_size = true                 # (Godot 4)
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# (Godot 3: use `img.expand = true` + a KEEP_* stretch mode)
