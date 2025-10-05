extends Node

var hands: Dictionary = {}

func _ready() -> void:
	load_hands()
	add_hands()
	
func load_hands():
	var dir := DirAccess.open("res://data/cards")
	if dir:
		for file in dir.get_files():
			if file.ends_with(".tres"):
				var hand = load("res://data/cards/" + file)
				if hand and hand is HandData:
					hands[hand.id] = hand
					print("added " + hand.name)
					
func add_hands():
	Globals.inventory[hands[0]] = 5
	Globals.inventory[hands[2]] = 1
	Globals.inventory[hands[4]] = 1
