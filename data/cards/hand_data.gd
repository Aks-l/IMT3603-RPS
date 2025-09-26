extends Resource

class_name HandData

@export var id: int
@export var sprite: Texture2D
@export var name: String # desplays name, example "Rock"
@export var beats: Array[String] #what beats what

#how any cpies of each card
#temporarly because max count will change
@export var max_count: int = 3
