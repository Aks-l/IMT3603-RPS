extends Control

signal chosen_reward

@onready var label = $VBoxContainer/Label
@onready var reward_container = $VBoxContainer/HBoxContainer

var continue_button: Button = null

func _ready() -> void:
	#Try to find existing button or create new one
	continue_button = get_node_or_null("VBoxContainer/ContinueButton")
	if not continue_button:
		continue_button = Button.new()
		continue_button.name = "ContinueButton"
		continue_button.text = "Continue"
		$VBoxContainer.add_child(continue_button)
	
	continue_button.visible = false
	continue_button.pressed.connect(_on_continue_pressed)

func setup(enemy: EnemyData, defeated: bool):
	if defeated:
		label.text = "You defeated\n%s\n\nChoose your reward:" % enemy.name
		populate_rewards(enemy)
		discover_cards(enemy)
		continue_button.visible = false
	else:
		label.text = "You were defeated by %s" % enemy.name
		reward_container.visible = false
		continue_button.visible = true
		continue_button.text = "Continue" if Globals.health > 0 else "Return to Main Menu"

func _on_continue_pressed() -> void:
	if Globals.health <= 0:
		# Game over - use a global flag and change scene
		Globals.reset_run()
		Globals.set_meta("returning_from_game_over", true)
		get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
	else:
		# Normal victory - continue playing
		chosen_reward.emit()

func populate_rewards(enemy: EnemyData):
	for child in reward_container.get_children():
		child.queue_free()
	for hand in enemy.deck.keys():
		var container = TextureRect.new()
		container.texture = hand.sprite
		container.ignore_texture_size = true                         
		container.custom_minimum_size = Vector2(128, 128)
		
		container.gui_input.connect(choose_reward.bind(hand))

		reward_container.add_child(container)

func choose_reward(event: InputEvent, hand: HandData):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var current := int(Globals.inventory.get(hand, 0))
		Globals.inventory[hand] = current + 1
		get_tree().paused = false
		chosen_reward.emit()
