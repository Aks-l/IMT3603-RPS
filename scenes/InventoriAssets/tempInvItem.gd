class_name tempInvItem
extends TextureRect

@export var data: tempItems


func init (d: tempItems) -> void:
	data = d
	
func _ready():
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture = data.sprite
	tooltip_text = "%s\n%s" % [data.name, data.description]
