extends Resource
class_name EnemyData

@export var id: String
@export var sprite: Texture2D
@export var loses_to: Array[String] = []
@export var wins_over: Array[String] = []
@export var description: String
