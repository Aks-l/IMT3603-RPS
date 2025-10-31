extends Resource

class_name HandData

@export var id: int
@export var sprite: Texture2D
@export var name: String

@export var discovered: bool = false

#how many copies of each card
#temporarily because max count will change
@export var max_count: int = 3

@export var living: bool #a living being (not plants)
@export var aquatic: bool #lives in water
@export var dry: bool #cannot suriveve under water (drowns)
@export var holy: bool #objectivly good being
@export var concept: bool #objectiv concept
@export var evil: bool #objectivly bad being
@export var plant: bool #plants and flora
@export var elemental: bool #natural elements
@export var metalic: bool #(partially) made of metal
@export var airborne: bool #flies, is able to be in the air, is in the ari
@export var land: bool #lives on land
@export var weird: bool #uncatogarizalbe
@export var wood: bool #(partially) made of wood
@export var electric: bool #electric, made of electricity, need electricity to function
@export var equal: bool #some enemies are similar to hands, puts them in tie


#how many copies of each card
#temporarily because max count will change
#@export var max_count: int = 15
