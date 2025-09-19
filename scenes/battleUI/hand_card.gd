extends Control

signal clicked(hand: HandData)

var hand: HandData

@onready var img: TextureRect = $VBoxContainer/Image
const CARD_SIZE  := Vector2(160, 220)
const IMAGE_SIZE := Vector2(144, 144)

func setup(data: HandData) -> void:
	hand = data

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

func _ready() -> void:
	img.mouse_filter = Control.MOUSE_FILTER_STOP
	img.gui_input.connect(_on_img_gui_input)

func _on_img_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(hand)
