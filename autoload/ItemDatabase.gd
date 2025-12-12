extends Node

var items: Dictionary = {}

func load_items():
	var dir = DirAccess.open("res://data/items")
	if dir:
		for file in dir.get_files():
			if file.ends_with(".tres"):
				var item = load("res://data/items/" + file)
				if item and item is ItemData:
					items[item.id] = item

func _ready():
	load_items()
