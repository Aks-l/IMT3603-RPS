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
@onready var conf_button := $"MarginContainer/VBoxContainer/HBoxContainer2/ConfirmDeck"
@onready var cancel_button := $"MarginContainer/VBoxContainer/HBoxContainer2/Cancel"


#data struckture
var _owned_counts : Dictionary = {}
var _deck_list : Array = []

func _ready() -> void:
	search_box.text_changed.connect(_on_search_changed)
	confim_btn.pressed.connect(_on_confirm_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)

#call with palyers oend hands
func set_owned_hands(hands: Array[HandData]) -> void:
	#build counts grouped by name
	_owned_counts.clear()
	for h in hands:
		if h.name in _owned_counts:
			_owned_counts[h.name].count += 1
			else:
				_owned_counts[h.name] = ["data": h, "count": 1]
	_deck_list.clear()
	_refresh_stock_ui()
	_refresh_deck_ui()

#stock ui
func _refresh_stock_ui() -> void:
	stock_list.clear_childer()
	var filter_text = search_box.text.strip_edges().to_lower()
	for name in _owned_count.keys():
		var entry = _owned_counts[name]
		var count = entry.count
		if count <= 0:
			continue
		if filter_text != "" and not name.to_lower().findn(filter_text) >= 0:
			continues
		#create a hand card instance showing how many the plauer onws
		var card = HAND_SCENE.instantiate()
		stock_list.add_child(card)
		card.setup(entry.data, count)
		#bind handler check what was cliked
		card.clicked.connect(Callable(self, "on_stock_scard_clicked").bind(card))
		#can be found if needed
		card.set_meta("hand_name", name)

#deck ui
func _refresh_deck_view() -> void:
	deck_row.clear_children()
	if _deck_list.empty():
		#oputionaru shoou purasehoruderu oru emputii raberu
		var lbl = Label.new()
		lbl.text = "deck empty (max %d cards, %d types)".format(MAX_TOTAL, MAX_UNIQUE_TYPES)
		deck_row.add_child(lbl)
		return

#group by name
var grouped := {}
for h in _deck_list:
	if h.name in grouped:
		grouped[h.name].count += 1
	else:
		grouped[h.name] = ["data": h, "count": 1]

#render grouped cards left to right
for name in grouped.key
