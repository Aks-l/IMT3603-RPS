extends Control

signal chosen_reward

@onready var label = $VBoxContainer/Label
@onready var reward_container = $VBoxContainer/HBoxContainer

func setup(enemy: EnemyData, defeated: bool):
	if defeated:
		label.text = "You defeated\n%s\n\nChoose your reward:" % enemy.name
		populate_rewards(enemy)
	else:
		label.text = "You were defeated by %s" % enemy.name

func populate_rewards(enemy: EnemyData):
	for child in reward_container.get_children():
		child.queue_free()
	for hand in enemy.moveset:
		var container = TextureRect.new()
		container.texture = hand.sprite
		container.ignore_texture_size = true                         
		container.custom_minimum_size = Vector2(64, 64)
		
		container.gui_input.connect(choose_reward.bind(hand))

		reward_container.add_child(container)

func choose_reward(event: InputEvent, hand: HandData):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Globals.inventory[hand]:
			Globals.inventory[hand] += 1
		else:
			Globals.inventory[hand] = 1
		print(Globals.inventory)
		chosen_reward.emit()
