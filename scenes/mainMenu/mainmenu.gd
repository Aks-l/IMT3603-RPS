extends Control

func _ready() -> void:
	# If returning from game over, clean up lingering scenes
	if Globals.has_meta("returning_from_game_over"):
		Globals.remove_meta("returning_from_game_over")
		_cleanup_overlays()

func _cleanup_overlays() -> void:
	var root = get_tree().root
	# Remove battle UI and map if they still exist
	var battle_ui = root.get_node_or_null("BattleUI")
	if battle_ui:
		battle_ui.queue_free()
	var map = root.get_node_or_null("map")
	if map:
		map.queue_free()

func _on_almanac_pressed() -> void:
	AlmanacOverlay._show_overlay()

func _on_play_pressed() -> void:
	Globals.reset_run()
	
	Globals.inventory.clear()
	Globals.inventory[HandDatabase.hands[9]] = 5
	Globals.inventory[HandDatabase.hands[60]] = 5
	Globals.inventory[HandDatabase.hands[17]] = 5
	
	Globals.current_deck = Globals.inventory.duplicate(true)
	
	get_tree().change_scene_to_file("res://scenes/map/map.tscn")
