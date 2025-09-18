extends Node3D
class_name BattleUI

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
		inv_node.set_inventory(_hand)

static func instantiate_with(enemy: EnemyData, hand: Array, consumables: Array) -> BattleUI:
	var scene := preload("res://scenes/battleUI/battle_ui.tscn").instantiate() as BattleUI
	scene.setup(enemy, hand, consumables)
	return scene
