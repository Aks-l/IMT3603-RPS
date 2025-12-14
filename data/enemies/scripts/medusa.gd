extends "res://data/enemies/EnemyData.gd"

@export var rock_card: HandData = preload("res://data/cards/rock.tres")

var is_dead: bool = false
var next_line: String = ""
var has_petrified := false

var dialogue := {
	"battle": [
		"'Do not look at me.'",
		"'Stone remembers everything.'",
		"'The gaze is already enough.'",
		"'You will still be here. Just quieter.'",
		"'I warned you.'"
	],
	"petrify": [
		"'Turn to stone!'"
		],
	"death": [
		"'Even monsters turn to myth.'",
		"'The stone finally cracks.'",
		"'I am done looking.'"
	]
}


func on_combat_start(players_cards: Array[HandData]) -> void:
	is_dead = false
	next_line = ""
	has_petrified = false

	for card in players_cards:
		# Petrify ALL living cards except the Medusa card itself
		if card.living and card.name != "Medusa":
			has_petrified = true
			petrify_card(card)
			_set_battle_line(card)
			emit_signal("update_hand_visuals", card)


func react_to_card(card: HandData) -> void:
	if card == null or is_dead:
		return

	next_line = ""

	# Special reaction if player plays Medusa card
	if card.name == "Medusa":
		next_line = "'You understand more than most.'"
		return

	# Petrified cards are just rocks now
	if card.status_flags.get("petrified", false):
		next_line = "'Throwing stones?'"
		return

	_set_battle_line(card)


func modify_result(player_card: HandData, enemy_card: HandData, base_result: int) -> int:
	if is_dead:
		return base_result

	# Medusa card always ties Medusa
	if player_card.name == "medusa":
		return 0

	# Petrified cards always lose
	if player_card.status_flags.get("petrified", false):
		return -1

	return base_result


func on_damage_taken(current_hp: int) -> void:
	if is_dead:
		return

	if current_hp <= 0:
		is_dead = true
		next_line = ""
		_emit_death_line()
		return

	_emit_stored_line()

func on_round_end() -> void:
	if not is_dead and next_line != "":
		_emit_stored_line()


func petrify_card(card: HandData) -> void:
	if rock_card == null:
		return

	card.status_flags["petrified"] = true
	card.status_revealed = true
	card.status_tint = Color(0.6, 0.6, 0.6)

	# Copy ROCK behavior
	card.name = rock_card.name
	card.sprite = rock_card.sprite

	card.living = false
	card.human = false
	card.plant = false
	card.elemental = false
	card.holy = false
	card.evil = false
	card.metalic = true
	card.weird = false

	emit_signal("update_hand_visuals", card)
	emit_signal("feedback", dialogue["petrify"].pick_random())


func _set_battle_line(card: HandData) -> void:
	next_line = dialogue["battle"].pick_random()

func _emit_stored_line() -> void:
	if next_line != "":
		emit_signal("feedback", next_line)
	next_line = ""

func _emit_death_line() -> void:
	emit_signal("feedback", dialogue["death"].pick_random())
	next_line = ""
