extends CanvasLayer
@onready var grid: GridContainer = %Grid
@onready var see_enemies = %Enemies
@onready var see_hands = %Hands
@onready var back = %Back

var card_scene := preload("res://scenes/almanac/enemyCard.tscn")

# Initialize with enemies shown, and connect buttons to their function
func _ready() -> void:
	setup("enemy")
	see_enemies.pressed.connect(refresh.bind("enemy"))
	see_hands.pressed.connect(refresh.bind("hand"))
	back.pressed.connect(_leave)
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	hide()

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
	print("clicked")
	for entry in grid.get_children():
		entry.queue_free()
	setup(type)
	
func _show_overlay():
	print("opened almanac")
	self.visible = true
	get_tree().paused = true
	
func _leave() -> void:
	print("closed almanac")
	hide()
	get_tree().paused = false
