extends Control

signal card_clicked(hand: HandData)

@onready var container: HBoxContainer = $HBoxContainer
const HAND_SCENE: PackedScene = preload("res://scenes/battleUI/hand_card.tscn")

const CARD_SIZE  := Vector2(160, 220)   # all cards same size
const IMAGE_SIZE := Vector2(144, 144)   # square art inside

func set_inventory(hand_list: Array[HandData]) -> void:
	print("set_inventory called with", hand_list.size(), "hands")
	for c in container.get_children():
		c.queue_free()

	for hand in hand_list:
		var card := HAND_SCENE.instantiate()
		container.add_child(card)
		card.setup(hand)
		card.clicked.connect(_on_card_clicked)
		print("Added card to container:", hand.name, "Conteiner children:", container.get_child_count())

func _on_card_clicked(hand: HandData) -> void:
	print("HandInventory caught click:", hand.name)
	card_clicked.emit(hand)

		### WHAT HAPPENS WHEN CARD IN INVENTORY IS CLICKED
		#card.clicked.connect(func(h): card_clicked.emit(h))
