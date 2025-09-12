extends Node

var enemy: EnemyData
var _hand: Array = []
var _consumables: Array = []

func start(e: EnemyData, h: Array, c: Array) -> void:
	enemy = e
	_hand = h
	_consumables = c
	print("CHANGING SCENE TO BATTLEUI...")
	get_tree().change_scene_to_file("res://scenes/battleUI/battle_ui.tscn")

func take() -> Dictionary:
	var d := {"enemy": enemy, "hand": _hand, "consumables": _consumables}
	enemy = null
	_hand = []
	_consumables = []
	print("Take function triggered")
	return d
