extends Control
signal on_purchase(item: ItemData)

@onready var vbox = $VBoxContainer
@onready var image_container = $VBoxContainer/Image
@onready var item_label = $VBoxContainer/Item_Label
@onready var price_label = $VBoxContainer/Price_Label

var item: ItemData

func _ready():
	custom_minimum_size = Vector2(220, 280)

func populate(data: ItemData):
	item = data
	image_container.texture = data.sprite
	item_label.text = data.name
	price_label.text = "Price: " + str(data.price)
	
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:

		if Globals.consumables.size() >= Globals.item_inventory_size:
			push_warning("No space in inventory")
			return
			

		if Globals.spend_funds(item.price):
			print(item.name + " was bought")
			if item.item_script:
				item.item_script.call("purchased", item)

			Globals.consumables.append(item)
			emit_signal("on_purchase", item)
			queue_free()
