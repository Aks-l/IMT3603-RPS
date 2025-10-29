extends Control


func _on_almanac_pressed() -> void:
	AlmanacOverlay._show_overlay()

func _on_play_pressed() -> void:
	print("clicked map")
	## Set up initial inventory and deck on startup
	Globals.inventory.clear()
	Globals.inventory[HandDatabase.hands[9]] = 5
	Globals.inventory[HandDatabase.hands[60]] = 5
	Globals.inventory[HandDatabase.hands[17]] = 5
	
	Globals.current_deck = Globals.inventory.duplicate(true)
	
	get_tree().change_scene_to_file("res://scenes/map/map.tscn")
