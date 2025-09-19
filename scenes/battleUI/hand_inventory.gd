extends Control

signal card_clicked(hand: HandData)

@onready var container: HBoxContainer = $HBoxContainer
const HAND_SCENE: PackedScene = preload("res://scenes/battleUI/hand_card.tscn")

const CARD_SIZE  := Vector2(160, 220)   # all cards same size
const IMAGE_SIZE := Vector2(144, 144)   # square art inside

func set_inventory(hand_list: Array[HandData]) -> void:
	for c in container.get_children():
		c.queue_free()

	for hand in hand_list:
		var card := HAND_SCENE.instantiate()
		container.add_child(card)
		card.setup(hand)

		### WHAT HAPPENS WHEN CARD IN INVENTORY IS CLICKED
		card.clicked.connect(func(h): card_clicked.emit(h))
