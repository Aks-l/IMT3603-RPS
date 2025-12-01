extends "res://data/enemies/EnemyData.gd"

# Cloudhead rusts metal/wood cards and can lose 1 HP once if you play Cloud.

@export var cloud_card_name := "Cloud" # Name of the Cloud card
var rusted_cards: Array[HandData] = []
var cloud_stolen_once := false
var max_hp := 3
var current_hp := max_hp

func on_combat_start(_hand: Array[HandData]) -> void:
	current_hp = max_hp
	cloud_stolen_once = false
	rusted_cards.clear()

	# Multiple feedback messages, no delays since EnemyData is a Resource
	emit_signal("feedback", "Cloudhead drifts into battle, humming softly…")
	emit_signal("feedback", "You feel moisture in the air — metal and wood will rust here.")
	emit_signal("feedback", "Play carefully, the storm remembers every move…")

func react_to_card(card: HandData) -> void:
	if card == null:
		return

	# Rust metal/wood cards
	if card.metalic or card.wood:
		if not ("rusted" in card.status_flags):
			card.status_flags["rusted"] = true
			card.status_revealed = true
			card.status_tint = Color(0.45, 0.35, 0.25) # muddy brown tint
			rusted_cards.append(card)

			emit_signal("feedback", "%s begins to rust in Cloudhead’s humid haze!" % card.name)
			emit_signal("update_hand_visuals", card)
		else:
			emit_signal("feedback", "%s is already rusted beyond use." % card.name)

	# Player plays Cloud — one-time HP drain
	elif card.name == cloud_card_name and not cloud_stolen_once:
		cloud_stolen_once = true
		current_hp -= 1
		current_hp = clamp(current_hp, 0, max_hp)

		emit_signal("feedback", "You harmonize with the storm! Cloudhead loses a heart!")
		emit_signal("feedback", "But the clouds darken — it won’t work again.")
	else:
		emit_signal("feedback", "Cloudhead watches your %s drift away in the wind." % card.name)

func modify_result(player: HandData, enemy: HandData, base_result: int) -> int:
	var result = base_result

	# Auto-lose if card is rusted
	if "rusted" in player.status_flags:
		emit_signal("feedback", "%s is too corroded to fight!" % player.name)
		result = -1

	return result

func on_damage_taken(current_hp: int) -> void:
	if current_hp <= 0:
		emit_signal("feedback", "Cloudhead sighs, fading into gentle drizzle…")
	else:
		emit_signal("feedback", "The air grows colder as Cloudhead hums a sad tune…")
