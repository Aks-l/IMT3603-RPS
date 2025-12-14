extends Control
class_name BattleUI

signal finished(result)

@onready var BATTLE_SCENE: PackedScene = preload("res://scenes/FightScene/fight_scene.tscn")
@onready var victory_fanfare = preload("res://audio/win.wav")
@onready var losing_fanfare = preload("res://audio/lose.wav")
@onready var battle_theme = preload("res://audio/battle.wav")

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
	#_enemy = enemy
	#TEMPORARY: Used for testning of certain enemy. can be changed to other tres-files
	_enemy = load("res://data/enemies/medusa.tres")
	
	_enemy.encounter_count += 1
	_enemy.discovered = true

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
	
	AudioPlayer.play_sound(battle_theme, 1.0)
	
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
			hand_inventory._refresh_ui()
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
	result_label.text = ""  # clear before a new turn

	
	# Let the enemy react first (Medusa, etc.)
	if _enemy and _enemy.has_method("react_to_card"):
		_enemy.react_to_card(hand)
	
	
	var enemy_hand = _enemy.get_hand()
	print("on_card_played called with: ", hand.name)
	
	var result = HandsDb.get_result(hand, enemy_hand)

	
	#special enemy hook. see enemydata for more info
	if _enemy and _enemy.has_method("modify_result"):
		result = _enemy.modify_result(hand, enemy_hand, result)
	
	#dialoge for special enemy
	if _enemy.has_method("emit_round_line"):
		_enemy.emit_round_line()


	# Play combat animation
	
	var showdown = BATTLE_SCENE.instantiate()
	add_child(showdown)
	showdown.setup(hand, enemy_hand, result)
	
	await get_tree().create_timer(0.5).timeout
	$sound_effects.play()
	
	await showdown.finished
	showdown.queue_free()

	
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
			result_label.text = "It's a tie! Both played " + hand.name
			print(result_label.text) 

	if enemy_hearts.get_hp() <= 0: resolve_win()
	elif player_hearts.get_hp() <= 0: resolve_loss()
	
	hand_inventory.unlock_battle()


func resolve_win():
	for owned_item in Globals.consumables:
		if owned_item.item_script:
			owned_item.item_script.call("carried",owned_item)
	_battle_ended = true
	victory.visible = true
	victory.setup(_enemy, true)
	AudioPlayer.play_sound(victory_fanfare)
	await get_tree().process_frame
	get_tree().paused = true

func resolve_loss():
	_battle_ended = true
	Globals.take_damage(1)
	victory.visible = true
	victory.setup(_enemy, false)
	AudioPlayer.play_sound(losing_fanfare)
	await get_tree().process_frame
	get_tree().paused = true

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
	
	
