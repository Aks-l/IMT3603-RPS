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

func _ready() -> void:
	reset_run()

func take_damage(amount: int = 1) -> void:
	health = max(0, health - amount)
	health_changed.emit(health)
	print("[Globals] Health reduced to: ", health)
	
	if health <= 0:
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
	print("[Globals] Run reset - Health: ", health, ", Funds: ", funds)

func set_current_deck(deck: Dictionary[HandData, int]) -> void:
	current_deck = deck.duplicate(true)
	print("[Globals] Deck saved in memory:", current_deck)

func get_current_deck() -> Dictionary[HandData, int]:
	return current_deck
