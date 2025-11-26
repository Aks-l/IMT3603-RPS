extends "res://data/enemies/EnemyData.gd"

# Reference to your Rock card resource
@export var max_censored_cards: int = 1

var censored_cards: Array[HandData] = []


func on_combat_start(inventory_hand: Array[HandData]) -> void:
	if inventory_hand.is_empty():
		return
		
	for i in range(max_censored_cards):
		var card = inventory_hand.pick_random()
		if not ("censored" in card.status_flags):
			card.status_flags["censored"] = true
			card.status_tint = Color(0.7, 0.2, 0.7)
			
			censored_cards.append(card)
			emit_signal("feedback", "%s has been censored!" % card.name)
			print("Censorship applied to: ", card.name)

func react_to_card(card: HandData) -> void:
	if "censored" in card.status_flags:
		emit_signal("feedback", "%s is censored and cannot act!" % card.name)
		
		# Mark this card type as visually revealed (generic)
		card.status_revealed = true
		
		# Tell UI to update visuals
		emit_signal("update_hand_visuals", card)
		
		print("Censored card played: ", card.name)
	else:
		print("%s ignores %s" % [name, card.name])

func modify_result(player_card: HandData, enemy_card: HandData, base_result: int) -> int:
	if player_card.status_flags:
		print("Censorship forced draw for: ", player_card.name)
		return 0 #auto draw
	return base_result
