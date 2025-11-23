extends CanvasLayer

@onready var graph_close_button = %CloseButton
@onready var drawing = %OutcomeGraph

func _ready():
	if graph_close_button:
		graph_close_button.pressed.connect(_toggle_outcome_graph)

func _toggle_outcome_graph():
	self.visible = !self.visible

func _refresh():
	drawing.redraw_all()
