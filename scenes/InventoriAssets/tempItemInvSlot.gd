class_name tempItemInvSlot
extends PanelContainer

@export var type: ItemData.Type

func init(t: ItemData.Type, cms: Vector2) -> void:
	type = t
	custom_minimum_size = cms
