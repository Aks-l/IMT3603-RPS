## Generates procedural map layouts (linear or radial)
class_name MapGenerator
extends Node

# Generation settings
@export var radial_layout: bool = false
@export var layers: int = 7
@export var max_width: int = 4
@export var min_endpoints: int = 1
@export var max_endpoints: int = 3
@export var nodes_per_ring: int = 8
@export var ring_radius: float = 200.0
@export var radial_rings: int = 4
@export var angle_randomness: float = 10.0
@export var min_node_separation: float = 80.0
@export var x_spacing: float = 140.0
@export var y_spacing: float = 140.0
@export var organic_layout: bool = true
@export var x_randomness: float = 90.0
@export var y_randomness: float = 70.0
@export var seed_value: int = -1

# Output data
var layer_ids = []
var counts = []
var pos = {}
var etype = {}
var edges = []

##Setup generation parameters, with defaults
func setup_parameters(settings: Dictionary):
	radial_layout = settings.get("radial_layout", false)
	layers = settings.get("layers", 7)
	max_width = settings.get("max_width", 4)
	min_endpoints = settings.get("min_endpoints", 1)
	max_endpoints = settings.get("max_endpoints", 3)
	nodes_per_ring = settings.get("nodes_per_ring", 8)
	ring_radius = settings.get("ring_radius", 200.0)
	radial_rings = settings.get("radial_rings", 4)
	angle_randomness = settings.get("angle_randomness", 10.0)
	min_node_separation = settings.get("min_node_separation", 80.0)
	x_spacing = settings.get("x_spacing", 140.0)
	y_spacing = settings.get("y_spacing", 140.0)
	organic_layout = settings.get("organic_layout", true)
	x_randomness = settings.get("x_randomness", 90.0)
	y_randomness = settings.get("y_randomness", 70.0)
	seed_value = settings.get("seed", -1)

##Generate the map layout
func generate(rng: RandomNumberGenerator = null) -> Dictionary:
	if rng == null:
		rng = RandomNumberGenerator.new()
		if seed_value >= 0:
			rng.seed = seed_value
		else:
			rng.randomize()
	
	layer_ids.clear()
	counts.clear()
	pos.clear()
	etype.clear()
	edges.clear()
	
	if radial_layout:
		_generate_radial(rng)
	else:
		_generate_linear(rng)
	
	return {
		"layer_ids": layer_ids,
		"counts": counts,
		"pos": pos,
		"etype": etype,
		"edges": edges
	}

##Generate radial layout
func _generate_radial(rng: RandomNumberGenerator):
	var origin := Vector2.ZERO
	var num_branches = rng.randi_range(min_endpoints, max_endpoints)
	
	#Start node in center
	var start_id = "START"
	layer_ids.append([start_id])
	counts.append(1)
	pos[start_id] = origin
	etype[start_id] = "Start"
	
	#Track nodes per ring
	var all_ring_nodes = {}
	
	#Branching out from center
	for branch_idx in range(num_branches):
		var base_angle = (float(branch_idx) / num_branches) * TAU - PI/4 + rng.randf_range(-angle_randomness, angle_randomness) * PI / 180.0
		var prev_ring_nodes = [start_id]
		
		for ring in range(1, radial_rings):
			#Layer setup
			if layer_ids.size() <= ring:
				layer_ids.append([])
				counts.append(0)
			
			if not all_ring_nodes.has(ring):
				all_ring_nodes[ring] = []
			
			#Nodes in this ring
			var nodes_in_ring = 1 if ring == radial_rings - 1 else clamp(prev_ring_nodes.size() + (1 if rng.randf() < (0.35 if prev_ring_nodes.size() == 1 else 0.15) and ring > 1 else 0), 1, 3) if ring > 1 else (2 if num_branches <= 2 and rng.randf() < 0.4 else 1)
			
			var current_ring_nodes = []
			for node_idx in range(nodes_in_ring):
				var id = "B%d_R%d_N%d" % [branch_idx, ring, node_idx]
				
				#Randomize angle and radius
				var angle = base_angle + (node_idx - (nodes_in_ring - 1) * 0.5) * (0.5 if ring < 3 else 0.7) / num_branches if nodes_in_ring > 1 else base_angle
				angle += rng.randf_range(-0.08, 0.08)
				var radius = ring * ring_radius + (rng.randf_range(-ring_radius * 0.15, ring_radius * 0.15) if organic_layout else 0.0)
				
				#Find valid position
				var candidate_pos = origin + Vector2(cos(angle), sin(angle)) * radius
				for _attempt in range(30):
					var valid = true
					for existing_id in all_ring_nodes[ring]:
						if pos.has(existing_id) and pos[existing_id].distance_to(candidate_pos) < min_node_separation:
							valid = false
							break
					if valid:
						break
					angle += rng.randf_range(-0.2, 0.2)
					candidate_pos = origin + Vector2(cos(angle), sin(angle)) * max(radius + rng.randf_range(-30, 30), 50.0)
				
				pos[id] = candidate_pos
				etype[id] = "Boss" if ring == radial_rings - 1 else (["Event", "Shop", "Combat"][[0.25, 0.4, 1.0].map(func(t): return rng.randf() < t).find(true)])
				all_ring_nodes[ring].append(id)
				current_ring_nodes.append(id)
			
			#Connect rings
			var p = prev_ring_nodes.size()
			var c = current_ring_nodes.size()
			if p == 1 and c == 1:
				edges.append([prev_ring_nodes[0], current_ring_nodes[0]])
			elif p == 1:
				for curr in current_ring_nodes:
					edges.append([prev_ring_nodes[0], curr])
			elif c == 1:
				for prev in prev_ring_nodes:
					edges.append([prev, current_ring_nodes[0]])
			else:
				for prev in prev_ring_nodes:
					var sorted = current_ring_nodes.duplicate()
					sorted.sort_custom(func(a, b): return pos[prev].distance_to(pos[a]) < pos[prev].distance_to(pos[b]))
					edges.append([prev, sorted[0]])
					if sorted.size() > 1 and rng.randf() < 0.4:
						edges.append([prev, sorted[1]])
			
			prev_ring_nodes = current_ring_nodes
	
	#Finalize layer data
	for ring in range(1, radial_rings):
		if all_ring_nodes.has(ring):
			layer_ids[ring] = all_ring_nodes[ring]
			counts[ring] = all_ring_nodes[ring].size()
	
	_ensure_connectivity(rng)

##Generate linear layout
func _generate_linear(rng: RandomNumberGenerator):
	var mid := int(layers / 2)
	var w := 1

    #Number of nodes per layer
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

    #Node positions and types
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
				var r = rng.randf()
				etype[id] = "Event" if r < 0.2 else "Shop" if r < 0.3 else "Combat"
		layer_ids.append(ids)

	#Connecting layers
	if organic_layout:
		#Use distance based connections
		for i in range(layers - 1):
			var from_layer = layer_ids[i]
			var to_layer = layer_ids[i + 1]
			
			for from_id in from_layer:
				var from_pos = pos[from_id]
				
				#Find nearest nodes in next layer
				var distances = []
				for to_id in to_layer:
					var dist = from_pos.distance_to(pos[to_id])
					distances.append({"id": to_id, "dist": dist})
				distances.sort_custom(func(a, b): return a.dist < b.dist)
				
				#Connect to closest
				edges.append([from_id, distances[0].id])
				
				#Maybe connect to others
				if i < int(layers / 2):  #Branching more early
					#2nd
					if distances.size() > 1 and rng.randf() < 0.4:
						edges.append([from_id, distances[1].id])
					
					#3rd
					if distances.size() > 2 and rng.randf() < 0.2:
						edges.append([from_id, distances[2].id])
				else:
					#Less branching later
					if distances.size() > 1 and rng.randf() < 0.25:
						edges.append([from_id, distances[1].id])
	else:
		#Column based connections
		for i in range(layers - 1):
			var c_from = counts[i]
			var c_to = counts[i + 1]
			for j in range(c_from):
				var from_id = _rid(i, j)
				#Assign to mapped target
				var base_tj = _map_index(j, c_from, c_to)
				edges.append([from_id, _rid(i + 1, base_tj)])

				#Extend connections
				if i < int(layers / 2):
					if base_tj - 1 >= 0 and rng.randf() < 0.35:
						edges.append([from_id, _rid(i + 1, base_tj - 1)])
					if base_tj + 1 < c_to and rng.randf() < 0.35:
						edges.append([from_id, _rid(i + 1, base_tj + 1)])
	
	_ensure_connectivity(rng)

##Ensure all nodes have at least one inbound connection
func _ensure_connectivity(rng: RandomNumberGenerator):
	var inbound = {}
	for e in edges:
		inbound[e[1]] = true
	
	var num_layers = layer_ids.size()
	for i in range(1, num_layers):
		for t in layer_ids[i]:
			if not inbound.has(t):
				var best = layer_ids[i - 1][0]
				var best_d = 1e9

				for f in layer_ids[i - 1]:
					var d = pos[f].distance_to(pos[t])
					if d < best_d:
						best_d = d
						best = f
                        
				edges.append([best, t])

##Map index mapping helper
func _map_index(j, from_count, to_count):
	if to_count == 1:
		return 0

	if from_count == 1:
		return int((to_count - 1) / 2)
	var t = float(j) * float(to_count - 1) / float(from_count - 1)
	return int(round(t))

##Generate node rid
func _rid(i, j):
	return "L%02d_N%02d" % [i, j]
