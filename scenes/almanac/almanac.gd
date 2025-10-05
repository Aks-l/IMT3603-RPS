extends Control
@onready var grid: GridContainer = $VBoxContainer/Container/Grid
@onready var see_enemies = $VBoxContainer/Buttons/Enemies
@onready var see_hands = $VBoxContainer/Buttons/Hands
@onready var back = $VBoxContainer/Back

var card_scene := preload("res://scenes/almanac/enemyCard.tscn")

# Initialize with enemies shown, and connect buttons to their function
func _ready() -> void:
	setup("enemy")
	see_enemies.pressed.connect(refresh.bind("enemy"))
	see_hands.pressed.connect(refresh.bind("hand"))
	back.pressed.connect(_leave)

# Popluate grid based on datatype
func setup(type):
	match type:
		"enemy":
			var enemies = EnemyDatabase.enemies.keys()
			for enemy in enemies:
				var data: EnemyData = EnemyDatabase.enemies[enemy]
				var card = card_scene.instantiate()
				grid.add_child(card)
				card.populate(data)
		"hand":
			var hands = HandDatabase.hands.keys()
			for hand in hands:
				if hand==9999:continue # Don't add the Placeholder hand
				var data: HandData = HandDatabase.hands[hand]
				var card = card_scene.instantiate()
				grid.add_child(card)
				card.populate(data)

# Update what is shown in grid
func refresh(type:String):
	for entry in grid.get_children():
		entry.queue_free()
	setup(type)

# Return to main menu
func _leave():
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
