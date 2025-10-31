extends Control


@onready var sprite: TextureRect = $VBoxContainer/ImageBox/Image
@onready var name_label: Label = $VBoxContainer/Name
@onready var description_label: Label = $VBoxContainer/Description

var undiscovered : Texture2D = preload("res://data/unknown.png")

# Fill one almanac entry with proper data
func populate(d: Resource) -> void:
	var data = d

	if sprite:
		if d.discovered:
			sprite.texture = d.sprite
		else:
			sprite.texture = undiscovered

	if name_label:
		if d.discovered:
			name_label.text = d.name
		else:
			name_label.text = "???"
			
	if description_label:
		if d is EnemyData :
			description_label.text = d.description
