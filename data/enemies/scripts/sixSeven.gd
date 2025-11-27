extends "res://data/enemies/EnemyData.gd"

var phase := 1
var used_ids: Array[int] = []
var previous_card_id: int = -1

##SIX SEVEN ENEMY
#PHASE 1 DOESNT DO ANYTHING SPECIAL
#PHASE 2 DOESNT ALLOW THE SAME CARD TO BE PLAYED TWO TIMES IN A ROW

func on_combat_start(inv: Array[HandData]) -> void:
	phase = 1
	used_ids.clear()
	print("Six enters the battle.")

func on_damage_taken(current_hp: int) -> void:
	var previous_phase := phase

	# Map HP → Phase
	if current_hp >= 3:
		phase = 1
	elif current_hp == 2:
		phase = 2
	else:
		phase = 3

	print("Six-Seven HP changed to", current_hp, "→ Phase", phase)

	# Only announce when phase changes
	if phase != previous_phase:
		match phase:
			2:
				emit_signal("feedback", "Seven breaks free! \"Don't you dare reuse a card.\"")
			1:
				emit_signal("feedback", "Six regains control!")
			3:
				emit_signal("feedback", "Six and Seven fuse into CHAOS!")


func react_to_card(card: HandData) -> void:
	if card == null:
		return

	match phase:
		1: _six_react(card)
		2: _seven_react(card)
		3: _fusion_react(card)


func modify_result(player: HandData, enemy: HandData, result: int) -> int:
	var final = result
	match phase:
		1: final = result
		2: final = _seven_modify(player, result)
		3: final = _fusion_modify(result)

	# Update AFTER evaluating
	previous_card_id = player.id
	return final


#phase 6, doesnt do anything
func _six_react(card: HandData) -> void:
	emit_signal("feedback", "%s faces Six without interference." % card.name)


#phase 7, doesnt allow you to play the same card twice in a row
#will end in auto loose
func _seven_react(card: HandData) -> void:
	if card.id == previous_card_id:
		emit_signal("feedback", "Seven curses your repeated %s!" % card.name)
		card.status_revealed = true
		card.status_tint = Color(0.6, 0.0, 0.6)
		emit_signal("update_hand_visuals", card)
	else:
		emit_signal("feedback", "Seven studies your %s carefully…" % card.name)



func _seven_modify(card: HandData, result: int) -> int:
	if card.id == previous_card_id:
		print("Seven converts repeated card into a loss:", card.name)
		return -1
	return result


#phase three doesnt really do anything different

func _fusion_react(card: HandData) -> void:
	emit_signal("feedback", "Chaos swirls around %s!" % card.name)


func _fusion_modify(result: int) -> int:
	return [1, 0, -1].pick_random()
