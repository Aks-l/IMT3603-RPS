extends Node

signal encounter_finished(result)

const SCENES := { #TODO:Add scenes for different encounter types
	"Combat": preload("res://scenes/battleUI/battle_ui.tscn"),
	"Boss": preload("res://scenes/battleUI/battle_ui.tscn"),
	"Shop": preload("res://scenes/shopScene/shop.tscn")
}

##Starts encounter
## 	Hides map, sets up an encounter and waits for it to finish
##	If an unimplemented encounter type is encountered, it is skipped
func start_encounter(encounter_type: String, params: Dictionary = {}) -> void:
	var map := _find_map()
	if map:
		map.hide()


	if not SCENES.has(encounter_type):
		push_warning("Encounter type '%s' not implemented. Skipping." % encounter_type)
		if map:
			map.show()
			var map_cam := map.get_node_or_null("Cam")
			if map_cam:
				map_cam.make_current()
		emit_signal("encounter_finished", {"type": encounter_type, "skipped": true})
		return

	# Combat encounter
	var scene: PackedScene = SCENES[encounter_type]
	var encounter := scene.instantiate()
	get_tree().root.add_child(encounter)

	var cam := encounter.get_node_or_null("Camera2D")
	if cam:
		cam.make_current()

	if encounter.has_method("setup"):
		var enemy := params.get("enemy") as EnemyData
		var hand := params.get("hand", []) as Dictionary[HandData, int]
		var consumables := params.get("consumables", []) as Array
		encounter.call("setup", enemy, hand, consumables)

	#Returns to map when signal is received
	encounter.tree_exited.connect(func ():
		var map_node := _find_map()
		if map_node:
			map_node.show()
			var map_cam := map_node.get_node_or_null("Cam")
			if map_cam:
				map_cam.make_current()
		emit_signal("encounter_finished", {"type": encounter_type, "skipped": false})
	)

##Function to find and return map node, if not found it returns null
func _find_map() -> Node:
	return get_tree().root.get_node_or_null("map")
