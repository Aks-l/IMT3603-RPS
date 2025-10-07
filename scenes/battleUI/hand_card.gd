extends Control

signal clicked(hand: HandData)

var hand: HandData
var remaining: int = 0 #track how many are left

@onready var img: TextureRect = $VBoxContainer/Image
@onready var count_label: Label = $VBoxContainer/CountLabel

const CARD_SIZE  := Vector2(160, 220)
const IMAGE_SIZE := Vector2(144, 144)

func setup(data: HandData, count: int) -> void:
	hand = data
	remaining = count
	custom_minimum_size = CARD_SIZE
	print("HandCard setup:", hand.name)  # DEBUG
	print("Handcard setup size:", custom_minimum_size)

	# card sizing
	custom_minimum_size = CARD_SIZE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical   = Control.SIZE_SHRINK_CENTER

	# image setup
	img.texture = data.sprite
	img.custom_minimum_size = IMAGE_SIZE
	img.size_flags_horizontal = Control.SIZE_FILL
	img.size_flags_vertical   = Control.SIZE_FILL
	img.ignore_texture_size = true
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	img.mouse_filter = Control.MOUSE_FILTER_STOP
	img.gui_input.connect(_on_img_gui_input)
	_update_count()

#no longer mutates "remainging" parent decides waht to change
func _on_img_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(hand)
		
		#	if remaining > 0:
	#		remaining -= 1
	#		_update_count()
	#		clicked.emit(hand)
	#		if remaining <= 0:
	#			queue_free()
	#	print("Card clicked:", hand.name, "remaining: ", remaining) #DEGUB

	#	if remaining > 0:
	#		remaining -= 1
	#		_update_count()
	#		clicked.emit(hand)
	#		if remaining <= 0:
	#			queue_free()
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
