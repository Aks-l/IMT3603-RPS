extends Control

func _on_almanac_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/almanac.tscn")
