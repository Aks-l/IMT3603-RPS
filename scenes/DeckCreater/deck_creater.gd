extends Node2D

signal deck_confirmed(deck : Array) #emits finalized deck as array

const HAND_SCENE: PackedScene = preload("res://scenes/battleUI/hand_card.tscn")

const MAX_TOTAL := 15
const MAX_UNIQUE_TYPES := 5

#ui node path
@onready var title_label := $"MarginContainer/VBoxContainer/YourDeck"
@onready var deck_row := $"MarginContainer/VBoxContainer/DeckRow"
@onready var search_box := $"MarginContainer/VBoxContainer/Search"
@onready var stock_scroll := $"MarginContainer/VBoxContainer/StockScoll"
@onready var stock_list := $"MarginContainer/VBoxContainer/StockScoll/StockList"
@onready var confirm_button := $"MarginContainer/VBoxContainer/HBoxContainer2/ConfirmDeck"
@onready var cancel_button := $"MarginContainer/VBoxContainer/HBoxContainer2/Cancel"


#data struckture
var _owned_counts : Dictionary = {}
var _deck_list : Array = []

func _ready() -> void:
	search_box.text_changed.connect(_on_search_changed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

#call with palyers oend hands
func set_owned_hands(hands: Array[HandData]) -> void:
	#build counts grouped by name
	_owned_counts.clear()
	for h in hands:
		if h.name in _owned_counts:
			_owned_counts[h.name].count += 1
		else:
			_owned_counts[h.name] = {"data": h, "count": 1}
	_deck_list.clear()
	_refresh_stock_ui()
	_refresh_deck_view()

#stock ui
func _refresh_stock_ui() -> void:
	stock_list.clear_children()
	var filter_text = search_box.text.strip_edges().to_lower()
	for name in _owned_counts.keys():
		var entry = _owned_counts[name]
		var count = entry.count
		if count <= 0:
			continue
		if filter_text != "" and not name.to_lower().findn(filter_text) >= 0:
			continue
		#create a hand card instance showing how many the plauer onws
		var card = HAND_SCENE.instantiate()
		stock_list.add_child(card)
		card.setup(entry.data, count)
		#bind handler check what was cliked
		card.clicked.connect(Callable(self, "_on_stock_card_clicked").bind(entry.data))
		#can be found if needed
		card.set_meta("hand_name", name)

#deck ui
func _refresh_deck_view() -> void:
	deck_row.clear_children()
	if _deck_list.is_empty():
		#oputionaru shoou purasehoruderu oru emputii raberu
		var lbl = Label.new()
		lbl.text = "deck empty (max %d cards, %d types)" % [MAX_TOTAL, MAX_UNIQUE_TYPES]
		deck_row.add_child(lbl)
		return
	
	#group by name
	var grouped := {}
	for h in _deck_list:
		if h.name in grouped:
			grouped[h.name].count += 1
		else:
			grouped[h.name] = {"data": h, "count": 1}

	#render grouped cards left to right
	for name in grouped.keys():
		var entry = grouped[name]
		var card = HAND_SCENE.instantiate()
		deck_row.add_child(card)
		card.setup(entry.data, entry.count)
		card.clicked.connect(Callable(self, "_on_deck_card_clicked").bind(name))

#stock clicked
func _on_stock_card_clicked(hand: HandData) -> void:
	if not _can_add_to_deck(hand):
		_show_status("Cannot add %s: would exceed deck limits( max %d total, max %d types)" % [hand.name, MAX_TOTAL, MAX_UNIQUE_TYPES])
		return
	_deck_list.append(hand)
	if hand.name in _owned_counts:
		_owned_counts[hand.name].count -= 1
	_refresh_stock_ui()
	_refresh_deck_view()

#deck clicked
func _on_deck_card_clicked(hand_name: String) -> void:
	var idx = -1
	for i in range(_deck_list.size()):
		if _deck_list[i].name == hand_name:
			idx = i
			break
		if idx == -1:
			push_error("clicked deck card but none found in deck_list: %s" % hand_name)
			return
	
	var removed = _deck_list.pop_at(idx)
	if hand_name in _owned_counts:
		_owned_counts[hand_name].count += 1
	else:
		_owned_counts[hand_name] = {"data": removed, "count": 1}
	
	_refresh_stock_ui()
	_refresh_deck_view()

#rules
func _can_add_to_deck(hand: HandData) -> bool:
	if _deck_list.size() + 1 > MAX_TOTAL:
		return false
	var types := {}
	for h in _deck_list:
		types[h.name] = true
	if not (hand.name in types) and types.size() + 1 > MAX_UNIQUE_TYPES:
		return false
	return true

#søk
func _on_search_changed(new_text: String) -> void:
	_refresh_stock_ui()

#confirm/cancel
func _on_confirm_pressed() -> void:
	var final_deck := _deck_list.duplicate(true)
	emit_signal("deck_confirmed", final_deck)
	queue_free()

func _on_cancel_pressed() -> void:
	queue_free()

#status
func _show_status(text: String) -> void:
	print("[DeckCreator] ", text)

#reorder
func _move_card_left(index: int) -> void:
	if index <= 0 or index >= _deck_list.size():
		return
	var item = _deck_list[index]
	_deck_list.remove_at(index)
	_deck_list.insert(index - 1, item)
	_refresh_deck_view()
	
func _move_card_right(index: int) -> void:
	if index < 0 or index >= _deck_list.size() - 1:
		return
	var item = _deck_list[index]
	_deck_list.remove_at(index)
	_deck_list.insert(index + 1, item)
	_refresh_deck_view()
