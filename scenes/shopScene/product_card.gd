extends Control

@onready var vbox = $VBoxContainer
@onready var image_container = $VBoxContainer/Image
@onready var item_label = $VBoxContainer/Item_Label

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
	image_container.texture = data.sprite
	item_label.text = data.name
	
