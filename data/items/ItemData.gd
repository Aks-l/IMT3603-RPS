class_name ItemData
extends Resource

enum Type {ACCESSORY, HEAL, DAMAGE, SHIELD}

@export var type: Type
@export var id: int
@export var sprite: Texture2D
@export var name: String
@export var description: String
@export var discovered: bool
@export var price: int

@export var item_script: Script
