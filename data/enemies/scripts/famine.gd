extends "res://data/enemies/EnemyData.gd"

# Famine instantly makes living cards useless (auto-lose).

var starve_lines := [
	"'You should have eaten at home!'",
	"'Hollow... empty... how fitting.'",
	"'The body fails long before the spirit.'",
	"'I only take what is already fading.'",
]

var reject_lines := [
	"'You have too much meat on your bones.'",
	"'You cling to vitality. How quaint.'",
]

var already_starved_lines := [
	"'%s has nothing more to give.'",
	"'I pity your frail attempt.'",
]


func react_to_card(card: HandData) -> void:
	if card == null:
		return

	if card.living:
		starve_card(card)
	else:
		_maybe_say(reject_lines, card)


func starve_card(card: HandData) -> void:
	# If already starved, just silently let modify_result handle the auto-lose line.
	if "starved" in card.status_flags:
		return

	card.status_flags["starved"] = true
	card.status_revealed = true
	card.status_tint = Color(0.3, 0.6, 0.2) # green

	emit_signal("update_hand_visual", card)
	_maybe_say(starve_lines, card)


func modify_result(card: HandData, enemy: HandData, base_result: int) -> int:
	if "starved" in card.status_flags:
		_maybe_say(already_starved_lines, card)
		return -1
	
	return base_result


func _maybe_say(lines: Array, card: HandData) -> void:
	# 20% chance to say nothing
	if randi() % 100 < 20:
		return
	
	var line = lines.pick_random()
	
	if line.find("%s") != -1:
		line = line % card.name
	
	emit_signal("feedback", line)
