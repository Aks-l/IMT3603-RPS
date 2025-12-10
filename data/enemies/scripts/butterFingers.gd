extends "res://data/enemies/EnemyData.gd"


var is_dead: bool = false
var next_line: String = ""

# Dialogue sets
var dialogue := {
	"intro": {
		"default": [
			"'Oh! A visitor. Careful, the floor is warm.'",
			"'I’ve been kneading since sunrise… or was it yesterday?'",
			"'Sit, sit — the dough rises better with company.'"
		],
		"discovered1": [
			"'The morning smelled like cinnamon today. Good omen.'",
			"'Is it windy today? My dough hates wind.'",
			"'Christopher said he would bring more raspberries today.'"
			],
		},
	"battle": {
		"default": [
			"'If flour spills out of my sleeves, pretend you didn’t see.'",
			"'Don’t mind me, I’m just thinking about dough hydration.'",
			"'Pink is such a nice colour.'"
		],
		"discovered1": [
			"'If I win, remind me to check the oven. If I lose, remind me anyway.'",
			"'Have you been by the beach, yet?'",
			"'Careful— I sharpened my knives for baking, not battling.'",
			"'Someone painted hearts on my storefront last night. I didn't remove them.'",
		],
		"discovered2": [
			"'If you see Karen, tell her she isn't welcome here.'",
			"'Keep it quick, I need to finish these cupcakes.'",
			"'My apron keeps getting in the way… I really should hem it.'",
			"'Children keep asking if the bakery is enchanted. I tell them: only on weekends.'"
		],
	},
	"death": {
		"default": [
			"'At least I won’t burn anything anymore."
		],
		"discovered1": [
			"'Leave the apron. It’s seen enough.'",
			"'INo.. my macrons.'"
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
	
	##differemt line if player usees the sun card
	if card.name == "sun":
		emit_signal("feedback", "AAAAaaaa... oh, i thought it was her.")
		next_line = ""
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
