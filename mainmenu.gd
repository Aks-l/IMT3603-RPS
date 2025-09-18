extends Control

func _on_almanac_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/almanac.tscn")

func _on_play_pressed() -> void:
	var enemy := preload("res://data/enemies/BobRock.tres") as EnemyData
	var battle := preload("res://scenes/battleUI/battle_ui.tscn").instantiate() as BattleUI
	battle.setup(enemy, Globals.inventory, [])
	get_tree().root.add_child(battle)

	# make the battle camera active (in case it isn’t set to Current in the editor)
	(battle.get_node("Camera3D") as Camera3D).make_current()

	# remove or hide the menu so it stops covering the screen
	queue_free()            # <- replaces the menu entirely
	# OR: hide()            # <- keep it in memory but invisible
