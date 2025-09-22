class_name tempItemInvSlot
extends PanelContainer

@export var type: tempItems.Type

func init(t: tempItems.Type, cms: Vector2) -> void:
	type = t
	custom_minimum_size = cms
