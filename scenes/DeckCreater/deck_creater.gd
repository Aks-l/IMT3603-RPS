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


#data struckture
var _owned_counts : Dictionary = {}
var _deck_list : Array = []

func _ready() -> void:
	search_box.text_changed.connect(_on_search_changed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	cam.make_current()
	
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
	for hand: HandData in inv.keys():
		var count_v = inv.get(hand, 0)
		var count := int(count_v) if typeof(count_v) in [TYPE_INT, TYPE_FLOAT] else 0
		_owned_counts[hand.name] = {
			"data": hand,
			"count": count
		}
	_deck_list.clear()
	_refresh_stock_ui()
	_refresh_deck_view()


#stock ui
func _refresh_stock_ui() -> void:
	for c in stock_list.get_children():
		c.queue_free()
	
	var filter_text = search_box.text.strip_edges().to_lower()
	for hand_name in _owned_counts.keys():
		var entry: Dictionary = _owned_counts[hand_name]
		var count: int = int(entry.get("count", 0))
		if count <= 0:
			continue
		if filter_text != "" and not hand_name.to_lower().contains(filter_text):
			continue
		#create a hand card instance showing how many the plauer onws
		var card = HAND_SCENE.instantiate()
		stock_list.add_child(card)
		print("ADDED:", card, " → parent:", card.get_parent().get_path())
		card.setup(entry["data"], count)
		#bind handler check what was cliked
		card.clicked.connect(Callable(self, "_on_stock_card_clicked"))
		#can be found if needed
		card.set_meta("hand_name", hand_name)

#deck ui
func _refresh_deck_view() -> void:
	
	for c in deck_row.get_children():
		c.queue_free()
	
	if _deck_list.is_empty():
		var lbl = Label.new()
		lbl.text = "Deck empty (max %d cards, %d types)" % [MAX_TOTAL, MAX_UNIQUE_TYPES]
		deck_row.add_child(lbl)
		return

		
	for i in range(_deck_list.size()):
		var idx := i
		
		# wrapper so we can add move buttons
		var slot := HBoxContainer.new()
		slot.alignment = BoxContainer.ALIGNMENT_CENTER
		deck_row.add_child(slot)
		
		var card := HAND_SCENE.instantiate()
		slot.add_child(card)
		card.setup(_deck_list[i], 1) # in the deck, we show each copy individually
		card.clicked.connect(func(_hand: HandData) -> void:
			_on_deck_card_clicked_at_index(idx))
		
		var btnL := Button.new()
		btnL.text = "<--"
		btnL.tooltip_text = "Move left"
		btnL.focus_mode = Control.FOCUS_NONE
		btnL.pressed.connect(func() -> void: _move_card_left(idx))
		slot.add_child(btnL)

		var btnR := Button.new()
		btnR.text = "-->"
		btnR.tooltip_text = "Move right"
		btnR.focus_mode = Control.FOCUS_NONE
		btnR.pressed.connect(func() -> void: _move_card_right(idx))
		slot.add_child(btnR)
	
#	#group by name
#	var grouped := {}
#	for h in _deck_list:
#		if h.name in grouped:
#			grouped[h.name].count += 1
#		else:
#			grouped[h.name] = {"data": h, "count": 1}
	#render grouped cards left to right
#	for hand_name in grouped.keys():
#		var entry = grouped[name]
#		var card = HAND_SCENE.instantiate()
#		deck_row.add_child(card)
#		card.setup(entry["data"], entry["count"])
#		card.clicked.connect(Callable(self, "_on_deck_card_clicked").bind(name))

#stock clicked
func _on_stock_card_clicked(hand: HandData) -> void:
	print("[DEBUG] Clicked on stock card:", hand.name)
	if not _can_add_to_deck(hand):
		_show_status("Cannot add %s: would exceed deck limits( max %d total, max %d types)" % [hand.name, MAX_TOTAL, MAX_UNIQUE_TYPES])
		return
	print("[DEBUG] Before add:", _deck_list.size())
	_deck_list.append(hand)
	print("[DEBUG] After add:", _deck_list.size())
	if hand.name in _owned_counts:
		_owned_counts[hand.name]["count"] -= 1
	_refresh_stock_ui()
	_refresh_deck_view()

func _on_deck_card_clicked_at_index(index: int) -> void:
	if index < 0 or index >= _deck_list.size():
		return
	var removed: HandData = _deck_list.pop_at(index)
	var name := removed.name
	if name in _owned_counts:
		_owned_counts[name]["count"] += 1
	else:
		_owned_counts[name] = {"data": removed, "count": 1}
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

#confirm/cancel
func _on_confirm_pressed() -> void:
	var final_deck := _deck_list.duplicate(true)
	Globals.current_deck = final_deck
	deck_confirmed.emit(final_deck)
	print("Deck confirmed with %d cards" % final_deck.size())
	queue_free()

func _on_cancel_pressed() -> void:
	print("Returning to map without changes")
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
