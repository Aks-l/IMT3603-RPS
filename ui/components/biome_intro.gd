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
	message.text = "You wake up %s %s..." % [biome.prefix, biome.name]
	color_rect.modulate.a = 1
	timer.start(5)
	timer.timeout.connect(close_message)

func close_message() -> void:
	get_tree().paused = false
	visible = false

func _process(float) -> void:
	color_rect.modulate.a = timer.time_left/max(fade_time, 0.001)
