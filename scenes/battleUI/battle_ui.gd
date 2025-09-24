extends Node3D
class_name BattleUI

@onready var hand_inventory = %HandInventory
@onready var result_label = $ResultLabel

@onready var player_hearts = $PlayerHearts
@onready var enemy_hearts = $EnemyHearts

var _enemy: EnemyData
var _hand: Array[HandData]		# CHANGE THESE WHEN HANDS AND 
var _consumables: Array = []	# CONSUMABLES ARE IMPLEMENTED

var _has_params := false
var _is_ready := false

# THE LAST OF SETUP AND READY WILL CALL _apply
func setup(enemy: EnemyData, hand: Array[HandData], consumables: Array) -> void:
	_enemy = enemy
	_hand = hand
	_consumables = consumables
	_has_params = true
	if _is_ready:
		_apply()

func _ready():
	player_hearts.set_hp(5) #health for player
	enemy_hearts.set_hp(5) #health for enemy
	result_label.text = ""  #start with empty result
	hand_inventory.card_clicked.connect(on_card_played)
	_is_ready = true
	if _has_params:
		_apply()

func _apply():
	var profile = get_node_or_null(^"%OpponentProfile")
	var inv_node = get_node_or_null(^"%HandInventory")
	#var consinv = get_node_or_null(consumables_path)

	if profile: 
		profile.set_enemy(_enemy)
	else: print("No enemy found; opponent_profile.gd")
	
	if inv_node:
		print("BattleUI calling set_inventory with", _hand.size(), "hands")
		inv_node.set_inventory(_hand)
	else:
		print("No HandInventory found")


func on_card_played(hand: HandData):
	print("BattleUI received card:", hand.name)
	var enemy_hand = _enemy.get_hand()
	print("on_card_played called with: ", hand.name)
	
	#print("You played: " + hand.name)
	#print("Enemy played: " + enemy_hand.name)
	
	var result = HandsDb.get_result(hand.name, enemy_hand.name)
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
	
	
	
	
