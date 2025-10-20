extends Node

var hands: Dictionary = {}
signal hands_loaded

func _ready() -> void:
	load_hands()
	emit_signal("hands_loaded")
	
func load_hands():
	var dir := DirAccess.open("res://data/cards")
	if dir:
		for file in dir.get_files():
			if file.ends_with(".tres"):
				var hand = load("res://data/cards/" + file)
				if hand and hand is HandData:
					hands[hand.id] = hand
					#hands[hand.id] = hand
					print("added " + hand.name)
	hands.erase(9999)
	
