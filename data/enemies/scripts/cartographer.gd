extends "res://data/enemies/EnemyData.gd"


var is_dead: bool = false
var next_line: String = ""

# Dialogue sets
var dialogue := {
	"intro": {
		"default": [
			"'Every journey starts with a question… most end with a map.'"
		],
		"discovered1": [
			"'The wind changed this morning. Makes me uneasy.'",
			"'Could you look over this?'"
			],
		},
	"battle": {
		"default": [
			"'Some new coordinates.'",
			"'I’d prefer a compass over conflict.'",
			"'I have traveled more than most.'",
			"'Can you imagine something you haven't seen?'",
			"'The stars guid many.'"
		],
		"discovered1": [
			"'The wind is but a passing of time.'",
			"'Rivers change when they want.'"
		],
		"discovered2": [
			"'Have you seen the yellow forest?'",
			"'I see far travels in you past and future.'"
		],
		"discovered3": [
			"'I’ve charted mountains, rivers, deserts… yet I don't know where you are from.'"
		],
	},
	"death": {
		"default": [
			"'There must be something else to see...'"
		],
		"discovered1": [
			"'A new world to map out...'"
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
	if encounter_count <= 6:
		return ["default", "discovered1", "discovered2", "discovered3"]
	return ["default", "discovered1", "discovered2", "discovered3"]


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
