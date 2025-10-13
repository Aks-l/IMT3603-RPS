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
@export var moveset: Array[HandData]   # assuming HandData is your card type
@export var fixed_moveset: Array[HandData] = [] #exact hands enemy has access to
@export var weighted_moveset: Dictionary = {}

@export var reactions: Dictionary = {}

#spesiell logic, kan brukes senere, trengs ikke
#@export var ai_script: String = ""



func get_hand(last_player_card: HandData = null) -> HandData:
	#priority 1: check for reaction trigger
	if last_player_card:
		var reaction_key := "player_used:%d" % last_player_card.id
		if reactions.has(reaction_key) and Globals.hands.has(reactions[reaction_key]):
			return Globals.hands[reactions[reaction_key]]
			
	#priority 2: pick from fixed set
	if not fixed_moveset.is_empty():
		return fixed_moveset.pick_random()
	
	#priority 3: weighted draw
	if not weighted_moveset.is_empty():
		var roll := randf()
		var cumulative := 0.0
		for card_id in weighted_moveset.keys():
			cumulative += weighted_moveset[card_id]
			if roll <= cumulative and Globals.hands.has(card_id):
				return Globals.hands[card_id]
	if moveset.is_empty():
		return Globals.hands[9999] # placeholder hand
	var played: HandData = moveset.pick_random()
	return played
