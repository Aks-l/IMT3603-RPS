extends "res://data/enemies/EnemyData.gd"

var is_dead: bool = false
var next_line: String = ""

# Dialogue sets
var dialogue := {
	"intro": {
		"default": [
			"'Will you join me for the road?'",
			"'A small break from the journey never hurt.'",
			"'Maybe a friend?'"
		],
		"discovered1": [
			"'Have I seen you before?'",
			"'If I may, I will leave a flower'"
		],
		},
	"battle": {
		"default": [
			"'There is no place for me to stay.'",
			"'There are so many who travel alone.'",
			"'No shame in asking, friend.'",
			"'I wasn't expecting this'"
		],
		"discovered1": [
			"'Is there a chance I win?'",
			"'After this, we can pick flowers'",
			"'There should be some rules to this?'"
		],
		"discovered2": [
			"'No shame in asking, friend.'",
			"'Do you understand yourself?'",
			"'Tell me, have this happend before?'"
		],
	},
	"death": {
		"default": [
			"'Is this... possible?'"
		],
		"discovered1": [
			"'Leave me a flower.'",
			"'I have to warn them...'"
		]
	}
}

#decides how to get lines
func _get_line(category: String) -> String:
	if not dialogue.has(category):
		return ""
		
	var tiers := _get_discovery()
	var sections: Dictionary = dialogue[category]
	var pool: Array[String] = []
		
	for tier in tiers:
		if sections.has(tier):
			pool.append_array(sections[tier])
			
	if pool.is_empty() and sections.has("default"):
		pool = sections["default"]
		
	return "" if pool.is_empty() else pool.pick_random()

#prints lines based on how many times you have encountered them

func _get_discovery() -> Array[String]:
	if encounter_count <= 1:
		return ["default"]
	if encounter_count <= 2:
		return ["default", "discovered1"]
	if encounter_count <= 3:
		return ["default", "discovered1", "discovered2"]
	return ["default", "discovered1", "discovered2"]


func on_combat_start(players_cards: Array[HandData]) -> void:
	is_dead = false
	next_line = ""
	emit_signal("feedback", _get_line("intro"))

func react_to_card(card: HandData) -> void:
	if is_dead or card == null:
		return
	next_line = _get_line("battle")

func on_damage_taken(current_hp: int) -> void:
	if is_dead:
		return

	if current_hp <= 0:
		is_dead = true
		next_line = ""
		emit_signal("feedback", _get_line("death"))
		return

	_emit_stored_line()

func on_round_end() -> void:
	if not is_dead and next_line != "":
		_emit_stored_line()

func _emit_stored_line() -> void:
	if next_line != "":
		emit_signal("feedback", next_line)
	next_line = ""
