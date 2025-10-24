extends Control

@onready var health_container: HBoxContainer = %HealthContainer
@onready var funds_label: Label = %FundsLabel

const HEART_FULL = "♥"
const HEART_EMPTY = "♡"

func _ready() -> void:
	Globals.health_changed.connect(_on_health_changed)
	Globals.funds_changed.connect(_on_funds_changed)
	
	_update_health_display(Globals.health)
	_update_funds_display(Globals.funds)

func _on_health_changed(new_health: int) -> void:
	_update_health_display(new_health)

func _on_funds_changed(new_funds: int) -> void:
	_update_funds_display(new_funds)

func _update_health_display(current_health: int) -> void:
	for child in health_container.get_children():
		child.queue_free()
	
	for i in range(Globals.MAX_HEALTH):
		var heart_label = Label.new()
		heart_label.add_theme_font_size_override("font_size", 32)
		
		if i < current_health:
			heart_label.text = HEART_FULL
			heart_label.add_theme_color_override("font_color", Color.RED)
		else:
			heart_label.text = HEART_EMPTY
			heart_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		
		health_container.add_child(heart_label)

func _update_funds_display(current_funds: int) -> void:
	funds_label.text = "Gold: %d" % current_funds
