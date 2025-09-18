extends Control

@export var data: EnemyData

@onready var sprite: TextureRect = $VBoxContainer/ImageBox/Image
@onready var name_label: Label = $VBoxContainer/Name
@onready var description_label: Label = $VBoxContainer/Description

func _ready() -> void:
	if data:
		populate(data)

func populate(d: EnemyData) -> void:
	data = d
	if sprite:
		sprite.texture = d.sprite
	if name_label:
		name_label.text = d.name
		print(name_label.text)
	if description_label:
		description_label.text = d.description
