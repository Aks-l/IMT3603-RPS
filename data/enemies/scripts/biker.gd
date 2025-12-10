extends "res://data/enemies/EnemyData.gd"

var is_dead: bool = false
var next_line: String = ""

# Dialogue sets
var dialogue := {
	"intro": {
		"default": [
			"'Name’s Mike Crum. I ride anything with wheels and destiny.'"
		],
		"discovered1": [
			"'You feel that breeze? That’s freedom breaking the speed limit.'",
			"'The mountain called me this morning.'",
			"'Where I’m going? Forward. Always forward.'"
			],
		},
	"battle": {
		"default": [
			"'My heartbeat is a national anthem.'",
			"'Justice rides shotgun. Determination drives.'",
			"'My legs could crush steel.'",
			"'I draft behind no one. Not even fate.'",
			"'I salute the sun everytime it rises.'"
		],
		"discovered1": [
			"'The wind fears me. The road respects me.'",
			"'Adrenaline is temporary. Glory is forever.'",
			"'Power comes from the quads, but truth comes from the heart.'"
		],
		"discovered2": [
			"'My motorcycle calls me ‘sir.’'",
			"'Let's take a quick round over the mountain."
		],
		"discovered3": [
			"'Victory is not a destination. It's a lifestyle.'"
		],
	},
	"death": {
		"default": [
			"'My last ride...'"
		],
		"discovered1": [
			"'My beloved bike...'"
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

func on_damage_taken(current_hp: int) -> void:
	if is_dead:
		return
	next_line = _get_line("battle")

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
