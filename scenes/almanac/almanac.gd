extends ScrollContainer
@onready var grid := $Grid
var card_scene := preload("res://scenes/almanac/enemyCard.tscn")

func _ready() -> void:
	setup("hand")

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
