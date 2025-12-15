extends Control

@onready var play_button = $MarginContainer/HBoxContainer/VBoxContainer/Play
@onready var continue_button = $MarginContainer/HBoxContainer/VBoxContainer/Continue

func _ready() -> void:
	# If returning from game over, clean up lingering scenes
	if Globals.has_meta("returning_from_game_over"):
		Globals.remove_meta("returning_from_game_over")
		_cleanup_overlays()
	
	# Update button visibility based on save file
	_update_menu_buttons()

func _update_menu_buttons() -> void:
	# Wait for SaveSystem to be ready
	await get_tree().process_frame
	
	if SaveSystem.has_save():
		play_button.text = "New Game"
		if continue_button:
			continue_button.visible = true
	else:
		play_button.text = "Play"
		if continue_button:
			continue_button.visible = false

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

func _on_continue_pressed() -> void:
	# Load will happen automatically in SaveSystem._ready()
	# but we can trigger it explicitly to be sure
	await SaveSystem.load_game()
	get_tree().change_scene_to_file("res://scenes/map/map.tscn")

func _on_play_pressed() -> void:
	# If save exists, ask for confirmation
	if SaveSystem.has_save():
		_show_new_game_confirmation()
	else:
		_start_new_game()

func _show_new_game_confirmation() -> void:
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "Starting a new game will delete your current save. Continue?"
	dialog.title = "New Game"
	dialog.ok_button_text = "Start New Game"
	
	# Add Cancel button
	var cancel_button = dialog.add_cancel_button("Cancel")
	
	dialog.confirmed.connect(func():
		_start_new_game()
		dialog.queue_free()
	)
	
	cancel_button.pressed.connect(func():
		dialog.queue_free()
	)
	
	add_child(dialog)
	dialog.popup_centered()

func _start_new_game() -> void:
	# Delete existing save
	SaveSystem.delete_save()
	
	# Reset everything
	Globals.reset_run()
	
	# Clear all discovered states for new game
	for enemy in EnemyDatabase.enemies.values():
		enemy.discovered = false
	for hand in HandDatabase.hands.values():
		hand.discovered = false
	for biome in BiomeDatabase.biomes.values():
		biome.discovered = false
		biome.encountered = false
	
	# Set up starting deck
	Globals.inventory.clear()
	Globals.inventory[HandDatabase.hands[9]] = 5
	Globals.inventory[HandDatabase.hands[60]] = 5
	Globals.inventory[HandDatabase.hands[17]] = 5
	
	Globals.current_deck = Globals.inventory.duplicate(true)
	
	get_tree().change_scene_to_file("res://scenes/map/map.tscn")
