extends Node

var biomes: Dictionary[int, BiomeData] = {}

func load_biomes():
	var dir = DirAccess.open("res://data/biomes")
	if dir:
		for file in dir.get_files():
			if file.ends_with(".tres"):
				var biome = load("res://data/biomes/" + file)
				if biome and biome is BiomeData:
					biomes[biome.id] = biome

func _ready():
	load_biomes()
	print(biomes.size())
