extends Resource

class_name HandData

@export var id: int
@export var sprite: Texture2D
@export var name: String # desplays name, example "Rock"


#undiscovered by default
@export var discovered: bool = false

#how any cpies of each card
#temporarly because max count will change
@export var max_count: int = 3

#how many copies of each card
#temporarily because max count will change
#@export var max_count: int = 15
