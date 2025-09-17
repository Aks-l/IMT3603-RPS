extends Node2D

@onready var container: Node = $HBoxContainer

func set_inventory(handList: Array[Hand]) -> Void:
	for hand in handList:
		var added_hand = handscene.instantiate()
		addedhand.data = hand.tres.data
		container.add_child(addedhand)
