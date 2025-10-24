extends Node2D

@export var layers := 7
@export var max_width := 4
@export var x_spacing := 140.0
@export var y_spacing := 140.0
@export var organic_layout := true
@export var x_randomness := 90.0
@export var y_randomness := 70.0
@export var path_texture: Texture2D
@export var seed := -1 ##If set to positive number, will generate from seed, otherwise random
@export var encounter_scene: PackedScene

@onready var edges_root := $Edges
@onready var encounters_root := $Encounters
@onready var background := $Background
@onready var deck_button: Button = $DeckButton

var layer_ids = []
var counts = []
var pos = {}
var etype = {}
var edges = []
var reachable = {}
var cleared = {}

var map_interaction_enabled := true


func _ready():
	EncounterHandler.encounter_finished.connect(_on_encounter_finished)
	setup()

func setup():
	_generate()
	_draw_edges()
	_spawn_encounters()
	_unlock_starts()
	
	#Generate terrain background based on map
	if background:
		background.set_graph(pos, edges)
	
	deck_button.pressed.connect(_on_deck_button_pressed)

func _rid(i, j):
	return "L%02d_N%02d" % [i, j]

## Generates a map based on seed, or randomly if seed is set to negative values
func _generate():
	var rng = RandomNumberGenerator.new()
	if seed > 0:
		rng.seed = seed
	else:
		rng.randomize()
		rng.seed = rng.randi()

	layer_ids.clear()
	counts.clear()
	pos.clear()
	etype.clear()
	edges.clear()	

	var mid := int(layers / 2)
	var w := 1
	for i in range(layers):
		if i == 0:
			w = 1
		elif i < mid:
			if w < max_width:
				var expand_chance = 0.4 + rng.randf() * 0.4
				if rng.randf() < expand_chance:
					w += 1
				if organic_layout and w < max_width and rng.randf() < 0.15:
					w += 1
		elif i < layers - 1:
			if w > 1:
				var shrink_chance = 0.5 + rng.randf() * 0.4
				if rng.randf() < shrink_chance:
					w -= 1
			elif organic_layout and rng.randf() < 0.2:
				pass
		else:
			w = 1
		counts.append(w)

	var origin := Vector2(120, 120)
	for i in range(layers):
		var ids = []
		var count = counts[i]
		
		var layer_y_offset = 0.0
		if organic_layout:
			layer_y_offset = (rng.randf() - 0.5) * y_randomness * 0.8
		
		for j in range(count):
			var id = _rid(i, j)
			ids.append(id)
			
			var base_x = (j - (count - 1) * 0.5) * x_spacing + origin.x
			var base_y = i * y_spacing + origin.y + layer_y_offset
			
			var offset_x = 0.0
			var offset_y = 0.0
			if organic_layout:
				offset_x = (rng.randf() - 0.5) * x_randomness
				offset_y = (rng.randf() - 0.5) * y_randomness
				
				if i == 0 or i == layers - 1:
					offset_x *= 0.4
					offset_y *= 0.4
			
			pos[id] = Vector2(base_x + offset_x, base_y + offset_y)
			
			if i == 0:
				etype[id] = "Start"
			elif i == layers - 1:
				etype[id] = "Boss"
			else:
				# simple mix
				var r = rng.randf()
				etype[id] = "Event" if r < 0.2 else "Shop" if r < 0.3 else "Combat"
		layer_ids.append(ids)

	# 3) connections
	if organic_layout:
		# Organic: connect to nearby nodes based on actual distance
		for i in range(layers - 1):
			var from_layer = layer_ids[i]
			var to_layer = layer_ids[i + 1]
			
			for from_id in from_layer:
				var from_pos = pos[from_id]
				
				# Find nearest nodes in next layer (sorted by distance)
				var distances = []
				for to_id in to_layer:
					var dist = from_pos.distance_to(pos[to_id])
					distances.append({"id": to_id, "dist": dist})
				distances.sort_custom(func(a, b): return a.dist < b.dist)
				
				# Always connect to closest node
				edges.append([from_id, distances[0].id])
				
				# Possibly connect to 2nd or 3rd closest (creates branching)
				if i < int(layers / 2):  # More branching in early game
					# Connect to 2nd closest with chance
					if distances.size() > 1 and rng.randf() < 0.4:
						edges.append([from_id, distances[1].id])
					
					# Connect to 3rd closest with lower chance
					if distances.size() > 2 and rng.randf() < 0.2:
						edges.append([from_id, distances[2].id])
				else:
					# Late game: occasional extra connection
					if distances.size() > 1 and rng.randf() < 0.25:
						edges.append([from_id, distances[1].id])
	else:
		# Even grid: use column-based connections
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
	
	var create_line = func(points: PackedVector2Array, line_width: float, color: Color = Color.WHITE, use_curve: bool = false) -> Line2D:
		var ln = Line2D.new()
		ln.width = line_width
		ln.points = points
		if use_curve:
			if path_texture:
				ln.texture = path_texture
				ln.texture_mode = Line2D.LINE_TEXTURE_TILE
			else:
				ln.default_color = color
			ln.width_curve = _create_path_width_curve()
			ln.joint_mode = Line2D.LINE_JOINT_ROUND
			ln.begin_cap_mode = Line2D.LINE_CAP_ROUND
			ln.end_cap_mode = Line2D.LINE_CAP_ROUND
			ln.antialiased = true
		return ln
	
	var bezier_curve = func(start: Vector2, end: Vector2, segments: int = 12) -> PackedVector2Array:
		var mid = (start + end) * 0.5
		var perpendicular = Vector2(-(end - start).normalized().y, (end - start).normalized().x)
		var curve_amount = sin(start.x * 0.01 + start.y * 0.01) * 20.0
		var control = mid + perpendicular * curve_amount
		
		var points = PackedVector2Array()
		for i in range(segments + 1):
			var t = float(i) / float(segments)
			points.append(start.lerp(control, t).lerp(control.lerp(end, t), t))
		return points
	
	if organic_layout:
		for e in edges:
			var curve_points = bezier_curve.call(pos[e[0]], pos[e[1]])
			edges_root.add_child(create_line.call(curve_points, 8.0, Color(0.4, 0.35, 0.3, 0.6), true))
	else:
		for e in edges:
			edges_root.add_child(create_line.call(PackedVector2Array([pos[e[0]], pos[e[1]]]), 2.0))

func _create_path_width_curve() -> Curve:
	var curve = Curve.new()
	# Taper at the ends like a natural path
	curve.add_point(Vector2(0.0, 0.7))
	curve.add_point(Vector2(0.5, 1.0))
	curve.add_point(Vector2(1.0, 0.7))
	return curve

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
	
	# Disable map interaction and hide map
	map_interaction_enabled = false
	set_process_mode(PROCESS_MODE_DISABLED)
	hide()
	
	#Hide any active events (they're children of root, not map)
	var root = get_tree().root
	var hidden_events = []
	for child in root.get_children():
		if child is Control and child.has_method("display_event"):
			child.hide()
			hidden_events.append(child)
	
	# Spawn deck creator
	var deck_scene := preload("res://scenes/DeckCreater/deck_creater.tscn")
	var deck_ui := deck_scene.instantiate()
	root.add_child(deck_ui)
	
	# Set up the deck creator
	deck_ui.set_owned_hands(Globals.inventory)
	
	# Connect to close signal
	deck_ui.tree_exited.connect(func():
		map_interaction_enabled = true
		set_process_mode(PROCESS_MODE_INHERIT)
		show()
		
		#Restore hidden events
		for event in hidden_events:
			if is_instance_valid(event):
				event.show()
		
		print("[Map] Deck builder closed, map interaction restored")
	)
	# Connect to close signal
	deck_ui.tree_exited.connect(func():
		map_interaction_enabled = true
		set_process_mode(PROCESS_MODE_INHERIT)
		show()
		
		#Restore hidden events
		for event in hidden_events:
			if is_instance_valid(event):
				event.show()
		
		print("[Map] Deck builder closed, map interaction restored")
	)

#func _on_deck_confirmed(deck: Array[HandData]) -> void:
#	print("Deck confirmed with %d cards" % deck.size())
#	Globals.current_deck = deck

#func _set_map_interaction(active: bool) -> void:
#	map_interaction_enabled = active
#	#for n in encounters_root.get_children():
#	#	n.mouse_filter = Control.MOUSE_FILTER_PASS if active else Control.MOUSE_FILTER_IGNORE
