extends CanvasLayer

signal deck_confirmed(deck: Dictionary) # now matches the emitted value

const HAND_SCENE: PackedScene = preload("res://scenes/battleUI/hand_card.tscn")

# ui node path
@onready var title_label := %YourDeck
@onready var deck_row := %DeckRow
@onready var search_box := %Search
@onready var stock_scroll := %StockScroll
@onready var stock_list := %StockList
@onready var confirm_button := %ConfirmDeck
@onready var cancel_button := %Cancel

@onready var cam := $Control/Cam

@onready var total_label = %Total
@onready var separate_label = %Separate

# data structure
var _inventory: Dictionary = {}         # HandData -> total copies owned
var _deck: Dictionary = {}              # HandData -> copies in current deck


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	search_box.text_changed.connect(_on_search_changed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	cam.make_current()
	hide()

	# load previously confirmed deck into working memory
	var current_deck: Dictionary = Globals.get_current_deck()
	_deck = current_deck.duplicate(true)

	if Globals.inventory.size() > 0:
		set_owned_hands(Globals.inventory)
	else:
		print("[DeckCreator] warning: player inventory empty")

	print("DECK CREATOR SCENE LOADED CORRECTLY")

	assert(
		stock_list and stock_list.get_parent() is ScrollContainer,
		"StockList must be a direct child of ScrollContainer"
	)

	# Keep the search bar a fixed height
	search_box.custom_minimum_size.y = 36


# call with player owned hands
func set_owned_hands(inv: Dictionary) -> void:
	_inventory = inv.duplicate(true)

	# Ensure the working deck is a copy of the saved deck
	_deck = Globals.get_current_deck().duplicate(true)

	_refresh_stock_ui()
	_refresh_deck_view()
	_refresh_labels()


# stock ui
func _refresh_stock_ui() -> void:
	# Clear UI
	for c in stock_list.get_children():
		c.call_deferred("free")

	var filter_text :String= search_box.text.strip_edges().to_lower()

	# Iterate inventory keys (hands) and compute remaining = inventory - deck
	for hand in _inventory.keys():
		var total_count: int = _inventory.get(hand, 0)
		var deck_count: int = _deck.get(hand, 0)
		var remaining: int = max(0, total_count - deck_count)

		if remaining <= 0:
			continue

		if filter_text != "" and not String(hand.name).to_lower().contains(filter_text):
			continue

		var card = HAND_SCENE.instantiate()
		stock_list.add_child(card)
		card.setup(hand, remaining)
		card.clicked.connect(_on_stock_card_clicked)


# deck ui
func _refresh_deck_view() -> void:
	for c in deck_row.get_children():
		c.queue_free()

	if _deck.is_empty():
		var lbl := Label.new()
		lbl.text = "Deck empty (max %d cards, %d types)" \
			% [Globals.card_inventory_amount_size, Globals.card_inventory_type_size]
		deck_row.add_child(lbl)
		return

	# Display each hand using the stored amount
	for hand in _deck.keys():
		var amount: int = _deck[hand]
		var card = HAND_SCENE.instantiate()
		deck_row.add_child(card)
		card.setup(hand, amount)

		# When clicked, remove one of that card type
		card.clicked.connect(func(_hand: HandData) -> void:
			_remove_one_from_deck(hand)
		)


func _remove_one_from_deck(hand: HandData) -> void:
	if not _deck.has(hand):
		return

	var current_amount: int = _deck[hand]
	if current_amount <= 1:
		_deck.erase(hand)
	else:
		_deck[hand] = current_amount - 1

	_refresh_stock_ui()
	_refresh_deck_view()
	_refresh_labels()


# If you still want a direct handler for deck card clicked, it can reuse the same logic
func _on_deck_card_clicked(hand: HandData) -> void:
	_remove_one_from_deck(hand)


# stock clicked
func _on_stock_card_clicked(hand: HandData) -> void:
	if not _can_add_to_deck(hand):
		_show_status("Cannot add %s: would exceed deck limits" % hand.name)
		return

	var current_amount: int = _deck.get(hand, 0)
	var max_available: int = _inventory.get(hand, 0)

	if current_amount >= max_available:
		_show_status("Cannot add %s: not enough copies in inventory" % hand.name)
		return

	_deck[hand] = current_amount + 1

	_refresh_stock_ui()
	_refresh_deck_view()
	_refresh_labels()


# rules
func _can_add_to_deck(hand: HandData) -> bool:
	var deck_total: int = _get_deck_total_cards()
	var deck_types: int = _deck.size()

	if deck_total + 1 > Globals.card_inventory_amount_size:
		return false

	var will_be_new_type := not _deck.has(hand)
	if will_be_new_type and deck_types + 1 > Globals.card_inventory_type_size:
		return false

	return true


func _get_deck_total_cards() -> int:
	var total := 0
	for hand in _deck.keys():
		total += _deck[hand]
	return total


# search
func _on_search_changed(_new_text: String) -> void:
	_refresh_stock_ui()


# Returns the deck dictionary (working copy)
func get_deck_dictionary() -> Dictionary:
	return _deck.duplicate(true)


# confirm / cancel
func _on_confirm_pressed() -> void:
	var final_deck := get_deck_dictionary()

	if _get_deck_total_cards() <= 3:
		push_error("Cannot save deck of 3 or less cards.")
		return

	Globals.set_current_deck(final_deck.duplicate(true))
	deck_confirmed.emit(final_deck)
	print("[DeckCreator] Deck confirmed with %d unique cards" % final_deck.size())
	_hide_overlay()


func _on_cancel_pressed() -> void:
	print("Returning to map without changes")
	var current := get_deck_dictionary()
	var saved := Globals.get_current_deck()
	var diff := get_deck_difference(current, saved)

	if diff.is_empty():
		print("No changes made - return to menu")
	else:
		print("Unsaved changes detected:", diff)

	_hide_overlay()


# Returns a dictionary of cards that differ between two decks
# Positive amount means full has more; negative means subset has more
func get_deck_difference(full: Dictionary, subset: Dictionary) -> Dictionary:
	var diff := {}

	# Difference for keys present in full
	for k in full.keys():
		var amount: int = full.get(k, 0) - subset.get(k, 0)
		if amount != 0:
			diff[k] = amount

	# Keys present only in subset (full does not have them)
	for k in subset.keys():
		if not full.has(k):
			diff[k] = -subset[k]

	return diff


# status
func _show_status(text: String) -> void:
	print("[DeckCreator] ", text)


# reorder
# With dictionary based storage there is no inherent order, so these are placeholders.
func _move_card_left(_index: int) -> void:
	# If you later need deck order, keep a separate Array and sync it with _deck.
	pass


func _move_card_right(_index: int) -> void:
	pass


func _show_overlay() -> void:
	get_tree().paused = true
	if Globals.inventory.size() > 0:
		set_owned_hands(Globals.inventory)
	_refresh_stock_ui()
	show()


func _hide_overlay() -> void:
	get_tree().paused = false
	hide()


func _refresh_labels() -> void:
	var current_total: int = _get_deck_total_cards()
	var possible_total: int = Globals.card_inventory_amount_size

	var current_types: int = _deck.size()
	var possible_types: int = Globals.card_inventory_type_size

	total_label.text = "Total cards:\n%d/%d" % [current_total, possible_total]
	separate_label.text = "Card types:\n%d/%d" % [current_types, possible_types]
