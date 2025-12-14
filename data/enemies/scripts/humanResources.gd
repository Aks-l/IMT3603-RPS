extends "res://data/enemies/EnemyData.gd"


# --- Attributes ---
@export var living := true
@export var human := true
@export var concept := true
@export var evil := true
@export var metalic := true
@export var land := true
@export var weird := true

#Internal state
var _current_policy: Dictionary = {}
var _disabled_tags: Array[String] = []
var _players_cards: Array[HandData] = []
var _policy_announced: bool = false
var _policy_displayed: bool = false
var is_dead: bool = false

var dialogue := {
	"death": [
		"'The exit interview is... eternal.'",
		"'We're downsizing... including me.'",
		"'My contract... has been terminated.'"
	],
}

#  Called once when combat starts 
func on_combat_start(players_cards: Array[HandData]) -> void:
	_players_cards = players_cards
	_policy_announced = false
	_policy_displayed = false
	is_dead = false
	# Announce the first policy at battle start (with slight delay for UI to be ready)
	print("Combat started, setting initial policy...")
	_set_random_policy()

# Called each time the player plays a card 
func react_to_card(card: HandData) -> void:
	if is_dead:
		return
	
	# Don't announce policy here - it's already been announced
	if card == null:
		return
	
	# Check if the card is blocked by current policy
	for tag in _disabled_tags:
		var tag_value = card.get(tag)
		print("Checking tag '", tag, "' on card '", card.name, "': ", tag_value)
		if tag_value == true:
			# Card is banned, just show a reminder
			var msg = "Your " + card.name + " card is banned by the current policy!"
			emit_signal("feedback", msg)
			return

#  Change RPS result if card is disabled 
func modify_result(card: HandData, enemy_card: HandData, result: int) -> int:
	if card == null or is_dead:
		return result
	
	print("modify_result called - checking ", _disabled_tags.size(), " banned tags")
	print("Banned tags are: ", _disabled_tags)
	
	# Force loss if card matches banned tags
	for tag in _disabled_tags:
		var tag_value = card.get(tag)
		print("  Checking if '", card.name, "' has tag '", tag, "': ", tag_value)
		if tag_value == true:
			print("!!! POLICY VIOLATION: Card '", card.name, "' has banned tag '", tag, "' - forcing loss!")
			return -1  # auto lose if your card is "banned" this turn
	
	print("No policy violation detected, returning original result: ", result)
	return result

# called after each round ends
func on_round_end() -> void:
	if is_dead or _policy_announced:
		return
	# Announce new policy for the NEXT turn
	_set_random_policy()

func on_damage_taken(current_hp: int) -> void:
	if is_dead:
		return
	
	if current_hp <= 0:
		is_dead = true
		_policy_announced = true  # Prevent new policy from being announced
		_emit_death_line()
		return

func _emit_death_line() -> void:
	var l: String = dialogue["death"].pick_random()
	emit_signal("feedback", l)

# Internal: Select a new random policy
func _set_random_policy() -> void:
	var policies = [
		{
			"text": "If you can breathe, you can be used.",
			"tags": ["living"],
			"desc": "All living cards bend to the will of the corporation."
		},
		{
			"text": "There is no good or evil — only profit.",
			"tags": ["holy", "evil"],
			"desc": "Good and evil cards are suspended pending ethics review."
		},
		{
			"text": "Can this serve productivity?",
			"tags": ["electric", "metalic"],
			"desc": "Electric and metallic cards are deemed unproductive."
		},
		{
			"text": "We must optimize headcount.",
			"tags": ["human"],
			"desc": "Human cards are laid off."
		},
		{
			"text": "We value nature’s contribution... just not today.",
			"tags": ["plant", "wood"],
			"desc": "Plant and wooden cards are cut from the budget."
		},
		{
			"text": "There is no ground for excuses.",
			"tags": ["land", "airborne"],
			"desc": "Land and airborne cards are grounded."
		}
	]

	_current_policy = policies.pick_random()
	_disabled_tags.clear()
	for tag in _current_policy["tags"]:
		_disabled_tags.append(tag)

	var msg = "\"" + _current_policy["text"] + "\"\n" + _current_policy["desc"]
	emit_signal("feedback", msg)
	print("Policy announced: ", _current_policy["desc"])
