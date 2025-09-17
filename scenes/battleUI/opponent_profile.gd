extends Control

@onready var portrait: TextureRect = $Container/ImageBox/Portrait
@onready var name_tag: Label       = $Container/NameTag
@onready var slanter_tag: Label    = $Container/Slanter

func set_enemy(enemy: EnemyData) -> void:
	assert(enemy, "Failed to load enemy (opponent_profile.gd)")
	portrait.texture = enemy.sprite
	name_tag.text = enemy.name if enemy.discovered else "???"
	# Slanter
