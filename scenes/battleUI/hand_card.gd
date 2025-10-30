extends Control

signal clicked(hand: HandData)

var hand: HandData
var remaining: int = 0 

@onready var img: TextureRect = $VBoxContainer/Image
@onready var count_label: Label = $VBoxContainer/CountLabel

func setup(data: HandData, count: int) -> void:
	hand = data
	remaining = count

	print("HandCard setup:", hand.name)  # DEBUG
	print("Handcard setup size:", custom_minimum_size)

	# image setup
	img.texture = data.sprite
	
	img.mouse_filter = Control.MOUSE_FILTER_STOP
	img.gui_input.connect(_on_img_gui_input)
	_update_count()

#no longer mutates "remainging" parent decides waht to change
func _on_img_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(hand)
		print("Card clicked:", hand.name, "remaining: ", remaining) #DEBUG


func set_count(new_count: int) -> void:
	remaining = new_count
	_update_count()
	if remaining <= 0:
		queue_free()

func _update_count() -> void:
	if remaining > 1:
		count_label.text = "x" + str(remaining)
	else:
		count_label.text = ""
