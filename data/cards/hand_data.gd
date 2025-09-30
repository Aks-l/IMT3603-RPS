extends Resource

class_name HandData

@export var id: int
@export var sprite: Texture2D
@export var name: String # desplays name, example "Rock"
@export var beats: Array[String] #what beats what

#how many copies of each card
#temporarily because max count will change
@export var max_count: int = 15
