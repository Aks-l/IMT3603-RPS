extends Control
signal on_purchase(item: ItemData)

@onready var vbox = $VBoxContainer
@onready var image_container = $VBoxContainer/Image
@onready var item_label = $VBoxContainer/Item_Label
@onready var price_label = $VBoxContainer/Price_Label

var item: ItemData

func _ready():
	custom_minimum_size = Vector2(220, 280)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 0
	vbox.offset_top = 0
	vbox.offset_right = 0
	vbox.offset_bottom = 0
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL

func populate(data: ItemData):
	item = data
	image_container.texture = data.sprite
	item_label.text = data.name
	price_label.text = "Price: " + str(data.price)
	
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Globals.consumables.size() >= Globals.item_inventory_size:
			push_warning("No space in inventory")
		if Globals.funds >= item.price:
			print(item.name + " was bought")
			Globals.consumables.append(item)
			Globals.funds -= item.price
			emit_signal("on_purchase", item)
			queue_free()
