class_name tempInvItem
extends TextureRect

@export var data: ItemData
signal item_used(data: ItemData)

func init(d: ItemData) -> void:
	data = d
	if is_inside_tree():
		_apply_data()

func _ready() -> void:
	if data:
		_apply_data()

func _apply_data() -> void:
	texture = data.sprite
	tooltip_text = "%s\n%s" % [data.name, data.description]
	# Make sure it scales nicely inside the slot
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	size_flags_horizontal = Control.SIZE_FILL
	size_flags_vertical = Control.SIZE_FILL

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.pressed \
	and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("item_used", data)
