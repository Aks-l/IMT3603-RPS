extends "res://data/enemies/EnemyData.gd"

# Reference to your Rock card resource
@export var max_censored_cards: int = 1

func on_combat_start(inventory_hand: Array[HandData]) -> void:
	if inventory_hand.is_empty():
		return
		
	for i in range(max_censored_cards):
		var card = inventory_hand.pick_random()
		if not card.censored:
			card.censored = true
			emit_signal("feedback", "%s has been censored!" % card.name)
			print("Censorship applied to: ", card.name)

func react_to_card(card: HandData) -> void:
	if card.censored:
		emit_signal("feedback", "%s is censored and cannot act!" % card.name)
		print("Censored card played: ", card.name)
	else:
		print("%s ignores %s" % [name, card.name])

func modify_result(player_card: HandData, enemy_card: HandData, base_result: int) -> int:
	if player_card.censored:
		print("Censorship forced draw for: ", player_card.name)
		return 0 #auto draw
	return base_result
