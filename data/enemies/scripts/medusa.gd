extends "res://data/enemies/EnemyData.gd"

func react_to_card(card: HandData) -> void:
	if card.living:
		print("%s turns %s to stone!" % [name, card.name])
	else:
		print("%s is unaffected by %s's gaze" % [card.name, name])
