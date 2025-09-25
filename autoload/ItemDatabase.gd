extends Node

var items: Dictionary = {}

func load_enemies():
	var dir = DirAccess.open("res://data/items")
	if dir:
		for file in dir.get_files():
			if file.ends_with(".tres"):
				var item = load("res://data/items/" + file)
				if item and item is ItemData:
					items[item.id] = item

func _ready():
	load_enemies()
	add_items()
	
func add_items():
	Globals.consumables.append(items[0])
