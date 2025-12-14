extends "res://data/enemies/EnemyData.gd"

# Reference to your Rock card resource
@export var rock_card: HandData = preload("res://data/cards/rock.tres")

var has_petrified := false

func on_combat_start(players_cards: Array[HandData]) -> void:
	for card in players_cards:
		if card.living:
			has_petrified = true
			var original_name := card.name
			petrify_card(card)
			emit_signal(
				"feedback",
				"Turn to stone! %s has been petrified!" % original_name)
			return  # IMPORTANT: only petrify ONE card

func modify_result(player_card: HandData, enemy_card: HandData, result: int) -> int:
	if player_card.name == "medusa":
		return 0  # force tie

	return result


func react_to_card(card: HandData) -> void:
	if card == null:
		return
	
	if card.status_flags.get("petrified", false):
		emit_signal("feedback", "Throwing rocks?")
		return

func petrify_card(card: HandData) -> void:
	if rock_card == null:
		push_warning("Medusa tried to petrify, but no rock_card was assigned!")
		return
	
	card.status_flags["petrified"] = true
	card.status_revealed = true

	# Copy visual & metadata from the rock card
	card.name = rock_card.name
	card.sprite = rock_card.sprite
	card.living = false
	card.human = false
	card.dry = false
	card.aquatic = false
	card.land = false
	card.holy = false
	card.evil = false
	card.plant = false
	card.elemental = false
	card.metalic = true
	card.wood = false
	card.equal = false
	card.weird = false
	card.electric = false

	# Optional: Feedback
	print("%s has been petrified into a rock!" % card.name)
