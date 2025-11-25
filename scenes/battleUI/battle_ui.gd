extends Control
class_name BattleUI

signal finished(result)

@onready var hand_inventory = %HandInventory
@onready var result_label = %ResultLabel

@onready var player_hearts = %PlayerHearts
@onready var enemy_hearts = %EnemyHearts

@onready var victory = %Victory

@onready var level_label = %LevelLabel
@onready var gold_label = %GoldLabel

var _enemy: EnemyData
var _hand: Dictionary = {}		# CHANGE THESE WHEN HANDS AND 
var _consumables: Array = []	# CONSUMABLES ARE IMPLEMENTED
var _battle_ended := false		# Prevent card plays after battle ends

var _has_params := false
var _is_ready := false

# THE LAST OF SETUP AND READY WILL CALL _apply
func setup(enemy: EnemyData, hand: Dictionary[HandData, int], consumables: Array) -> void:
	_enemy = enemy
	_consumables = consumables
	
	_enemy.discovered = true
	for _hand:HandData in enemy.deck.keys(): _hand.discovered = true 
	
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
	if _is_ready:
		_apply()

func _ready():
	victory.chosen_reward.connect(queue_free)
	
	result_label.text = ""  #start with empty result
	hand_inventory.card_clicked.connect(on_card_played)
	
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
		
	outcome_graph_panel._refresh()

##Card Played
##Resolves the outcome of a played card against the enemy's card
##Updates health and checks for victory/loss
func on_card_played(hand: HandData):
	# Prevent playing cards after battle has ended
	if _battle_ended:
		return
		
	print("BattleUI received card:", hand.name)
	var enemy_hand = _enemy.get_hand()
	print("on_card_played called with: ", hand.name)
	
	var result = HandsDb.get_result(hand, enemy_hand)
	match result:
		1:
			result_label.text = "You win! " + hand.name + " beats " + enemy_hand.name
			print(result_label.text)
			enemy_hearts.take_damage(1)
		-1:
			result_label.text = "You lose! " + enemy_hand.name + " beats " + hand.name
			print(result_label.text)
			player_hearts.take_damage(1)
		0:
			result_label.text = "It's a tie! Both played " + hand.name
			print(result_label.text) 
	if enemy_hearts.get_hp() <= 0: resolve_win()
	elif player_hearts.get_hp() <= 0: resolve_loss()

func resolve_win():
	for owned_item in Globals.consumables:
		if owned_item.item_script:
			owned_item.item_script.call("carried",owned_item)
	_battle_ended = true
	victory.visible = true
	victory.setup(_enemy, true)
	get_tree().paused = true

func resolve_loss():
	_battle_ended = true
	Globals.take_damage(1)	
	victory.visible = true
	victory.setup(_enemy, false)
	get_tree().paused = true

func _toggle_outcome_graph():
	if outcome_graph_panel:
		outcome_graph_panel.visible = !outcome_graph_panel.visible

##Input Handling, toggles outcome graph with 'G' key
func _input(event: InputEvent):
	# Toggle outcome graph with 'G' key
	if event.is_action_pressed("input_keyboard_key_G"):
		_toggle_outcome_graph()
