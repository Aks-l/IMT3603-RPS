extends Node

var inventory: Dictionary[HandData, int] = {}
var consumables: Array[ItemData] = []
var funds: int = 2

var current_deck: Dictionary[HandData, int] = {}

func set_current_deck(deck: Dictionary[HandData, int]) -> void:
	current_deck = deck.duplicate(true)
	print("[Globals] Deck saved in memory:", current_deck)

func get_current_deck() -> Dictionary[HandData, int]:
	return current_deck
