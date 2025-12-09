extends "res://data/enemies/EnemyData.gd"

@export var holy := true
@export var concept := true
@export var land := true

var is_dead: bool = false
var next_line: String = ""

# Dialogue sets

var intro_lines: Array[String] = [
	"'Blessings upon you, traveler.'",
	"'You walk in the light, friend.'",
	"'Would you join me for a prayer?'"
]
var purify_lines: Array[String] = [
	"'I banish you, evil!'",
	"'His light will prevail!'",
	"'Gone to His embrace!'"
]

var holy_lines: Array[String] = [
	"'A gift?'",
	"'I already have one of those.'"
]

var evil_lines: Array[String] = [
	"'Begone evil spirit!'",
]

var battle_lines: Array[String] = [
	"'The divine shall decide!'",
	"'Faith shall triumph!'",
	"'Your sins weigh heavy...'"
]

var death_lines: Array[String] = [
	"'Even in death, I shall serve the light.'",
	"'May I see Him...'",
	"'How can your resolve be heavier than my faith...'"
]

func on_combat_start(players_cards: Array[HandData]) -> void:
	is_dead = false
	next_line = ""
	emit_signal("feedback", intro_lines.pick_random())

func react_to_card(card: HandData) -> void:
	if is_dead or card == null:
		return

	# Default: prepare a battle line to show later this turn.
	next_line = battle_lines.pick_random()

	# Evil is purified immediately -> overrides battle line this turn.
	if card.evil:
		# Visuals
		card.status_revealed = true
		card.status_tint = Color.WHITE
		emit_signal("update_hand_visuals", card)

		# Purify line overrides and is emitted now. Clear stored battle line.
		var line: String = purify_lines.pick_random()
		emit_signal("feedback", line)
		next_line = ""  # prevent a second line this turn
		return
	 
	if card.holy:
		card.status_revealed = true
		card.status_tint = Color.WHITE
		emit_signal("update_handvisuals", card)
		
		var line: String = holy_lines.pick_random()
		emit_signal("feedback", line)
		next_line = ""
		return


	# Holy cards: no special line here; they will auto-tie in modify_result.
	# Leave next_line as the stored battle line.
	

func modify_result(card: HandData, enemy_card: HandData, result: int) -> int:
	if is_dead or card == null:
		return result

	# Evil auto-lose against the Priest
	if card.evil:
		card.status_revealed = true
		card.status_tint = Color(0.9, 0.3, 0.3)
		card.status_flags["evil"] = true
		emit_signal("update_hand_visuals", card)
		
		return -1

	# Holy auto-tie (no special line here; battle line will show normally)
	if card.holy:
		card.status_revealed = true
		card.status_tint = Color(0.9, 0.9, 0.5)
		card.status_flags["evil"] = true
		emit_signal("update_hand_visuals", card)

		return 0
	
	return result


func on_damage_taken(current_hp: int) -> void:
	if is_dead:
		return

	if current_hp <= 0:
		is_dead = true
		next_line = ""  # ensure nothing else prints
		emit_signal("feedback", death_lines.pick_random())
		return

	# Enemy survived — emit any stored battle line for this turn.
	_emit_stored_line()

func on_round_end() -> void:
	# Called even on ties/losses; show a single stored line if any and not dead.
	if not is_dead and next_line != "":
		_emit_stored_line()

func _emit_stored_line() -> void:
	if next_line != "":
		emit_signal("feedback", next_line)
	next_line = ""
