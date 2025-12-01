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

@onready var level_label = %LevelLabel
@onready var gold_label = %GoldLabel


var _enemy: EnemyData
var _hand: Dictionary = {}		# CHANGE THESE WHEN HANDS AND 
var _consumables: Array = []	# CONSUMABLES ARE IMPLEMENTED

var _has_params := false
var _is_ready := false

# THE LAST OF SETUP AND READY WILL CALL _apply
func setup(enemy: EnemyData, hand: Dictionary[HandData, int], consumables: Array) -> void:
	#_enemy = enemy
	#TEMPORARY: Used for testning of certain enemy. can be changed to other tres-files
	_enemy = load("res://data/enemies/humanResources.tres")

	_consumables = consumables
	
	player_hearts.set_hp(Globals.battlehealth)
	player_hearts._draw_hearts()
	enemy_hearts.set_hp(3) # TODO: Change to enemy.health once implemented
	enemy_hearts._draw_hearts()
	level_label.text = "Level: %d - %d" % [Globals.run_biomes_completed+1, Globals.biome_levels_completed+1]
	gold_label.text = "Gold: %d" % Globals.funds
	
	var loaded_deck = Globals.get_current_deck()
	if not loaded_deck.is_empty():
		_hand = loaded_deck
	else:
		_hand = hand
	_has_params = true
	
	# Connect signals BEFORE applying
	if _enemy and _enemy.has_signal("feedback"):
		_enemy.feedback.connect(_on_enemy_feedback)
		print("Connected enemy feedback signal") # DEBUG
	
	if _enemy.has_signal("update_hand_visuals"):
		_enemy.update_hand_visuals.connect(_on_enemy_update_hand_visuals)
	
	if _is_ready:
		_apply()

func _ready():
	victory.chosen_reward.connect(queue_free)
	
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
	#	print("[BattleUI] Using deck:", Globals.get_current_deck)
	#	var deck : Dictionary[HandData, int] = Globals.get_current_deck()
	#	print("[BattleUI] Converted deck for HandInventory:", deck)
	#	inv_node.set_inventory(deck)
		var deck : Dictionary[HandData, int] = Globals.get_current_deck()
		var local_deck : Dictionary[HandData, int] = {}
		
		for card_data in deck.keys():
			var duplicated_card: HandData = card_data.duplicate(true)
			local_deck[duplicated_card] = deck[card_data]
		inv_node.set_inventory(local_deck)
		
		if _enemy and _enemy.has_method("on_combat_start"):
			var players_cards: Array[HandData] = []
			for card in local_deck.keys():
				players_cards.append(card)
			_enemy.on_combat_start(players_cards)
	else:
		print("No HandInventory found")

##Card Played
##Resolves the outcome of a played card against the enemy's card
##Updates health and checks for victory/loss
func on_card_played(hand: HandData):
	print("BattleUI received card:", hand.name)
	result_label.text = ""  # clear before a new turn

	
	# Let the enemy react first (Medusa, etc.)
	if _enemy and _enemy.has_method("react_to_card"):
		_enemy.react_to_card(hand)
	
	
	var enemy_hand = _enemy.get_hand()
	print("on_card_played called with: ", hand.name)
	
	#print("You played: " + hand.name)
	#print("Enemy played: " + enemy_hand.name)
	
	var result = HandsDb.get_result(hand, enemy_hand)
	
	#special enemy hook. see enemydata for more info
	if _enemy and _enemy.has_method("modify_result"):
		result = _enemy.modify_result(hand, enemy_hand, result)
	
	#dialoge for special enemy
	if _enemy.has_method("emit_round_line"):
		_enemy.emit_round_line()

	
	match result:
		1:
			result_label.text += "\nYou win! " + hand.name + " beats " + enemy_hand.name
			print(result_label.text) #DEBUG
			enemy_hearts.take_damage(1)
			
			if _enemy.has_method("on_damage_taken"):
				_enemy.on_damage_taken(enemy_hearts.get_hp())
				
			
		-1:
			result_label.text += "\nYou lose! " + enemy_hand.name + " beats " + hand.name
			print(result_label.text) #DEBUG
			player_hearts.take_damage(1)
			
		0:
			result_label.text += "\nIt's a tie! Both played " + hand.name
			print(result_label.text) #DEBUG
	
	# Call on_round_end after all damage has been applied
	if _enemy and _enemy.has_method("on_round_end"):
		_enemy.on_round_end()
			
			
	if enemy_hearts.get_hp() <= 0:
		victory.visible = true
		victory.setup(_enemy, true)
		get_tree().paused = true
		
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

#For special enemies
func _on_enemy_feedback(message: String) -> void:
	# show this message above the nomral win/lose link
	result_label.text = message + "\n" + result_label.text
	print(">>> UI received feedback signal") # DEBUG

func _on_enemy_update_hand_visuals(hand: HandData):
	hand_inventory.update_visuals_for(hand)
	
	
