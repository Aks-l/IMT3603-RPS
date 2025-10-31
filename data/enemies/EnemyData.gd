extends Resource
class_name EnemyData


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
