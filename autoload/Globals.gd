extends Node

## Global containers
var inventory: Dictionary[HandData, int] = {}
var consumables: Array[ItemData] = []
var current_deck: Dictionary[HandData, int] = {}

func set_current_deck(deck: Dictionary[HandData, int]) -> void:
	current_deck = deck.duplicate(true)
	print("[Globals] Deck saved in memory:", current_deck)

func get_current_deck() -> Dictionary[HandData, int]:
	return current_deck

## Run-specific variables
var globalhealth: int = 3
var battlehealth: int = 5
var item_inventory_size: int = 4
var funds = 5

## Progress variables
var biome_levels_completed: int = 0
var run_levels_completed: int = 0
var total_levels_completed: int = 0

var run_biomes_completed: int = 0
var total_biomes_completed: int = 0
