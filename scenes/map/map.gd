extends Node2D

# -------- knobs --------
@export var layers := 7                 # total rows (top=0 ... bottom=layers-1)
@export var max_width := 4              # max nodes in the wide middle
@export var x_spacing := 140.0
@export var y_spacing := 140.0
@export var seed := -1 ##If set to positive number, will generate from seed, otherwise random
@export var encounter_scene: PackedScene

@onready var edges_root := $Edges
@onready var encounters_root := $Encounters

@onready var deck_button: Button = $DeckButton
@onready var almanac_button: Button = $AlmanacButton

var AlmanacScene := preload("res://scenes/almanac/almanac.tscn")
var almanac_ui: Control

# -------- state --------
var layer_ids = []   # [[ids...], ...]
var counts = []      # [count per layer]
var pos = {}         # id -> Vector2
var etype = {}       # id -> "Start"/"Combat"/"Event"/"Shop"/"Rest"/"Boss"
var edges = []       # [[from_id, to_id], ...]
var reachable = {}   # id -> bool
var cleared = {}     # id -> bool

var map_interaction_enabled := true


func _ready():
	EncounterHandler.encounter_finished.connect(_on_encounter_finished)
	
	almanac_ui = AlmanacScene.instantiate()
	almanac_ui.visible = false
	almanac_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(almanac_ui)
	
	deck_button.pressed.connect(_on_deck_button_pressed)
	almanac_button.pressed.connect(_on_almanac_button_pressed)
	
	setup()

func setup():
	_generate()
	_draw_edges()
	_spawn_encounters()
	_unlock_starts()

func _rid(i, j):
	return "L%02d_N%02d" % [i, j]

## Generates a map based on seed, or randomly if seed is set to negative values
func _generate():
	var rng = RandomNumberGenerator.new()
	if seed > 0:
		rng.seed = seed
	else:
		randomize()
		rng.seed = rng.randi()

	layer_ids.clear()
	counts.clear()
	pos.clear()
	etype.clear()
	edges.clear()	

	# 1) decide width per layer
	var mid := int(layers / 2)
	var w := 1
	for i in range(layers):
		if i == 0:
			w = 1
		elif i < mid:
			# widen early; sometimes stay same, sometimes +1
			if w < max_width and rng.randf() < 0.6:
				w += 1
		elif i < layers - 1:
			# converge later; usually -1
			if w > 1 and rng.randf() < 0.8:
				w -= 1
		else:
			w = 1  # last layer = boss
		counts.append(w)

	# 2) positions (top → down); center rows horizontally
	var origin := Vector2(0, 0)
	for i in range(layers):
		var ids = []
		var count = counts[i]
		for j in range(count):
			var id = _rid(i, j)
			ids.append(id)
			var x = (j - (count - 1) * 0.5) * x_spacing + origin.x
			var y = i * y_spacing + origin.y
			pos[id] = Vector2(x, y)
			if i == 0:
				etype[id] = "Start"
			elif i == layers - 1:
				etype[id] = "Boss"
			else:
				# simple mix
				var r = rng.randf()
				etype[id] = "Event" if r < 0.2 else "Shop" if r < 0.3 else "Combat"
		layer_ids.append(ids)

	# 3) connections: always straight-down; optional diagonals in first half
	for i in range(layers - 1):
		var c_from = counts[i]
		var c_to = counts[i + 1]
		for j in range(c_from):
			var from_id = _rid(i, j)
			# base mapping: keep relative column (guaranteed straight-down)
			var base_tj = _map_index(j, c_from, c_to)
			edges.append([from_id, _rid(i + 1, base_tj)])

			# early branching: allow optional side links (first half only)
			if i < int(layers / 2):
				if base_tj - 1 >= 0 and rng.randf() < 0.35:
					edges.append([from_id, _rid(i + 1, base_tj - 1)])
				if base_tj + 1 < c_to and rng.randf() < 0.35:
					edges.append([from_id, _rid(i + 1, base_tj + 1)])

	# 4) ensure every node in next layer has at least one inbound
	var inbound = {}
	for e in edges: inbound[e[1]] = true
	for i in range(1, layers):
		for t in layer_ids[i]:
			if not inbound.has(t):
				# connect closest prev node to this orphan
				var best = layer_ids[i - 1][0]
				var best_d = 1e9
				for f in layer_ids[i - 1]:
					var d = pos[f].distance_to(pos[t])
					if d < best_d: best_d = d; best = f
				edges.append([best, t])


func _map_index(j, from_count, to_count):
	if to_count == 1:
		return 0
	if from_count == 1:
		return int((to_count - 1) / 2)  # center
	# keep relative column across different widths
	var t = float(j) * float(to_count - 1) / float(from_count - 1)
	return int(round(t))

func _draw_edges():
	for c in edges_root.get_children():
		c.queue_free()
	for e in edges:
		var ln = Line2D.new()
		ln.width = 2.0
		ln.points = PackedVector2Array([pos[e[0]], pos[e[1]]])
		edges_root.add_child(ln)

func _spawn_encounters():
	for c in encounters_root.get_children():
		c.queue_free()
	for i in range(layers):
		for j in range(counts[i]):
			var id = _rid(i, j)
			var node = encounter_scene.instantiate()
			node.position = pos[id]
			node.encounter_id = id
			node.encounter_type = _etype_to_dropdown(etype[id])
			node.clicked.connect(_on_encounter_clicked)
			encounters_root.add_child(node)
			reachable[id] = false
			cleared[id] = false

func _unlock_starts():
	for id in layer_ids[0]:
		reachable[id] = true
	_apply_state_to_nodes()

func _apply_state_to_nodes():
	for n in encounters_root.get_children():
		n.set_reachable(reachable.get(n.encounter_id, false))
		n.set_cleared(cleared.get(n.encounter_id, false))

func _on_encounter_clicked(id):
	
	if not map_interaction_enabled:
		print("Map interaction disabled - click ignored")
		return
	
	cleared[id] = true
	reachable[id] = false
	var layer_idx = _layer_of(id)

	# lock siblings
	for other in layer_ids[layer_idx]:
		if other != id:
			reachable[other] = false

	# unlock neighbors in next layer
	if layer_idx + 1 < layers:
		for e in edges:
			if e[0] == id:
				reachable[e[1]] = true

	_apply_state_to_nodes()
	# print("Enter:", etype[id], id)

func _layer_of(id):
	# "Lxx_Nyy" -> xx
	return int(id.substr(1, 2))

##Converts text to encountertype (enum)
func _etype_to_dropdown(t):
	match t:
		"Start": return 0
		"Combat": return 1
		"Event": return 2
		"Shop": return 3
		"Rest": return 4
		"Boss": return 5
		_: return 1

func _on_encounter_finished(result):
	if result.type == "Boss":
		for i in edges_root.get_children():
			i.queue_free()
		for i in encounters_root.get_children():
			i.queue_free()
		setup()
	

func _on_deck_button_pressed() -> void:
	print("Opening deck builder")
	#saves any map data if needed before switching scenes, can be removed later
	EncounterHandler.start_encounter("DeckCreator")

func _on_almanac_button_pressed() -> void:
	print("Opening almanac")
