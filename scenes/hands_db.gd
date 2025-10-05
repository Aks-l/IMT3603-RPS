extends Node

class_name HandsDB

@export var hands: Array[HandData] = []  #drags inn rock, paper,scissors .tres


func get_result(hand_a: HandData, hand_b: HandData) -> int:
	var num_hands = HandDatabase.hands.size()
	var result_bool:bool = (hand_a.id + hand_b.id) % num_hands >= num_hands / 2
	
	if hand_a.id == hand_b.id:
		return 0 #tie
	if result_bool:
		return 1 #A wins!!!!
	if not result_bool:
		return -1 #A looses :(
	assert(false)
	return 99
