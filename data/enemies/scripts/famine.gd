extends "res://data/enemies/EnemyData.gd"

var is_dead: bool = false
var next_line: String = ""


var dialogue := {
	"battle": [
		"'You should have eaten at home!'",
		"'The body fails long before the spirit.'",
		"'I only take what is already fading.'",
		"'Have you met my siblings yet?'",
		"'Do I exist in your world, too?'"
	],
	"death": [
		"'I wish Fiona was here...'",
		"'At last... I, too, fade.'",
		"'The feast ends with me.'"
	]
}


func on_combat_start(inv: Array[HandData]) -> void:
	is_dead = false
	next_line = ""



# CARD REACTION
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


# ROUND RESULT

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


func emit_round_line() -> void:
	# Called after modify_result for ALL outcomes (win/lose/tie)
	# Don't emit anything here - let on_damage_taken handle it
	pass


# DAMAGE / DEATH
func on_damage_taken(current_hp: int) -> void:
	if is_dead:
		return

	if current_hp <= 0:
		is_dead = true
		next_line = ""  # Clear battle line so only death line shows
		_emit_death_line()
		return
	
	# Enemy survived - emit the stored battle line
	_emit_stored_line()


func on_round_end() -> void:
	# Called at the end of every round (even ties and player losses)
	# Emit battle line if enemy is still alive
	if not is_dead and next_line != "":
		_emit_stored_line()



# line helpers
func _set_battle_line(card: HandData) -> void:
	# Pick random battle line
	var l: String = dialogue["battle"].pick_random()
	if "%s" in l and card:
		l = l % card.name
	next_line = l


func _emit_stored_line() -> void:
	if next_line != "":
		emit_signal("feedback", next_line)
	next_line = ""


func _emit_death_line() -> void:
	var l: String = dialogue["death"].pick_random()
	emit_signal("feedback", l)
	next_line = ""
