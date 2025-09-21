extends HBoxContainer

@export var red_heart_texture: Texture2D
@export var blue_heart_texture: Texture2D
@export var max_red_hearts: int = 5 #permanent health
@export var max_blue_cap: int = 2 #max possible "blue" health

var current_red_hearts: int
var current_blue_hearts: int = 0


func _ready():
	current_red_hearts = max_red_hearts
	_draw_hearts()


func _draw_hearts():
	#clears old hearts
	for c in get_children():
		c.queue_free()
		
	#draw hearts for curent hp
	for i in range(current_red_hearts):
		var heart = TextureRect.new()
		heart.texture = red_heart_texture
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(heart)
		
	#draw blye harts
	for i in range(current_blue_hearts):
		var heart = TextureRect.new()
		heart.texture = blue_heart_texture
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(heart)


func set_hp(red_hp: int, blue_hp: int = -1):
	current_red_hearts = clamp(red_hp, 0 , max_red_hearts)
	if blue_hp >= 0:
		current_blue_hearts = clamp(blue_hp, 0, max_blue_cap)
		_draw_hearts()


func add_blue_hearts(amount: int):
	current_blue_hearts = clamp(current_blue_hearts + amount, 0, max_blue_cap)
	_draw_hearts()

func take_damage(amount: int):
	var dmg_left = amount
	
	#makes blue harts get hit first
	if current_blue_hearts > 0:
		var absorbed = min(dmg_left, current_blue_hearts)
		current_blue_hearts -= absorbed
		dmg_left -= absorbed
	
	#when no blue harts, red takes damage
	if dmg_left > 0:
		current_red_hearts = max(current_red_hearts - dmg_left, 0)
		
		_draw_hearts()
