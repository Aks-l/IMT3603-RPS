extends Resource
class_name BiomeData

@export_group("Metadata")
@export var id: int
@export var name: String
@export var prefix: String
@export var difficulty: int
@export var discovered: bool = false
@export var encountered: bool = false # prevent encountering same biome twice in one run

@export_group("Color palette")
@export var ocean_color: Color 
@export var shallow_water_color: Color 
@export var sand_color: Color 
@export var grass_color: Color 
@export var forest_color: Color 
@export var hill_color: Color 
@export var mountain_color: Color 
@export var snow_color: Color 
