extends Node2D

@export_group("Map Generation Settings")
@export var radial_layout := false  ##Use circular/radial branching instead of linear
@export var layers := 7 ##Number of layers/nodes down the map if linear layout
@export var max_width := 4 ##Maximum width of the map if linear layout
@export var min_endpoints := 1  ##Minimum number of endpoint nodes
@export var max_endpoints := 3  ##Maximum number of endpoint nodes
@export var nodes_per_ring := 8  ##Base number of nodes per ring
@export var ring_radius := 200.0  ##Distance between rings
@export var radial_rings := 4  ##Number of concentric rings for radial layout
@export var angle_randomness := 10 ##Range of random angle offset for branches, from - to + value in degrees
@export var min_node_separation := 80.0  ##Minimum distance between nodes
@export var x_spacing := 140.0 ##Spacing between nodes in the X direction
@export var y_spacing := 140.0 ##Spacing between nodes in the Y direction
@export var organic_layout := true ##Use organic/randomized layout instead of grid-like
@export var x_randomness := 90.0 ##Randomness factor for node positioning in the X direction
@export var y_randomness := 70.0 ##Randomness factor for node positioning in the Y direction
@export var path_texture: Texture2D ##Texture for map paths
@export var seed := -1 ##If set to positive number, will generate from seed, otherwise random
@export var encounter_scene: PackedScene

@onready var edges_root := $Edges
@onready var encounters_root := $Encounters
@onready var background := $Background
@onready var deck_button: Button = $DeckButton
@onready var almanac_button: Button = $AlmanacButton

var almanac_ui: Control

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
	deck_button.pressed.connect(_on_deck_button_pressed)
	almanac_button.pressed.connect(_on_almanac_button_pressed)
	setup()
	$Cam.make_current()

func setup():
	_generate()
	_draw_edges()
	_spawn_encounters()
	_unlock_starts()
	
	#Generate terrain background based on map
	if background:
		background.set_graph(pos, edges)
	
	deck_button.pressed.connect(_on_deck_button_pressed)

##Generate unique node ID based on layer and index
func _rid(i, j):
	return "L%02d_N%02d" % [i, j]

##Generates a map based on seed, or randomly if seed is set to negative values
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
	
	if radial_layout:
		_generate_radial(rng)
	else:
		_generate_linear(rng)

##Generate radial/circular branching map with diverging paths
func _generate_radial(rng: RandomNumberGenerator):
	var origin := Vector2(0, 0)
	
	#Determine number of branches
	var num_branches = rng.randi_range(min_endpoints, max_endpoints)
	
	#Single start node at center
	var start_id = "START"
	layer_ids.append([start_id])
	counts.append(1)
	pos[start_id] = origin
	etype[start_id] = "Start"

	#Independent branches
	var node_counter = 0
	for branch_idx in range(num_branches):
		#Calulate base angle
		var base_angle = (float(branch_idx) / num_branches) * TAU - PI/4 + rng.randf_range(-angle_randomness, angle_randomness) * DEG2RAD
		
		var prev_ring_nodes = [start_id]
		
		#Generate rings
		for ring in range(1, radial_rings):
			var is_final_ring = (ring == radial_rings - 1)
			
			#Layer tracking
			while layer_ids.size() <= ring:
				layer_ids.append([])
				counts.append(0)
			
			#Determine number of nodes in branch ring
			var nodes_in_ring = 1
			if ring == 1:
				#First ring, sometimes split into 2 nodes
				if num_branches <= 2 and rng.randf() < 0.4:
					nodes_in_ring = 2
			elif ring < radial_rings - 1:
				#Middle rings, splits based on previous ring
				var split_chance = 0.35 if prev_ring_nodes.size() == 1 else 0.15
				if rng.randf() < split_chance:
					nodes_in_ring = prev_ring_nodes.size() + 1
				else:
					nodes_in_ring = prev_ring_nodes.size()
				nodes_in_ring = min(nodes_in_ring, 3)
			else:
				nodes_in_ring = 1
			
			var current_ring_nodes = []
			
			for node_idx in range(nodes_in_ring):
				#Create unique ID
				var id = "B%d_R%d_N%d" % [branch_idx, ring, node_idx]
				node_counter += 1
				
				#Calculate angle for this node
				var angle = base_angle
				if nodes_in_ring > 1:
					#Spread nodes around base angle
					var spread = 0.5 if ring < 3 else 0.7
					angle += (node_idx - (nodes_in_ring - 1) * 0.5) * spread / num_branches
				
				#Add slight randomness
				angle += rng.randf_range(-0.08, 0.08)
				
				#Calculate radius
				var radius = ring * ring_radius
				if organic_layout:
					radius += rng.randf_range(-ring_radius * 0.15, ring_radius * 0.15)
				
				#Calculate position with minimum separation check
				var candidate_pos = origin + Vector2(cos(angle), sin(angle)) * radius
				var attempts = 0
				var max_attempts = 30
				
				#Ensure node is separated enough from others in same ring
				while attempts < max_attempts:
					var too_close = false
					#Check against nodes in same ring
					if layer_ids.size() > ring and layer_ids[ring].size() > 0:
						for existing_id in layer_ids[ring]:
							if pos.has(existing_id):
								var dist = pos[existing_id].distance_to(candidate_pos)
								if dist < min_node_separation:
									too_close = true
									break
					
					if not too_close:
						break
					
					#If too close, try again
					angle += rng.randf_range(-0.2, 0.2)
					radius += rng.randf_range(-30, 30)
					candidate_pos = origin + Vector2(cos(angle), sin(angle)) * max(radius, 50.0)
					attempts += 1
				
				pos[id] = candidate_pos

				#Set encounter type
				if is_final_ring:
					etype[id] = "Boss"
				else:
					var r = rng.randf()
					etype[id] = "Event" if r < 0.25 else "Shop" if r < 0.4 else "Combat"

				#Add to tracking
				layer_ids[ring].append(id)
				counts[ring] += 1
				current_ring_nodes.append(id)
			
			#Create connections from previous ring to current ring
			if prev_ring_nodes.size() == 1 and current_ring_nodes.size() == 1:
				#1 to 1: Simple connection
				edges.append([prev_ring_nodes[0], current_ring_nodes[0]])
			elif prev_ring_nodes.size() == 1 and current_ring_nodes.size() > 1:
				#1 to Many: Connect to all
				for curr_id in current_ring_nodes:
					edges.append([prev_ring_nodes[0], curr_id])
			elif prev_ring_nodes.size() > 1 and current_ring_nodes.size() == 1:
				#Many to 1: All paths converge to one node
				for prev_id in prev_ring_nodes:
					edges.append([prev_id, current_ring_nodes[0]])
			else:
				#Many to Many: Connect each prev to 1-2 nearest current nodes
				for prev_id in prev_ring_nodes:
					var prev_pos = pos[prev_id]
					var distances = []
					for curr_id in current_ring_nodes:
						distances.append({"id": curr_id, "dist": prev_pos.distance_to(pos[curr_id])})
					distances.sort_custom(func(a, b): return a.dist < b.dist)
					
					#Connect to closest
					edges.append([prev_id, distances[0].id])
					#Sometimes connect to second closest aswell
					if distances.size() > 1 and rng.randf() < 0.4:
						edges.append([prev_id, distances[1].id])

			#Update for next iteration
			prev_ring_nodes = current_ring_nodes
	
	print("[Map] Generated radial map with %d branches, %d total nodes" % [num_branches, node_counter + 1])

##Generate traditional linear branching map
func _generate_linear(rng: RandomNumberGenerator):
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

	var origin := Vector2(0, 0)
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

	_ensure_connectivity(rng)

##Ensure every node (except start) has at least one incoming edge
func _ensure_connectivity(rng: RandomNumberGenerator):
	var inbound = {}
	for e in edges: 
		inbound[e[1]] = true
	
	var num_layers = layer_ids.size()
	for i in range(1, num_layers):
		for t in layer_ids[i]:
			if not inbound.has(t):
				#Connect orphan to closest
				var best = layer_ids[i - 1][0]
				var best_d = 1e9
				for f in layer_ids[i - 1]:
					var d = pos[f].distance_to(pos[t])
					if d < best_d: 
						best_d = d
						best = f
				edges.append([best, t])

##Create mapping from one count to another
func _map_index(j, from_count, to_count):
	if to_count == 1:
		return 0
	if from_count == 1:
		return int((to_count - 1) / 2)  # center
	# keep relative column across different widths
	var t = float(j) * float(to_count - 1) / float(from_count - 1)
	return int(round(t))

##Draw edges between nodes
func _draw_edges():
	for c in edges_root.get_children():
		c.queue_free()
	
	#Create line with optional curve
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
	
	var bezier_curve = func(start: Vector2, end: Vector2, segments: int = 16) -> PackedVector2Array:
		var mid = (start + end) * 0.5
		var perpendicular = Vector2(-(end - start).normalized().y, (end - start).normalized().x)
		var curve_amount = sin(start.x * 0.01 + start.y * 0.01) * 20.0
		var control = mid + perpendicular * curve_amount
		
		var points = PackedVector2Array()
		for i in range(segments + 1):
			var t = float(i) / float(segments)
			var point = start.lerp(control, t).lerp(control.lerp(end, t), t)
			
			#Push path away from nearby nodes, not including start/end nodes
			for node_id in pos.keys():
				var node_pos = pos[node_id]
				#Skip if start or end node
				if node_pos.distance_to(start) < 5 or node_pos.distance_to(end) < 5:
					continue
				
				var dist_to_node = point.distance_to(node_pos)
				var push_radius = 40.0  #Radius within which to push the path away
				
				if dist_to_node < push_radius:
					#Push the point away from the node
					var push_dir = (point - node_pos).normalized()
					var push_strength = (push_radius - dist_to_node) / push_radius
					point += push_dir * push_strength * 30.0
			
			points.append(point)
		return points
	
	if organic_layout:
		for e in edges:
			var curve_points = bezier_curve.call(pos[e[0]], pos[e[1]])
			edges_root.add_child(create_line.call(curve_points, 8.0, Color(0.4, 0.35, 0.3, 0.6), true))
	else:
		for e in edges:
			edges_root.add_child(create_line.call(PackedVector2Array([pos[e[0]], pos[e[1]]]), 2.0))

###Create a curve for path width variation
func _create_path_width_curve() -> Curve:
	var curve = Curve.new()
	# Taper at the ends like a natural path
	curve.add_point(Vector2(0.0, 0.7))
	curve.add_point(Vector2(0.5, 1.0))
	curve.add_point(Vector2(1.0, 0.7))
	return curve


##Spawn encounter nodes based on generated map
func _spawn_encounters():
	for c in encounters_root.get_children():
		c.queue_free()
	
	#Spawn encounters for all nodes in pos dictionary
	for id in pos.keys():
		var node = encounter_scene.instantiate()
		node.position = pos[id]
		node.encounter_id = id
		node.encounter_type = _etype_to_dropdown(etype[id])
		node.clicked.connect(_on_encounter_clicked)
		encounters_root.add_child(node)
		reachable[id] = false
		cleared[id] = false

##Unlock starting nodes
func _unlock_starts():
	for id in layer_ids[0]:
		reachable[id] = true
	_apply_state_to_nodes()


##Update encounter nodes based on current state
func _apply_state_to_nodes():
	for n in encounters_root.get_children():
		n.set_reachable(reachable.get(n.encounter_id, false))
		n.set_cleared(cleared.get(n.encounter_id, false))

##Handle encounter node click
func _on_encounter_clicked(id):
	
	if not map_interaction_enabled:
		print("Map interaction disabled - click ignored")
		return
	
	cleared[id] = true
	reachable[id] = false
	var layer_idx = _layer_of(id)

	# lock siblings in same layer
	if layer_idx >= 0 and layer_idx < layer_ids.size():
		for other in layer_ids[layer_idx]:
			if other != id:
				reachable[other] = false

	# unlock connected nodes in next layers
	for e in edges:
		if e[0] == id:
			reachable[e[1]] = true

	_apply_state_to_nodes()
	# print("Enter:", etype[id], id)

##Get layer index from node ID
func _layer_of(id: String) -> int:
	#Special case for start node	
	if id == "START":
		return 0
	#Layout is linear
	if id.begins_with("L"):
		# Linear format: "L01_N02"
		return int(id.substr(1, 2))
	#Layout is radial
	elif id.begins_with("B"):
		var parts = id.split("_")
		if parts.size() >= 2:
			return int(parts[1].substr(1))
	push_error("Invalid node ID format: %s" % id)	
	return -1

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

##Handle encounter finished signal
func _on_encounter_finished(result):
	if result.type == "Boss":
		for i in edges_root.get_children():
			i.queue_free()
		for i in encounters_root.get_children():
			i.queue_free()
		setup()

##Deck and Almanac button handlers
func _on_deck_button_pressed() -> void:
	print("Opening deck builder")
	DeckCreater._show_overlay()

##Almanac button handler
func _on_almanac_button_pressed() -> void:
	print("pressed button")
	AlmanacOverlay._show_overlay()
