extends Node

var hands: Dictionary = {}
var inventory: Array[HandData] = []

func _ready() -> void:
	inventory.clear()
	load_hands()
	inventory.append(hands[0])
	inventory.append(hands[1])
	inventory.append(hands[2])


func load_hands():
	var dir := DirAccess.open("res://data/cards")
	if dir:
		for file in dir.get_files():
			if file.ends_with(".tres"):
				var hand = load("res://data/cards/" + file)
				if hand and hand is HandData:
					hands[hand.id] = hand


	
