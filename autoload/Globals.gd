extends Node

signal health_changed(new_health: int)
signal funds_changed(new_funds: int)
signal game_over()

const MAX_HEALTH = 3
const STARTING_FUNDS = 2

var health: int = MAX_HEALTH
var inventory: Dictionary[HandData, int] = {}
var consumables: Array[ItemData] = []
var funds: int = STARTING_FUNDS

var current_deck: Dictionary[HandData, int] = {}

## Run-specific variables
var globalhealth: int = 3
var battlehealth: int = 5
var item_inventory_size: int = 4
var current_biome: BiomeData

var card_inventory_amount_size: int = 15
var card_inventory_type_size: int = 5

## Progress variables
var biome_levels_completed: int = 0
var run_levels_completed: int = 0
var total_levels_completed: int = 0

var run_biomes_completed: int = 0
var total_biomes_completed: int = 0

func _ready() -> void:
	reset_run()

func take_damage(amount: int = 1) -> void:
	health = max(0, health - amount)
	health_changed.emit(health)
	print("[Globals] Health reduced to: ", health)
	
	if health <= 0:
		# Emit deferred to avoid synchronous handlers running while the tree may be paused
		call_deferred("_emit_game_over")

# Deferred emitter so receivers run after current frame / pause state resolves
func _emit_game_over() -> void:
	game_over.emit()
	print("[Globals] Game Over - No health remaining")


func heal(amount: int = 1) -> void:
	health = min(MAX_HEALTH, health + amount)
	health_changed.emit(health)
	print("[Globals] Health increased to: ", health)

func add_funds(amount: int) -> void:
	funds += amount
	funds_changed.emit(funds)
	print("[Globals] Funds changed to: ", funds)

func spend_funds(amount: int) -> bool:
	if funds >= amount:
		funds -= amount
		funds_changed.emit(funds)
		print("[Globals] Spent ", amount, " funds. Remaining: ", funds)
		return true
	return false

func reset_run() -> void:
	health = MAX_HEALTH
	funds = STARTING_FUNDS
	inventory.clear()
	consumables.clear()
	current_deck.clear()
	health_changed.emit(health)
	funds_changed.emit(funds)
	run_levels_completed = 0
	biome_levels_completed = 0
	run_biomes_completed = 0
	for b in BiomeDatabase.biomes.values(): b.encountered = false
	print("[Globals] Run reset - Health: ", health, ", Funds: ", funds)

func set_current_deck(deck: Dictionary[HandData, int]) -> void:
	current_deck = deck.duplicate(true)
	print("[Globals] Deck saved in memory:", current_deck)

func get_current_deck() -> Dictionary[HandData, int]:
	return current_deck
