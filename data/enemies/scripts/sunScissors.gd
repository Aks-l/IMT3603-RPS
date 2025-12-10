extends "res://data/enemies/EnemyData.gd"

var is_dead: bool = false
var next_line: String = ""

# Dialogue sets
var dialogue := {
	"intro": {
		"default": [
			"'Stay low… the light might follow us here.'",
			"'Don’t let the Sun hear us whisper.'",
			"'Shadows move safer together… I think.'"
		],
		"discovered1": [
			"'Some say the Sun forgets… I don’t believe them.'",
			"'The light chases everything… even what hides.'",
			"'I learned long ago: never trust the warmth.'"
			]
		},
	"battle": {
		"default": [
			"'Keep the light away from me.'",
			"'Don’t let reflections form…'",
			"'Run if you see a glint above us.'"
		],
		"discovered1": [
			"'Every clash echoes… the Sun loves echoes.'",
			"'Shadows tremble when steel meets air.'",
			"'Strike softly… noise attracts attention.'"
		],
		"discovered2": [
			"'The Sun once forged me… now it hunts me.'",
			"'I still remember the burn beneath my edge.'",
			"'Every battle feels like the moment I fled the light.'"
		],
	},
	"death": {
		"default": [
			"'Not inyo the light.'"
		],
		"discovered1": [
			"'Could have been worse.'",
			"'I die free.'"
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
