extends Node2D

signal clicked(encounter_id)

enum EncounterType { START, COMBAT, EVENT, SHOP, REST, BOSS }

@export var encounter_id: String = ""
@export_enum("Start","Combat","Event","Shop","Rest","Boss")
var encounter_type: int = EncounterType.COMBAT

var reachable := false
var cleared := false
var _hovered := false

@onready var marker: ColorRect = $UI/VBox/CenterContainer/NodeImage            # ColorRect
@onready var name_label: Label = $UI/VBox/TypeLabel      # Label above
@onready var area: Area2D = $NodeShape                   # Has a CircleShape2D

func _ready() -> void:
	name_label.text = _type_to_string(encounter_type)
	for c in [$UI, $UI/VBox, $UI/VBox/CenterContainer, name_label, marker]:
		(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Hover & click via Area2D
	area.mouse_entered.connect(_on_hover_enter)
	area.mouse_exited.connect(_on_hover_exit)
	area.input_event.connect(_on_area_input)

	_refresh_visual()

func set_reachable(v: bool) -> void:
	reachable = v
	_refresh_visual()

func set_cleared(v: bool) -> void:
	cleared = v
	_refresh_visual()

func _on_hover_enter() -> void:
	_hovered = true
	_refresh_visual()

func _on_hover_exit() -> void:
	_hovered = false
	_refresh_visual()

func _on_area_input(_vp, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if reachable and not cleared:
			emit_signal("clicked", encounter_id)

func _refresh_visual() -> void:
	# Base by type
	var c := Color(0.45, 0.45, 0.45) # locked/neutral
	if encounter_type == EncounterType.BOSS:
		c = Color(0.8, 0.2, 0.2)

	# State overrides
	if cleared:
		c = Color(0.2, 0.8, 0.3)          # cleared
	elif _hovered:
		c = Color(1.0, 0.95, 0.5)         # hover (brighter)
	elif reachable:
		c = Color(1.0, 0.9, 0.3)          # reachable (normal)

	marker.color = c

func _type_to_string(t: int) -> String:
	match t:
		EncounterType.START: return "Start"
		EncounterType.COMBAT: return "Combat"
		EncounterType.EVENT: return "Event"
		EncounterType.SHOP: return "Shop"
		EncounterType.REST: return "Rest"
		EncounterType.BOSS: return "Boss"
		_: return "?"
