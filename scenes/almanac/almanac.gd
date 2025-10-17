extends Control
@onready var grid: GridContainer = $Margin/VBoxContainer/Container/Grid
@onready var see_enemies = $Margin/VBoxContainer/Buttons/Enemies
@onready var see_hands = $Margin/VBoxContainer/Buttons/Hands
@onready var back = $Margin/VBoxContainer/Back

var card_scene := preload("res://scenes/almanac/enemyCard.tscn")

func _enter_tree():
	visible = false
	z_as_relative = false
	z_index = 100
	
	
# Initialize with enemies shown, and connect buttons to their function
func _ready() -> void:
	setup("enemy")
	see_enemies.pressed.connect(refresh.bind("enemy"))
	see_hands.pressed.connect(refresh.bind("hand"))
	back.pressed.connect(_leave)
	process_mode = Node.PROCESS_MODE_ALWAYS

# Popluate grid based on datatype
func setup(type:String):
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
	
func _leave() -> void:
	self.hide()
