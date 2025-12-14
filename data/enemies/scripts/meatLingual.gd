extends "res://data/enemies/EnemyData.gd"

var drowned_cards: Array[HandData] = []

func react_to_card(card: HandData) -> void:
	if card == null:
		return

	if card.dry:
		_drown(card)
	else:
		emit_signal("feedback", "%s can't drown." % card.name)
		print("%s is unaffected by %s's water." % [card.name, name])


func _drown(card: HandData) -> void:
	if not drowned_cards.has(card):
		drowned_cards.append(card)

	emit_signal("feedback", "%s cannot stay in water!" % card.name)
	print("%s has drowned!" % card.name)

	# Mark as revealed — this is the ONLY universal flag we need
	card.status_revealed = true
	card.status_tint = Color(0.3, 0.4, 0.9)
	card.status_flags["drowned"] = true
	
	# Generic signal → BattleUI → HandInventory → tint card
	emit_signal("update_hand_visuals", card)


func modify_result(player_card: HandData, enemy_card: HandData, base_result: int) -> int:
	if player_card.dry:
		print("Drowned card auto-loses: %s" % player_card.name)
		return -1
	return base_result
