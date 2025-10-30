extends Node

var enemies: Dictionary = {}

func load_enemies():
	var dir = DirAccess.open("res://data/enemies")
	if dir:
		for file in dir.get_files():
			if file.ends_with(".tres"):
				var enemy = load("res://data/enemies/" + file)
				if enemy and enemy is EnemyData:
					enemies[enemy.id] = enemy
					print("%d %s" % [enemy.id, enemy.name]) 

func _ready():
	load_enemies()
