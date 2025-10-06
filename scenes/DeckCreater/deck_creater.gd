extends Control

signal deck_confirmed(deck: Array[HandData])
 #emits finalized deck as array

const HAND_SCENE: PackedScene = preload("res://scenes/battleUI/hand_card.tscn")

const MAX_TOTAL := 15
const MAX_UNIQUE_TYPES := 5

#ui node path
@onready var title_label := $"MarginContainer/HBoxContainer/ChosenCards/YourDeck"
@onready var deck_row := $"MarginContainer/HBoxContainer/ChosenCards/DeckRow"
@onready var search_box := $"MarginContainer/HBoxContainer/StockCards/Search"
@onready var stock_scroll := $"MarginContainer/HBoxContainer/StockCards/StockScroll"
@onready var stock_list := $"MarginContainer/HBoxContainer/StockCards/StockScroll/StockList"
@onready var confirm_button := $"MarginContainer/HBoxContainer2/ConfirmDeck"
@onready var cancel_button := $"MarginContainer/HBoxContainer2/Cancel"

@onready var cam := $Cam


#data structure
var _owned_counts : Dictionary = {}
var _deck_list : Array = []
var _original_deck : Dictionary = {}

func _ready() -> void:
	search_box.text_changed.connect(_on_search_changed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	cam.make_current()
	
	#load previously confirmed deck into working emory
	_original_deck = Globals.get_current_deck().duplicate(true)
	
	if Globals.inventory.size() > 0:
		set_owned_hands(Globals.inventory)
	else: 
		print("[DeckCreator] warning: player invetory empty")
	
	#DEBUG
	print("DECK CREATOR SCENE LOADED CORRECTCTLY")
	
	assert(stock_list and stock_list.get_parent() is ScrollContainer, 
		"StockList must be a direct child of ScrollContainer")
	
	# Make the search bar keep visible height
	search_box.custom_minimum_size.y = 36
	search_box.size_flags_vertical = Control.SIZE_FILL
	search_box.size_flags_horizontal = Control.SIZE_FILL
	# Let the scroll area take the leftover space
	stock_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stock_scroll.size_flags_horizontal = Control.SIZE_FILL
	# StockList should not force expansion beyond content
	stock_list.size_flags_vertical = Control.SIZE_FILL
	stock_list.size_flags_horizontal = Control.SIZE_FILL


#call with palyers oend hands
func set_owned_hands(inv: Dictionary) -> void:
	_owned_counts.clear()

	# Start from the player’s global inventory
	for hand: HandData in inv.keys():
		var total_count: int = inv[hand]
		var deck_count: int = 0

		# If this hand is already in the saved deck, remove that many from stock
		for d: HandData in Globals.get_current_deck().keys():
			if d == hand:
				deck_count = Globals.get_current_deck()[d]
				break

		var remaining: int = max(0, total_count - deck_count)

		_owned_counts[hand.name] = {
			"data": hand,
			"count": remaining
		}

	# Rebuild working deck list from saved deck
	_deck_list.clear()
	for hand: HandData in Globals.get_current_deck().keys():
		var count: int = Globals.get_current_deck()[hand]
		for i in range(count):
			_deck_list.append(hand)

	_refresh_stock_ui()
	_refresh_deck_view()




#stock ui
func _refresh_stock_ui() -> void:
	for c in stock_list.get_children():
		c.call_deferred("free")  # immediately remove

	var filter_text = search_box.text.strip_edges().to_lower()
	for hand_name in _owned_counts.keys():
		var entry: Dictionary = _owned_counts[hand_name]
		var count: int = int(entry.get("count", 0))
		if count <= 0:
			continue
		if filter_text != "" and not hand_name.to_lower().contains(filter_text):
			continue
		var card = HAND_SCENE.instantiate()
		stock_list.add_child(card)
		card.setup(entry["data"], count)
		card.clicked.connect(_on_stock_card_clicked)


#deck ui
func _refresh_deck_view() -> void:
	for c in deck_row.get_children():
		c.queue_free()

	if _deck_list.is_empty():
		var lbl = Label.new()
		lbl.text = "Deck empty (max %d cards, %d types)" % [MAX_TOTAL, MAX_UNIQUE_TYPES]
		deck_row.add_child(lbl)
		return

	# Group cards by name
	var grouped := {}
	for h in _deck_list:
		if h.name in grouped:
			grouped[h.name]["count"] += 1
		else:
			grouped[h.name] = {"data": h, "count": 1}

	# Display each group as one stacked card (e.g. “Rock ×3”)
	for hand_name in grouped.keys():
		var entry = grouped[hand_name]
		var card = HAND_SCENE.instantiate()
		deck_row.add_child(card)
		card.setup(entry["data"], entry["count"])

		# When clicked, remove one of that card type
		card.clicked.connect(func(_hand: HandData):
			_remove_one_from_deck(hand_name)
		)

func _remove_one_from_deck(hand_name: String) -> void:
	for i in range(_deck_list.size()):
		if _deck_list[i].name == hand_name:
			var removed: HandData = _deck_list.pop_at(i)
			if hand_name in _owned_counts:
				_owned_counts[hand_name]["count"] += 1
			else:
				_owned_counts[hand_name] = {"data": removed, "count": 1}
			break

	_refresh_stock_ui()
	_refresh_deck_view()


func _on_deck_card_clicked(hand_name: String) -> void:
	for i in range(_deck_list.size()):
		if _deck_list[i].name == hand_name:
			var removed: HandData = _deck_list.pop_at(i)
			if hand_name in _owned_counts:
				_owned_counts[hand_name]["count"] += 1
			else:
				_owned_counts[hand_name] = {"data": removed, "count": 1}
			break
	_refresh_stock_ui()
	_refresh_deck_view()


#stock clicked
func _on_stock_card_clicked(hand: HandData) -> void:
	if not _can_add_to_deck(hand):
		_show_status("Cannot add %s: would exceed deck limits" % hand.name)
		return

	_deck_list.append(hand)

	# Subtract from inventory
	if hand.name in _owned_counts:
		_owned_counts[hand.name]["count"] -= 1
		if _owned_counts[hand.name]["count"] < 0:
			_owned_counts[hand.name]["count"] = 0

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
func _on_search_changed(_new_text: String) -> void:
	_refresh_stock_ui()

# Returns the deck as a dictionary grouped by card name (and accessible by ID)
func get_deck_dictionary() -> Dictionary:
	var deck_dict := {}
	for h in _deck_list:
		if h.id in deck_dict:
			deck_dict[h.id]["count"] += 1
		else:
			deck_dict[h.id] = {
				"data": h,
				"count": 1
			}
	return deck_dict


#confirm/cancel
func _on_confirm_pressed() -> void:
	var final_deck := get_deck_dictionary()
	
	var deck_for_globals: Dictionary[HandData, int] = {}
	for entry in final_deck.values():
		var hand: HandData = entry["data"]
		var count: int = entry["count"]
		deck_for_globals[hand] = count
		
	Globals.set_current_deck(deck_for_globals)
	deck_confirmed.emit(deck_for_globals)
	print("[DeckCreator] Deck confirmed with %d unique cards" % deck_for_globals.size())
	queue_free()


func _on_cancel_pressed() -> void:
	print("Returning to map without changes")
	var current := get_deck_dictionary()
	var saved := Globals.get_current_deck()
	var diff := get_deck_difference(current, saved)
	
	if diff.is_empty():
		print("no changs made - return to menu")
	else:
		print("unsaved chagned detected:", diff)
	queue_free()

# Returns a dictionary of cards that differ between two decks
func get_deck_difference(full: Dictionary, subset: Dictionary) -> Dictionary:
	var diff := {}
	for k in full.keys():
		var amount: int = int(full.get(k, 0)) - int(subset.get(k, 0))
		if amount > 0:
			diff[k] = amount
	return diff


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
