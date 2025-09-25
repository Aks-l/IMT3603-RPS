extends Control

func _on_almanac_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/almanac/almanac.tscn")

func _on_play_pressed() -> void:
	var map := preload("res://scenes/map/map.tscn").instantiate()

	get_tree().root.add_child(map)

	(map.get_node("Cam") as Camera2D).make_current()
	
	# remove or hide the menu so it stops covering the screen
	queue_free()            # <- replaces the menu entirely
	#hide()            # <- keep it in memory but invisible
