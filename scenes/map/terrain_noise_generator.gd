##Manages multiple noise generators for terrain generation
class_name TerrainNoiseGenerator
extends Node

@export_group("Noise Configuration")
@export var base_noise_frequency: float = 0.15
@export var elevation_frequency: float = 0.004
@export var elevation_octaves: int = 4
@export var detail_frequency: float = 0.12
@export var edge_frequency: float = 0.01
@export var edge_octaves: int = 3
@export var continent_frequency: float = 0.008
@export var continent_octaves: int = 3

var noise: FastNoiseLite
var elevation_noise: FastNoiseLite
var detail_noise: FastNoiseLite
var edge_noise: FastNoiseLite
var continent_noise: FastNoiseLite

func _ready() -> void:
	_initialize_noise_generators()

func _initialize_noise_generators() -> void:
	noise = _create_noise(0, base_noise_frequency, 1, FastNoiseLite.TYPE_SIMPLEX_SMOOTH)
	elevation_noise = _create_noise(1000, elevation_frequency, elevation_octaves, FastNoiseLite.TYPE_PERLIN)
	detail_noise = _create_noise(2000, detail_frequency, 1, FastNoiseLite.TYPE_PERLIN)
	edge_noise = _create_noise(3000, edge_frequency, edge_octaves, FastNoiseLite.TYPE_PERLIN)
	continent_noise = _create_noise(4000, continent_frequency, continent_octaves, FastNoiseLite.TYPE_PERLIN)

func _create_noise(seed_offset: int, freq: float, octaves: int = 1, type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH) -> FastNoiseLite:
	var n = FastNoiseLite.new()
	n.seed = randi() + seed_offset
	n.frequency = freq
	n.noise_type = type
	if octaves > 1:
		n.fractal_octaves = octaves
	return n

##Reinitialize with new seed
func regenerate() -> void:
	_initialize_noise_generators()
