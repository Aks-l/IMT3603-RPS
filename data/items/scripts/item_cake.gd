extends Node

static func purchased(item:ItemData):
	pass

static func used(item: ItemData) -> void:
	print("used %s" % item.name)

static func carried(item: ItemData):
	pass
