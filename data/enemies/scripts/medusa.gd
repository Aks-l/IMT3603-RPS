extends "res://data/enemies/EnemyData.gd"

# Reference to your Rock card resource
@export var rock_card: HandData = preload("res://data/cards/rock.tres")

func react_to_card(card: HandData) -> void:
	if card == null:
		return
	
	if card.living:
		print("%s turns %s to stone!" % [name, card.name])
		petrify_card(card)
	else:
		print("%s is unaffected by %s's gaze." % [card.name, name])


func petrify_card(card: HandData) -> void:
	if rock_card == null:
		push_warning("Medusa tried to petrify, but no rock_card was assigned!")
		return

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
