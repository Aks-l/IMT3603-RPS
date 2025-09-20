extends Resource
class_name EnemyData

@export var id: int
@export var sprite: Texture2D
@export var name: String
@export var description: String
@export var discovered: bool
@export var moveset: Array[HandData]   # assuming HandData is your card type

func get_hand() -> HandData:
	if moveset.is_empty():
		return Globals.hands[9999] # placeholder hand
	var played: HandData = moveset.pick_random()
	return played
