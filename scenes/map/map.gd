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

@export_group("Fog of War Settings")
@export var enable_fog_of_war := true ##Enable shader-based fog of war effect
@export var reveal_radius := 150.0 ##Radius of visibility around revealed nodes
@export var fade_distance := 100.0 ##Distance over which fog fades
@export var fog_color := Color(0.0, 0.0, 0.0, 0.95) ##Color and opacity of the fog
@export var vignette_strength := 0.8 ##Strength of vignette darkening at edges

@onready var edges_root := $Edges
@onready var encounters_root := $Encounters
@onready var background := $Background
@onready var deck_button: Button = $DeckButton
@onready var almanac_button: Button = $AlmanacButton
@onready var fog_overlay: ColorRect = $FogOfWarContainer/FogOverlay
@onready var generating_label: Label = $GeneratingLabel

var almanac_ui: Control
var map_generator: Node  # MapGenerator instance

var layer_ids = []
var counts = []
var pos = {}
var etype = {}
var edges = []
var reachable = {}
var cleared = {}

var map_interaction_enabled := true

# Fog of war
var fog_material: ShaderMaterial
var revealed_nodes: Array[String] = []


func _ready():
	add_to_group("map")
	EncounterHandler.encounter_finished.connect(_on_encounter_finished)	
	deck_button.pressed.connect(_on_deck_button_pressed)
	almanac_button.pressed.connect(_on_almanac_button_pressed)
	
	# Initialize MapGenerator
	var MapGeneratorClass = load("res://scenes/map/map_generator.gd")
	map_generator = MapGeneratorClass.new()
	add_child(map_generator)
	
	$Cam.make_current()
	setup()
	_setup_fog_of_war()

func _process(_delta):
	# Update fog shader positions continuously to account for camera movement
	if enable_fog_of_war and fog_material:
		_update_fog_overlay_size()
		_update_fog_shader()

func setup():
	_generate()
	_draw_edges()
	_spawn_encounters()
	_unlock_starts()
	
	#Generate terrain background based on map
	if background:
		background.set_graph(pos, edges)

func _setup_fog_of_war():
	if not enable_fog_of_war:
		return
	
	fog_material = fog_overlay.material as ShaderMaterial
	revealed_nodes.clear()
	if layer_ids.size() > 0:
		for id in layer_ids[0]:
			revealed_nodes.append(id)
	
	await get_tree().process_frame
	_update_fog_overlay_size()
	_update_fog_shader()

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
	
	#Setup generator parameters
	map_generator.radial_layout = radial_layout
	map_generator.layers = layers
	map_generator.max_width = max_width
	map_generator.min_endpoints = min_endpoints
	map_generator.max_endpoints = max_endpoints
	map_generator.radial_rings = radial_rings
	map_generator.ring_radius = ring_radius
	map_generator.angle_randomness = angle_randomness
	map_generator.min_node_separation = min_node_separation
	map_generator.x_spacing = x_spacing
	map_generator.y_spacing = y_spacing
	map_generator.organic_layout = organic_layout
	map_generator.x_randomness = x_randomness
	map_generator.y_randomness = y_randomness
	
	#Generate map using MapGenerator
	var map_data = map_generator.generate(rng)
	
	#Extract generated data
	layer_ids = map_data.layer_ids
	counts = map_data.counts
	pos = map_data.pos
	etype = map_data.etype
	edges = map_data.edges

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
	
	#Spliced bezier curves for smooth paths
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
		return
	
	cleared[id] = true
	reachable[id] = false
	var layer_idx = _layer_of(id)

	#Lock nodes in same layer
	if layer_idx >= 0 and layer_idx < layer_ids.size():
		for other in layer_ids[layer_idx]:
			if other != id:
				reachable[other] = false

	#Unlock next nodes
	for e in edges:
		if e[0] == id:
			reachable[e[1]] = true
			#Reveal nodes
			if enable_fog_of_war and not revealed_nodes.has(e[1]):
				revealed_nodes.append(e[1])

	_apply_state_to_nodes()
	_update_fog_shader()

##Update fog overlay size and position to match camera view
func _update_fog_overlay_size():
	if not fog_overlay:
		return
	
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	var viewport = get_viewport()
	var viewport_size = viewport.get_visible_rect().size
	

	#Ensure fog overlay covers entire viewport
	var cam_zoom = camera.zoom
	var world_view_size = viewport_size / cam_zoom
	
	var extended_size = world_view_size * 4.0
	
	fog_overlay.position = camera.global_position - extended_size / 2.0
	fog_overlay.size = extended_size

##Update the fog of war shader with current revealed positions
func _update_fog_shader():
	if not enable_fog_of_war or not fog_material or not fog_overlay:
		return
	
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	var viewport_size = get_viewport().get_visible_rect().size
	
	#Pass world positions to shader
	var world_positions: PackedVector2Array = PackedVector2Array()
	for node_id in revealed_nodes:
		if pos.has(node_id):
			world_positions.append(pos[node_id])
	
	#Update shader parameters
	fog_material.set_shader_parameter("revealed_count", world_positions.size())
	fog_material.set_shader_parameter("fog_offset", fog_overlay.position)
	fog_material.set_shader_parameter("fog_size", fog_overlay.size)
	fog_material.set_shader_parameter("viewport_size", viewport_size)
	fog_material.set_shader_parameter("camera_position", camera.global_position)
	
	while world_positions.size() < 64:
		world_positions.append(Vector2.ZERO)
	
	fog_material.set_shader_parameter("revealed_positions", world_positions)

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
		
		# Reset fog of war to show only start nodes
		if enable_fog_of_war:
			revealed_nodes.clear()
		
		setup()
		
		# Re-reveal start nodes after regeneration
		if enable_fog_of_war and layer_ids.size() > 0:
			for id in layer_ids[0]:
				revealed_nodes.append(id)
			_update_fog_shader()

##Deck and Almanac button handlers
func _on_deck_button_pressed() -> void:
	print("Opening deck builder")
	DeckCreater._show_overlay()

##Almanac button handler
func _on_almanac_button_pressed() -> void:
	print("pressed button")
	AlmanacOverlay._show_overlay()
