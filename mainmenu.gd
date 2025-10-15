extends Control

func _on_almanac_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/almanac/almanac.tscn")

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/map/map.tscn")
	
	## Set up initial inventory and deck on startup
	Globals.inventory.clear()
	Globals.inventory[HandDatabase.hands[9]] = 5
	Globals.inventory[HandDatabase.hands[60]] = 5
	Globals.inventory[HandDatabase.hands[17]] = 5
	
	Globals.current_deck = Globals.inventory.duplicate(true)
	
#	map.name = "map"
#	get_tree().root.add_child(map)

#	(map.get_node("Cam") as Camera2D).make_current()
	
	# remove or hide the menu so it stops covering the screen
#	queue_free()            # <- replaces the menu entirely
	#hide()            # <- keep it in memory but invisible
