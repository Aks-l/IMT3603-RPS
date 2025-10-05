extends Control


@onready var sprite: TextureRect = $VBoxContainer/ImageBox/Image
@onready var name_label: Label = $VBoxContainer/Name
@onready var description_label: Label = $VBoxContainer/Description

# Fill one almanac entry with proper data
func populate(d: Resource) -> void:
	var data = d
	print("added " + d.name)
	if sprite:
		sprite.texture = d.sprite
	if name_label:
		name_label.text = d.name
		print(name_label.text)
	if description_label:
		if d is EnemyData:
			description_label.text = d.description
