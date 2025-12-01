##Configuration for terrain noise generation
class_name NoiseSettings
extends Resource

@export var seed_offset: int = 0
@export var frequency: float = 0.1
@export var octaves: int = 1
@export_enum("Simplex", "Perlin", "Cellular") var noise_type_name: String = "Simplex"

func create_noise() -> FastNoiseLite:
	var n = FastNoiseLite.new()
	n.seed = randi() + seed_offset
	n.frequency = frequency
	
	match noise_type_name:
		"Simplex":
			n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		"Perlin":
			n.noise_type = FastNoiseLite.TYPE_PERLIN
		"Cellular":
			n.noise_type = FastNoiseLite.TYPE_CELLULAR
	
	if octaves > 1:
		n.fractal_octaves = octaves
	
	return n
