extends Node

static func purchased(item: ItemData):
	print("purchased %s"%item.name)
	pass

static func used(item: ItemData):
	print("used %s"%item.name)
	pass

static func carried(item: ItemData):
	print("carried %s"%item.name)
	pass
