extends Node

class_name HandsDB

@export var hands: Array[HandData] = []  #drags inn rock, paper,scissors .tres
var lookup: Dictionary = {}

func _ready():
	#dictionary to look up hands by name
	for h in hands:
		lookup[h.name] = h
		
func get_result(hand_a: String, hand_b: String) -> int:
	if hand_a == hand_b:
		return 0 #tie
	if hand_b in lookup[hand_a].beats:
		return 1 #A wins!!!!
	if hand_a in lookup[hand_b].beats:
		return -1 #A looses :(
	return 0 
