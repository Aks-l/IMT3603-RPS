extends ScrollContainer
@onready var grid := $Grid
var card_scene := preload("res://scenes/almanac/enemyCard.tscn")

func _ready() -> void:
	var enemies = EnemyDatabase.enemies.keys()
	for enemy in enemies:
		var data: EnemyData = EnemyDatabase.enemies[enemy]
		var card = card_scene.instantiate()
		grid.add_child(card)
		card.populate(data)
