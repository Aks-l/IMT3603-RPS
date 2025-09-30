extends Node3D

@onready var container: HBoxContainer = $HBoxContainer
@onready var fund_label: Label = $funds
const productCardScene: PackedScene = preload("res://scenes/shopScene/productCard.tscn")

var buyables: Array[ItemData] = []
var num_buyables: int = 3

func _ready():
	get_random_shop_items()
	populate_shop()
	fund_label.text = str(Globals.funds)
func populate_shop():
	for entry in buyables:
		var shopEntry = productCardScene.instantiate()
		container.add_child(shopEntry)
		shopEntry.populate(entry)
		shopEntry.on_purchase.connect(refresh_after_purchase)

func get_random_shop_items():
	for i in num_buyables:
		buyables.append(ItemDatabase.items.values().pick_random())
	
func refresh_after_purchase(_item):
	fund_label.text = str(Globals.funds)
