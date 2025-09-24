extends HBoxContainer

@export var red_heart_texture: Texture2D
@export var blue_heart_texture: Texture2D
@export var max_red_hearts: int = 5 #permanent health
@export var max_blue_cap: int = 2 #max possible "blue" health

@export var heart_icon_scene: PackedScene #assign heart icon
@export var icon_size: Vector2 = Vector2(24,24)

var current_red_hearts: int = max_red_hearts
var current_blue_hearts: int = 0


func _ready():
	current_red_hearts = max_red_hearts
	_draw_hearts()

func _update_icons():
	for c in get_children(): #removed old hearts
		c.queue_free()
	
	for i in range(current_red_hearts):
		add_child(_make_icon(red_heart_texture))
	
	for i in range(current_blue_hearts):
		add_child(_make_icon(blue_heart_texture))

func _make_icon(tex: Texture2D) -> TextureRect:
	var icon := heart_icon_scene.instantiate() as TextureRect
	icon.texture = tex
	icon.custom_minimum_size = icon_size
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.ignore_texture_size = true
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon


func _draw_hearts():
	#clears old hearts
	for c in get_children():
		c.queue_free()
		
	#draw hearts for curent hp
	for i in range(current_red_hearts):
		add_child(_make_icon(red_heart_texture))
		
	#draw blye harts
	for i in range(current_blue_hearts):
		add_child(_make_icon(blue_heart_texture))


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

func heal(amount: int):
	current_red_hearts = clamp(current_red_hearts + amount, 0, max_red_hearts)
	_update_icons()

func add_blue(amount: int):
	current_blue_hearts = clamp(current_blue_hearts + amount, 0, max_blue_cap)
	_update_icons()
