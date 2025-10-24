extends Camera2D

@export var drag_button := MOUSE_BUTTON_MIDDLE   # change to RIGHT if you prefer
@export var zoom_step := 0.1                     # how fast to zoom
@export var zoom_min := 0.5
@export var zoom_max := 2.0
@export var bounds := Vector4(-1000, -500, 1000, 1000)

var _dragging := false
var _last_mouse := Vector2.ZERO

func _ready() -> void:
	limit_left   = int(bounds.x)
	limit_top    = int(bounds.y)
	limit_right  = int(bounds.z)
	limit_bottom = int(bounds.w)


func _unhandled_input(event: InputEvent) -> void:
	# Start/stop dragging
	if event is InputEventMouseButton and event.button_index == drag_button:
		if event.pressed:
			_dragging = true
			_last_mouse = get_viewport().get_mouse_position()
		else:
			_dragging = false
		get_viewport().set_input_as_handled()

	# Zoom with wheel while cursor over viewport
	if event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		var z := 1.0
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:  z = 1.0 - zoom_step
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: z = 1.0 + zoom_step
		var new_zoom := (zoom * z).clamp(Vector2(zoom_min, zoom_min), Vector2(zoom_max, zoom_max))
		zoom = new_zoom
		get_viewport().set_input_as_handled()

func _process(_dt: float) -> void:
	if _dragging:
		var cur := get_viewport().get_mouse_position()
		var delta := cur - _last_mouse           # screen-space delta
		position -= delta * zoom                 # pan opposite; scale by zoom
		_last_mouse = cur
