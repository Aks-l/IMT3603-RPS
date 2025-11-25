extends CanvasLayer

@onready var color_rect = %ColorRect
@onready var message = %Message
@onready var timer = %Timer

const fade_time: float = 5

func trigger():
	get_tree().paused = true
	var biome = Globals.current_biome
	visible = true
	color_rect.size = message.size
	message.text = "You wake up in %s" % biome.name
	color_rect.self_modulate.a = 1
	timer.start(5)

func _process(float) -> void:
	color_rect.modulate.a = timer.time_left/fade_time
	if timer.time_left == 0:
		visible = false
		get_tree().paused = false
	
