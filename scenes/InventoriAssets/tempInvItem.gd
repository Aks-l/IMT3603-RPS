class_name tempInvItem
extends TextureRect

@export var data: ItemData


func init (d: ItemData) -> void:
	data = d
	
func _ready():
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture = data.sprite
	tooltip_text = "%s\n%s" % [data.name, data.description]

signal item_used(data: ItemData)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("item_used", data)
