extends Node

signal encounter_finished(result)

const SCENES := { #TODO:Add scenes for different encounter types
	"Combat": preload("res://scenes/battleUI/battle_ui.tscn"),
	"Boss": preload("res://scenes/battleUI/battle_ui.tscn"),
	"Shop": preload("res://scenes/shopScene/shop.tscn"),
	"Event": preload("res://scenes/eventScene/event_ui.tscn"),
	"DeckCreator": preload("res://scenes/DeckCreater/deck_creater.tscn")
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

	#Special handling for different encounter types
	if encounter.has_method("setup"):
		var enemy := params.get("enemy") as EnemyData
		var hand := params.get("hand", []) as Dictionary[HandData, int]
		var consumables := params.get("consumables", []) as Array
		encounter.call("setup", enemy, hand, consumables)
	
	if encounter.has_method("display_event"):
		var event = params.get("event")
		if event:
			encounter.call("display_event", event)
			
			#Connect to event_completed signal to handle combat chaining
			if encounter.has_signal("event_completed"):
				encounter.event_completed.connect(func(result: Dictionary):
					print("[EncounterHandler] Event completed with result: ", result)
					
					#Check if combat should be triggered
					if result.get("triggers_combat", false):
						var enemy_data = result.get("enemy")
						if enemy_data:
							print("[EncounterHandler] Triggering combat with: ", enemy_data.name)
							#Combat will start after event UI is freed
							await encounter.tree_exited
							start_encounter("Combat", {
								"enemy": enemy_data,
								"hand": Globals.inventory,
								"consumables": Globals.consumables
							})
					
					#If chain event, start next event
					elif result.get("chain_event", false):
						var next_event_id = result.get("next_event_id", -1)
						if next_event_id >= 0:
							var next_event = EventDatabase.get_event(next_event_id)
							if next_event:
								print("[EncounterHandler] Chaining to next event: ", next_event.event_name)
								# Chain to next event after current UI is freed
								await encounter.tree_exited
								start_encounter("Event", {"event": next_event})
							else:
								push_warning("[EncounterHandler] Could not find next event with ID: ", next_event_id)
				)

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
	if not get_tree() or not get_tree().root:
		push_warning("[EncounterHandler] SceneTree not ready yet")
		return null
	return get_tree().root.get_node_or_null("map")
