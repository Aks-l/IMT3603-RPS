extends Node

const SAVE_PATH = "user://savegame.save"
const AUTO_SAVE_ENABLED = true

# Auto-save triggers
signal save_completed
signal load_completed

func _ready() -> void:
	# Connect to key events for auto-saving
	if AUTO_SAVE_ENABLED:
		Globals.health_changed.connect(_on_auto_save_trigger)
		Globals.funds_changed.connect(_on_auto_save_trigger)
		EncounterHandler.encounter_finished.connect(_on_auto_save_trigger)
	
	# Attempt to load save on startup
	await load_game()

func _show_notification(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 24)
	label.modulate = Color(1, 1, 1, 1)
	label.position = Vector2(20, 20)
	label.z_index = 100
	
	get_tree().root.add_child(label)
	
	# Fade out animation
	var tween = get_tree().create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 2.0).set_delay(1.0)
	tween.tween_callback(label.queue_free)

func _on_auto_save_trigger(_param = null) -> void:
	save_game()

## Save all game progress
func save_game() -> bool:
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_datetime_string_from_system(),
		
		# Global state
		"health": Globals.health,
		"funds": Globals.funds,
		"globalhealth": Globals.globalhealth,
		"battlehealth": Globals.battlehealth,
		"item_inventory_size": Globals.item_inventory_size,
		"card_inventory_amount_size": Globals.card_inventory_amount_size,
		"card_inventory_type_size": Globals.card_inventory_type_size,
		
		# Progress
		"biome_levels_completed": Globals.biome_levels_completed,
		"run_levels_completed": Globals.run_levels_completed,
		"total_levels_completed": Globals.total_levels_completed,
		"run_biomes_completed": Globals.run_biomes_completed,
		"total_biomes_completed": Globals.total_biomes_completed,
		
		# Current biome
		"current_biome_id": Globals.current_biome.id if Globals.current_biome else -1,
		
		# Inventory and deck
		"inventory": _serialize_hand_dict(Globals.inventory),
		"current_deck": _serialize_hand_dict(Globals.current_deck),
		"consumables": _serialize_item_array(Globals.consumables),
		
		# Discovery states
		"discovered_enemies": _get_discovered_enemies(),
		"discovered_hands": _get_discovered_hands(),
		"discovered_biomes": _get_discovered_biomes(),
		"encountered_biomes": _get_encountered_biomes(),
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for writing: " + str(FileAccess.get_open_error()))
		return false
	
	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()
	
	print("[SaveSystem] Game saved successfully")
	save_completed.emit()
	return true

## Load game progress
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SaveSystem] No save file found - starting fresh")
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file for reading: " + str(FileAccess.get_open_error()))
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("Failed to parse save file: " + json.get_error_message())
		return false
	
	var save_data = json.get_data()
	if typeof(save_data) != TYPE_DICTIONARY:
		push_error("Invalid save data format")
		return false
	
	# Wait for databases to load
	await get_tree().process_frame
	
	# Restore global state
	Globals.health = save_data.get("health", Globals.MAX_HEALTH)
	Globals.funds = save_data.get("funds", Globals.STARTING_FUNDS)
	Globals.globalhealth = save_data.get("globalhealth", 3)
	Globals.battlehealth = save_data.get("battlehealth", 5)
	Globals.item_inventory_size = save_data.get("item_inventory_size", 4)
	Globals.card_inventory_amount_size = save_data.get("card_inventory_amount_size", 15)
	Globals.card_inventory_type_size = save_data.get("card_inventory_type_size", 5)
	
	# Restore progress
	Globals.biome_levels_completed = save_data.get("biome_levels_completed", 0)
	Globals.run_levels_completed = save_data.get("run_levels_completed", 0)
	Globals.total_levels_completed = save_data.get("total_levels_completed", 0)
	Globals.run_biomes_completed = save_data.get("run_biomes_completed", 0)
	Globals.total_biomes_completed = save_data.get("total_biomes_completed", 0)
	
	# Restore current biome
	var biome_id = save_data.get("current_biome_id", -1)
	if biome_id >= 0 and BiomeDatabase.biomes.has(biome_id):
		Globals.current_biome = BiomeDatabase.biomes[biome_id]
	
	# Restore inventory and deck
	Globals.inventory = _deserialize_hand_dict(save_data.get("inventory", {}))
	Globals.current_deck = _deserialize_hand_dict(save_data.get("current_deck", {}))
	Globals.consumables = _deserialize_item_array(save_data.get("consumables", []))
	
	# Restore discovery states
	_restore_discovered_enemies(save_data.get("discovered_enemies", {}))
	_restore_discovered_hands(save_data.get("discovered_hands", {}))
	_restore_discovered_biomes(save_data.get("discovered_biomes", {}))
	_restore_encountered_biomes(save_data.get("encountered_biomes", {}))
	
	# Emit signals to update UI
	Globals.health_changed.emit(Globals.health)
	Globals.funds_changed.emit(Globals.funds)
	
	print("[SaveSystem] Game loaded successfully from: ", save_data.get("timestamp", "unknown"))
	load_completed.emit()
	return true

## Delete save file
func delete_save() -> bool:
	if FileAccess.file_exists(SAVE_PATH):
		var err = DirAccess.remove_absolute(SAVE_PATH)
		if err == OK:
			print("[SaveSystem] Save file deleted")
			return true
		else:
			push_error("Failed to delete save file: " + str(err))
			return false
	return true

## Check if save file exists
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

# ===== HELPER FUNCTIONS =====

## Serialize HandData dictionary to saveable format
func _serialize_hand_dict(dict: Dictionary) -> Dictionary:
	var result = {}
	for hand in dict.keys():
		if hand is HandData:
			result[str(hand.id)] = dict[hand]
	return result

## Deserialize HandData dictionary from save format
func _deserialize_hand_dict(dict: Dictionary) -> Dictionary:
	var result: Dictionary[HandData, int] = {}
	for id_str in dict.keys():
		var id = int(id_str)
		if HandDatabase.hands.has(id):
			result[HandDatabase.hands[id]] = int(dict[id_str])
	return result

## Serialize ItemData array to saveable format
func _serialize_item_array(array: Array) -> Array:
	var result = []
	for item in array:
		if item is ItemData:
			result.append(item.id)
	return result

## Deserialize ItemData array from save format
func _deserialize_item_array(array: Array) -> Array[ItemData]:
	var result: Array[ItemData] = []
	for id in array:
		if ItemDatabase.items.has(id):
			result.append(ItemDatabase.items[id])
	return result

## Get discovered state of all enemies
func _get_discovered_enemies() -> Dictionary:
	var result = {}
	for id in EnemyDatabase.enemies.keys():
		var enemy: EnemyData = EnemyDatabase.enemies[id]
		result[str(id)] = enemy.discovered
	return result

## Get discovered state of all hands
func _get_discovered_hands() -> Dictionary:
	var result = {}
	for id in HandDatabase.hands.keys():
		var hand: HandData = HandDatabase.hands[id]
		result[str(id)] = hand.discovered
	return result

## Get discovered state of all biomes
func _get_discovered_biomes() -> Dictionary:
	var result = {}
	for id in BiomeDatabase.biomes.keys():
		var biome: BiomeData = BiomeDatabase.biomes[id]
		result[str(id)] = biome.discovered
	return result

## Get encountered state of all biomes
func _get_encountered_biomes() -> Dictionary:
	var result = {}
	for id in BiomeDatabase.biomes.keys():
		var biome: BiomeData = BiomeDatabase.biomes[id]
		result[str(id)] = biome.encountered
	return result

## Restore discovered state of enemies
func _restore_discovered_enemies(data: Dictionary) -> void:
	for id_str in data.keys():
		var id = int(id_str)
		if EnemyDatabase.enemies.has(id):
			EnemyDatabase.enemies[id].discovered = data[id_str]

## Restore discovered state of hands
func _restore_discovered_hands(data: Dictionary) -> void:
	for id_str in data.keys():
		var id = int(id_str)
		if HandDatabase.hands.has(id):
			HandDatabase.hands[id].discovered = data[id_str]

## Restore discovered state of biomes
func _restore_discovered_biomes(data: Dictionary) -> void:
	for id_str in data.keys():
		var id = int(id_str)
		if BiomeDatabase.biomes.has(id):
			BiomeDatabase.biomes[id].discovered = data[id_str]

## Restore encountered state of biomes
func _restore_encountered_biomes(data: Dictionary) -> void:
	for id_str in data.keys():
		var id = int(id_str)
		if BiomeDatabase.biomes.has(id):
			BiomeDatabase.biomes[id].encountered = data[id_str]
