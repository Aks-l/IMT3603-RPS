extends Node

var enemies: Dictionary = {}

func load_enemies():
	var dir = DirAccess.open("res://enemies")
	if dir:
		print("found dir")
		for file in dir.get_files():
			if file.ends_with(".tres"):
				print("found file")
				var enemy = load("res://enemies/" + file)
				if enemy and enemy is EnemyData:
					print("adding enemy")
					enemies[enemy.id] = enemy
				
	
func _ready():
	load_enemies()
	print(enemies.values())
