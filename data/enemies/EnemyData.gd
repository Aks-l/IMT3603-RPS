extends Resource
class_name EnemyData

signal feedback(message: String)

@export var id: int
@export var sprite: Texture2D
@export var name: String
@export var description: String
@export var discovered: bool = false
@export var biome: String = "neutral"
#for difficulty
@export var tier: int = 1 #1 er tidlig, 2 is mid, and 3 is last biome 

#Dictionary of HandData, number of copies
@export var deck: Dictionary = {}

#internal working deck, this is used during battle
var current_deck: Array[HandData] = []

#deck handeling
func ready():
	reset_deck()

func reset_deck():
	current_deck.clear()
	for card in deck.keys():
		var count = deck[card]
		for i in count:
			current_deck.append(card)
	current_deck.shuffle()

func get_hand() -> HandData:
	if current_deck.is_empty():
		reset_deck()
	
	if current_deck.is_empty():
		push_warning("%s has no cards in deck" % name)
		return null
	
	return current_deck.pop_back()


#defines how enemies reacts to played cards
#this is overwritten persinally for enemy if script is assigned
func react_to_card(card: HandData) -> void:
	if card == null:
		return
	print("%s ignores %s." % [name, card.name])

#allows special enemies to change the result.
#only counts for the ruslt of the round, not the battle itself
func modify_result(player_card: HandData, enemy_card: HandData, base_result: int) -> int:
	return base_result  # default: do nothing
