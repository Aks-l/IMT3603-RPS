extends Control

signal card_clicked(hand: HandData)

@onready var container: HBoxContainer = $HBoxContainer
const HAND_SCENE: PackedScene = preload("res://scenes/battleUI/hand_card.tscn")

const CARD_SIZE  := Vector2(160, 220)   # all cards same size
const IMAGE_SIZE := Vector2(144, 144)   # square art inside

func set_inventory(hand_list: Dictionary[HandData, int]) -> void:
	print("set_inventory called with", hand_list.size(), "hands")
	for c in container.get_children():
		c.queue_free()
	
	#group by card name
	var grouped := {}
	for hand in hand_list:
		if hand.name in grouped:
			grouped[hand.name].count += 1
		else:
			grouped[hand.name] = {
				"data": hand,
				"count": 1
		}
	#create on card per group
	for key in grouped.keys():
		var entry = grouped[key]
		var card := HAND_SCENE.instantiate()
		container.add_child(card)
		card.setup(entry.data, entry.count)
		
	#	var card := HAND_SCENE.instantiate()
	#	container.add_child(card)
	#	card.setup(hand, hand.max_count)
		card.clicked.connect(_on_card_clicked)
		print("Added card to container:", entry.data.name, "x ", entry.count)

func _on_card_clicked(hand: HandData) -> void:
	print("HandInventory caught click:", hand.name)
	card_clicked.emit(hand)

		### WHAT HAPPENS WHEN CARD IN INVENTORY IS CLICKED
		#card.clicked.connect(func(h): card_clicked.emit(h))
