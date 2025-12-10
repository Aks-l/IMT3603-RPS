extends "res://data/enemies/EnemyData.gd"

var is_dead: bool = false
var next_line: String = ""

# Dialogue sets
var dialogue := {
	"intro": {
		"default": [
			"'You may approach. I won’t get up, though.'",
			"'Yes, yes, greet me quickly. I'm very busy doing nothing.'"
		],
		"discovered1": [
			"'If you're looking for wisdom, come back after my nap. Or don’t.'",
			"'Yes, yes, greet me quickly. I'm very busy doing nothing.'",
			"'Someone fed me seven treats earlier. I deserved eight.'"
			],
		},
	"battle": {
		"default": [
			"'Do we have to? I'm very comfortable sitting here.'",
			"'My strategy is simple: exist gloriously.'",
			"'Don't expect much.'",
			"'If I beat you, I want someone to carry me home.'",
			"'No, you cannot pet me.'"
		],
		"discovered1": [
			"'Don’t worry, I always look this magnificent.'",
			"'If I beat you, I want someone to carry me home.'",
			"'You better stay away from my fishes'"
		],
		"discovered2": [
			"'I guide the universe by simply existing. You're welcome.'",
			"'HMMMMmmmm...zzzzz'"
		],
		"discovered3": [
			"'I have to leave for a party.'",
			"'Glutteny is waiting.'"
		],
	},
	"death": {
		"default": [
			"'Ugh. Effort was my downfall.'"
		],
		"discovered1": [
			"'Put me somewhere soft, at least.'",
			"'Mmmmm, eternal sleep...'"
		],
		"discovered3": [
			"'Don't eat me."
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
