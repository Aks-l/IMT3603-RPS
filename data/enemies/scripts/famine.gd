extends "res://data/enemies/EnemyData.gd"

var is_dead: bool = false
var line_to_say: String = ""
enum LinePriority {DEATH = 3, STARVE = 2, ALREADY = 1, REJECT = 0}
var current_priority: int = -1

var starve_lines: Array[String] = [
	"'You should have eaten at home!'",
	"'Hollow... empty... how fitting.'",
	"'The body fails long before the spirit.'",
	"'I only take what is already fading.'",
	"'Have you met my siblings yet?'"
]

var already_starved_lines: Array[String] = [
	"'%s has nothing more to give.'",
	"'I pity your frail attempt.'",
]

var death_lines: Array[String] = [
	"'I wish Fiona was here.'",
	"'At last… I, too, fade.'",
	"'The feast… ends with me.'",
]



func on_combat_start(inv: Array[HandData]) -> void:
	is_dead = false
	line_to_say = ""


# ----------------------------------------
# CARD REACTION
# ----------------------------------------
func react_to_card(card: HandData) -> void:
	if is_dead or card == null:
		return

	line_to_say = ""  # reset this round

	if card.living:
		# already starved?
		if "starved" in card.status_flags:
			line_to_say = _make_line(already_starved_lines, card)
		else:
			# first starvation
			starve_card(card)
	else:
		# non-living: no line at this stage
		pass


func starve_card(card: HandData) -> void:
	card.status_flags["starved"] = true
	card.status_revealed = true
	card.status_tint = Color(0.3, 0.6, 0.2)
	emit_signal("update_hand_visual", card)

	line_to_say = _make_line(starve_lines, card)


# ----------------------------------------
# ROUND RESULT
# ----------------------------------------
func modify_result(card: HandData, enemy: HandData, base_result: int) -> int:
	if is_dead:
		return base_result

	var result := base_result

	# starved cards ALWAYS lose, override base_result
	if "starved" in card.status_flags:
		result = -1
		line_to_say = _make_line(already_starved_lines, card)
		return result

	# NORMAL ROUND LINES:
	match result:
		-1:
			# Player loses → starve line
			line_to_say = _make_line(starve_lines, card)

		0:
			# Tie → NO LINE
			pass

		1:
			# Player hits famine → handled after HP changes
			pass

	return result


# ----------------------------------------
# DAMAGE TO FAMINE
# ----------------------------------------
func on_damage_taken(current_hp: int) -> void:
	if current_hp <= 0 and not is_dead:
		is_dead = true
		emit_signal("feedback", death_lines.pick_random())
		return

	# If famine loses 1HP but survives → NO extra line
	if line_to_say != "":
		emit_signal("feedback", line_to_say)


# ----------------------------------------
# LINE GENERATOR
# ----------------------------------------
func _make_line(lines: Array, card: HandData) -> String:
	var line: String = lines.pick_random()
	if card and "%s" in line:
		line = line % card.name
	return line
