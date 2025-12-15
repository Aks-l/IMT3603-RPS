extends Control

signal card_clicked(hand: HandData)

@onready var container: HBoxContainer = $HBoxContainer
const HAND_SCENE: PackedScene = preload("res://scenes/battleUI/hand_card.tscn")

const CARD_SIZE  := Vector2(160, 220)   # all cards same size
const IMAGE_SIZE := Vector2(144, 144)   # square art inside

var _inventory: Dictionary[HandData, int] = {}

var _in_battle = false

func set_inventory(hand_list: Dictionary[HandData, int]) -> void:
	print("set_inventory called with", hand_list.size(), "hands")
	for c in container.get_children():
		c.queue_free()

	_inventory = hand_list.duplicate(true)
	_refresh_ui()
		
func _refresh_ui() -> void:
	for c in container.get_children():
		c.queue_free()

	for hand in _inventory.keys():
		var count = _inventory[hand]
		if count <= 0:
			continue

		var card := HAND_SCENE.instantiate()
		container.add_child(card)
		card.setup(hand, count)
		card.clicked.connect(func(_h): _on_card_clicked(hand))

		print("[HandInventory] Added card:", hand.name, "x", count)


func _on_card_clicked(hand: HandData) -> void:
	if _in_battle:
		print("Cannot play card while in battle")
		return
	lock_battle()
	print("HandInventory caught click:", hand.name)
	
	if not _inventory.has(hand):
		return
		
	_inventory[hand] -= 1
	if _inventory[hand] <= 0:
		_inventory.erase(hand)
	
	_refresh_ui()
	card_clicked.emit(hand)


		### WHAT HAPPENS WHEN CARD IN INVENTORY IS CLICKED
		#card.clicked.connect(func(h): card_clicked.emit(h))

func update_visuals_for(hand: HandData) -> void:
	for card_node in container.get_children():
		if card_node.hand.id == hand.id:
			card_node._update_visuals()

func lock_battle():
	_in_battle = true

func unlock_battle():
	_in_battle = false
