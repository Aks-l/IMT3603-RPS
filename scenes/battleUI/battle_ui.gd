extends Control
class_name BattleUI

signal finished(result)

@onready var hand_inventory = %HandInventory
@onready var result_label = %ResultLabel

@onready var player_hearts = %PlayerHearts
@onready var enemy_hearts = %EnemyHearts

@onready var victory = %Victory
@onready var outcome_graph_panel = %OutcomeGraphPanel
@onready var graph_toggle_button = %GraphToggleButton
@onready var graph_close_button = %CloseButton

var _enemy: EnemyData
var _hand: Dictionary = {}		# CHANGE THESE WHEN HANDS AND 
var _consumables: Array = []	# CONSUMABLES ARE IMPLEMENTED

var _has_params := false
var _is_ready := false

# THE LAST OF SETUP AND READY WILL CALL _apply
func setup(enemy: EnemyData, hand: Dictionary[HandData, int], consumables: Array) -> void:
	_enemy = enemy
	_consumables = consumables
	
	var loaded_deck = Globals.get_current_deck()
	if not loaded_deck.is_empty():
		_hand = loaded_deck
	else:
		_hand = hand
	#_hand = hand if not hand.is_empty() else Globals.current_deck
	#uses DeckBuilder to generate a deck from the available hands
	#var deck_builder = DeckBuilder.new()
	#_hand = deck_builder.build_deck(hand, 15) #gives limit of 15
	#_hand = hand
	_has_params = true
	if _is_ready:
		_apply()

func _ready():
	victory.visible = false
	victory.chosen_reward.connect(queue_free)
	
	player_hearts.set_hp(5) #health for player
	enemy_hearts.set_hp(5) #health for enemy
	
	result_label.text = ""  #start with empty result
	hand_inventory.card_clicked.connect(on_card_played)
	
	#Setup outcome graph toggle
	if outcome_graph_panel:
		outcome_graph_panel.visible = false
	if graph_toggle_button:
		graph_toggle_button.pressed.connect(_toggle_outcome_graph)
	if graph_close_button:
		graph_close_button.pressed.connect(_toggle_outcome_graph)
	
	_is_ready = true
	if _has_params:
		_apply()


func _apply():
	
	var profile = get_node_or_null(^"%OpponentProfile")
	var inv_node = get_node_or_null(^"%HandInventory")

	if profile:
		profile.set_enemy(_enemy)
	else:
		print("No enemy found; opponent_profile.gd")
	
	if inv_node:
		print("[BattleUI] Using deck:", Globals.get_current_deck)
		var deck : Dictionary[HandData, int] = Globals.get_current_deck()
		print("[BattleUI] Converted deck for HandInventory:", deck)
		inv_node.set_inventory(deck)
	else:
		print("No HandInventory found")

##Card Played
##Resolves the outcome of a played card against the enemy's card
##Updates health and checks for victory/loss
func on_card_played(hand: HandData):
	print("BattleUI received card:", hand.name)
	var enemy_hand = _enemy.get_hand()
	print("on_card_played called with: ", hand.name)
	
	#print("You played: " + hand.name)
	#print("Enemy played: " + enemy_hand.name)
	
	var result = HandsDb.get_result(hand, enemy_hand)
	match result:
		1:
			result_label.text = "You win! " + hand.name + " beats " + enemy_hand.name
			print(result_label.text) #DEBUG
			enemy_hearts.take_damage(1)
		-1:
			result_label.text = "You lose! " + enemy_hand.name + " beats " + hand.name
			print(result_label.text) #DEBUG
			player_hearts.take_damage(1)
		0:
			result_label.text = "It's a tie! Both played " + hand.name
			print(result_label.text) #DEBUG
	if enemy_hearts.get_hp() <= 0:
		victory.visible = true
		victory.setup(_enemy, true)
		
		## ONCE AN ITEM IS CHOSEN, queue_free()
		
	elif player_hearts.get_hp() <= 0:
		push_error("TODO: implement gameover/loss resolution")
		victory.setup(_enemy, false)
		assert(false)

##Item Used, handles effects of used items TODO: move to separate script?
func _on_item_used(item: ItemData):
	match item.type:
		ItemData.Type.HEAL:
			player_hearts.heal(1)
		ItemData.Type.SHIELD:
			player_hearts.add_blue(1)

func _toggle_outcome_graph():
	if outcome_graph_panel:
		outcome_graph_panel.visible = !outcome_graph_panel.visible

##Input Handling, toggles outcome graph with 'G' key
func _input(event: InputEvent):
	# Toggle outcome graph with 'G' key
	if event.is_action_pressed("input_keyboard_key_G"):
		_toggle_outcome_graph()
