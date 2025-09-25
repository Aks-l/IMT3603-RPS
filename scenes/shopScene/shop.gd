extends Node3D

@onready var container: HBoxContainer = $HBoxContainer
const productCardScene: PackedScene = preload("res://scenes/shopScene/productCard.tscn")

var buyables: Array[ItemData] = []
var num_buyables: int = 3

func _ready():
	get_random_shop_items()
	populate_shop()

func populate_shop():
	for entry in buyables:
		var shopEntry = productCardScene.instantiate()
		shopEntry.populate(entry)
		container.add_child(shopEntry)

func get_random_shop_items():
	for i in num_buyables:
		buyables.append(Globals.consumables.pick_random())
