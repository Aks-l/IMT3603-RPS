extends "res://data/enemies/EnemyData.gd"

var is_dead: bool = false
var next_line: String = ""

var battle_lines: Array[String] = [
	"'You should have eaten at home!'",
	"'The body fails long before the spirit.'",
	"'I only take what is already fading.'",
	"'Have you met my siblings yet?'",
	"'Do I exist in your world, too?'",
]

var death_lines: Array[String] = [
	"'I wish Fiona was here...'",
	"'At last... I, too, fade.'",
	"'The feast ends with me.'",
]

func on_combat_start(inv: Array[HandData]) -> void:
	is_dead = false
	next_line = ""


# ---------------------------------------------------------
# CARD REACTION
# ---------------------------------------------------------
func react_to_card(card: HandData) -> void:
	if card == null or is_dead:
		return

	# reset any previous stored line
	next_line = ""

	if card.living:
		starve_card(card)
	else:
		# Non-living → still give a battle line!
		_set_battle_line(card)


func starve_card(card: HandData) -> void:
	if "starved" in card.status_flags:
		# Still just battle lines — nothing special
		_set_battle_line(card)
		return

	card.status_flags["starved"] = true
	card.status_revealed = true
	card.status_tint = Color(0.3, 0.6, 0.2)

	emit_signal("update_hand_visual", card)

	# Starving a card = also battle line
	_set_battle_line(card)


# ---------------------------------------------------------
# ROUND RESULT
# ---------------------------------------------------------
func modify_result(card: HandData, enemy: HandData, base_result: int) -> int:
	if is_dead:
		return base_result

	# Starved cards ALWAYS lose
	if "starved" in card.status_flags:
		_set_battle_line(card)
		return -1

	# Always set a battle line regardless of win/lose/tie
	_set_battle_line(card)

	return base_result


# ---------------------------------------------------------
# DAMAGE / DEATH
# ---------------------------------------------------------
func on_damage_taken(current_hp: int) -> void:
	if is_dead:
		return

	if current_hp <= 0:
		is_dead = true
		_emit_death_line()
		return

	# Not dead → emit the stored battle line
	_emit_stored_line()


# ---------------------------------------------------------
# LINE HELPERS
# ---------------------------------------------------------
func _set_battle_line(card: HandData) -> void:
	# Pick random battle line
	var l: String = battle_lines.pick_random()
	if "%s" in l and card:
		l = l % card.name
	next_line = l


func _emit_stored_line() -> void:
	if next_line != "":
		emit_signal("feedback", next_line)
	next_line = ""


func _emit_death_line() -> void:
	var l: String = death_lines.pick_random()
	emit_signal("feedback", l)
	next_line = ""
