extends Control

signal event_completed(result: Dictionary)

@onready var overlay: ColorRect = $Overlay
@onready var event_panel: PanelContainer = $EventPanel
@onready var event_image: TextureRect = $EventPanel/MarginContainer/VBoxContainer/EventImage
@onready var event_title: Label = $EventPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var event_description: Label = $EventPanel/MarginContainer/VBoxContainer/DescriptionLabel
@onready var options_container: VBoxContainer = $EventPanel/MarginContainer/VBoxContainer/OptionsContainer
@onready var outcome_panel: PanelContainer = $OutcomePanel
@onready var outcome_label: Label = $OutcomePanel/MarginContainer/VBoxContainer/OutcomeLabel
@onready var continue_button: Button = $OutcomePanel/MarginContainer/VBoxContainer/ContinueButton

var current_event: EventData
var selected_option: EventOptionData

func _ready():
	#Block all mouse input from passing through to map
	mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	#Hide outcome
	outcome_panel.visible = false
	#Connect continue button
	continue_button.pressed.connect(_on_continue_pressed)

##Display the event
func display_event(event: EventData):
	current_event = event
	
	#Clear existing options
	for child in options_container.get_children():
		child.queue_free()
	
	#Set up event display
	if event.image:
		event_image.texture = event.image
		event_image.visible = true
	else:
		event_image.visible = false
	
	event_title.text = event.event_name
	event_description.text = event.description
	
	#Create option buttons
	var button_count = 0
	for option in event.options:
		print("[EventUI] Processing option: ", option.option_text if option else "NULL")
		
		var button = Button.new()
		button.text = option.option_text
		button.custom_minimum_size = Vector2(0, 35)
		
		#Check if option is available
		var is_available = true
		if option.custom_script:
			var script_instance = option.custom_script.new()
			var context = _build_context(option)
			is_available = script_instance.can_execute(context)
			
            # Add tooltip if custom script provides one
			var tooltip = script_instance.get_tooltip(context)
			if tooltip != "":
				button.tooltip_text = tooltip
		
		#Grey out and disable unavailable options
		if not is_available:
			button.disabled = true
			button.modulate = Color(0.5, 0.5, 0.5, 0.7)
			if button.tooltip_text == "":
				button.tooltip_text = "Not available"
			print("[EventUI] Option disabled: ", option.option_text)
		else:
			button.pressed.connect(_on_option_chosen.bind(option))
		
		options_container.add_child(button)
		button_count += 1
		print("[EventUI] Button created for: ", option.option_text)
	
	print("[EventUI] Total buttons created: ", button_count)
	
	#Show the event UI
	show()

func _on_option_chosen(option: EventOptionData):
	selected_option = option
	
	#Hide event panel, prepare to show outcome
	event_panel.visible = false
	
	var outcome_text := ""
	var result := {}
	
	#Execute custom script if present
	if option.custom_script:
		var script_instance = option.custom_script.new()
		var context = _build_context(option)
		result = script_instance.execute(context)
		
		outcome_text = result.get("message", "Something happened...")
		
	#Execute custom code string if present, overridden by custom_script
	elif option.custom_code != "":
		var expression = Expression.new()
		var parse_error = expression.parse(option.custom_code, ["globals", "option"])
		
		if parse_error == OK:
			var execution_result = expression.execute([Globals, option])
			if not expression.has_execute_failed():
				result = {"success": true, "message": str(execution_result)}
				outcome_text = str(execution_result)
			else:
				outcome_text = "Error executing custom code"
		else:
			outcome_text = "Error parsing custom code"
	
	#Standard outcome handling
	else:
		outcome_text = option.outcome_description
		_apply_standard_rewards(option)
		result = {"success": true}
	
	#Display outcome
	outcome_label.text = outcome_text
	outcome_panel.visible = true
	
	#Handle followup actions
	if option.triggers_combat and option.combat_enemy:
		result["triggers_combat"] = true
		result["enemy"] = option.combat_enemy
	elif option.next_event_id >= 0:
		result["next_event_id"] = option.next_event_id


##Apply rewards and consequences
func _apply_standard_rewards(option: EventOptionData):
	#Apply rewards
	Globals.funds += option.gold_reward
	
	if option.health_change != 0:
		#Health will be applied by the map/encounter handler
		pass #TODO: Implement health change application
	
	for item in option.items_received:
		Globals.consumables.append(item)
	
	for hand in option.hands_received:
		var current := int(Globals.inventory.get(hand, 0))
		Globals.inventory[hand] = current + 1
	
	#Handle consequences
	Globals.funds -= option.gold_cost
	
	for item in option.removes_items:
		Globals.consumables.erase(item)

func _on_continue_pressed():
	#Prepare result data
	var result := {
		"event": current_event,
		"option": selected_option,
		"health_change": selected_option.health_change if selected_option else 0
	}
	
	#Check for follow up actions
	if selected_option:
		if selected_option.triggers_combat:
			result["triggers_combat"] = true
			#Use specified enemy or pick random one
			if selected_option.combat_enemy:
				result["enemy"] = selected_option.combat_enemy
			else:
				result["enemy"] = EnemyDatabase.enemies.values().pick_random()
				print("[EventUI] No enemy specified, picked random: ", result["enemy"].name if result["enemy"] else "NULL")
		elif selected_option.next_event_id >= 0:
			result["next_event_id"] = selected_option.next_event_id
			result["chain_event"] = true
			print("[EventUI] Event will chain to next_event_id: ", selected_option.next_event_id)
	
	event_completed.emit(result)
	queue_free()


##Sets up context for custom scripts
func _build_context(option: EventOptionData) -> Dictionary:
	return {
		"player_health": null,  #TODO: Set player health
		"globals": Globals,
		"encounter_handler": EncounterHandler,
		"event_ui": self,
		"option_data": option
	}
