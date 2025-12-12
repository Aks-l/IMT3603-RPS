extends Node2D
@export var width:float = 36.0
@export var room_r:float = 100.0
@export var noise_strength: float = 8.0
@export var noise_segments: int = 32

@export_group("Terrain Generation")
@export var ocean_color: Color
@export var shallow_water_color: Color
@export var sand_color: Color
@export var grass_color: Color
@export var forest_color: Color
@export var hill_color: Color
@export var mountain_color: Color
@export var snow_color: Color
@export var terrain_resolution: Vector2i = Vector2i(512, 512)
@export var ocean_margin: float = 1200.0
@export var terrain_scale: float = 3.0
@export var elevation_frequency: float = 0.004
@export var landmass_padding: float = 900.0
@export var edge_roughness: float = 120.0
@export var continent_arms: int = 5
@export var island_count: int = 4
@export var coast_width: float = 40.0

var positions := {}
var edges := []
var terrain_texture: ImageTexture
var noise_generator: TerrainNoiseGenerator
var island_centers: Array = []
var shared_image: Image
var thread_mutex: Mutex = Mutex.new()
var active_threads: Array[Thread] = []
var completed_threads: int = 0
var total_threads: int = 0

func _ready() -> void:
	_initialize_noise_generator()

func _initialize_noise_generator() -> void:
	#Create TerrainNoiseGenerator
	noise_generator = TerrainNoiseGenerator.new()
	noise_generator.elevation_frequency = elevation_frequency
	add_child(noise_generator)
	noise_generator._initialize_noise_generators()

##Apply colors to palette based on biome
func set_palette(b: BiomeData) -> void:
	ocean_color = b.ocean_color
	shallow_water_color = b.shallow_water_color
	sand_color = b.sand_color
	grass_color = b.grass_color
	forest_color = b.forest_color
	hill_color = b.hill_color
	mountain_color = b.mountain_color
	snow_color = b.snow_color

##Set the graph data and start terrain generation
func set_graph(p:Dictionary, e:Array) -> void:
	positions = p
	edges = e
	_generate_terrain_texture_async()
	queue_redraw()

##Asynchronous terrain generation
func _generate_terrain_texture_async() -> void:
	if positions.is_empty():
		return
	
	#Pre-calculate shared data
	var get_bounds = func() -> Array:
		var min_p := Vector2.INF
		var max_p := Vector2(-INF, -INF)
		for pos_vec in positions.values():
			min_p = min_p.min(pos_vec)
			max_p = max_p.max(pos_vec)
		return [min_p, max_p]
	
	var bounds: Array = get_bounds.call()
	var min_pos: Vector2 = bounds[0]
	var max_pos: Vector2 = bounds[1]
	var center: Vector2 = (min_pos + max_pos) * 0.5
	
	#Generate island centers once
	island_centers = range(island_count).map(func(_i):
		var angle := randf() * TAU
		var distance := ocean_margin * terrain_scale * (0.4 + randf() * 0.4)
		return center + Vector2.from_angle(angle) * distance
	)
	
	var scaled_margin := ocean_margin * terrain_scale
	min_pos -= Vector2.ONE * scaled_margin
	max_pos += Vector2.ONE * scaled_margin
	
	#Create shared image
	shared_image = Image.create(terrain_resolution.x, terrain_resolution.y, true, Image.FORMAT_RGBA8)
	
	#Use half available cores
	var thread_count = max(1, OS.get_processor_count() / 2)
	total_threads = thread_count
	completed_threads = 0
	
	#Show generating label if parent has one
	var parent_map = get_parent()
	if parent_map and parent_map.has_node("GeneratingLabel"):
		parent_map.get_node("GeneratingLabel").visible = true
	
	active_threads.clear()
	for i in range(thread_count):
		var thread = Thread.new()
		active_threads.append(thread)
		thread.start(_generate_terrain_texture_threaded.bind(i, thread_count, min_pos, max_pos))
	
##Threaded terrain generation
func _generate_terrain_texture_threaded(thread_id: int, thread_count: int, min_pos: Vector2, max_pos: Vector2) -> void:
	var map_size: Vector2 = max_pos - min_pos
	
	#Determine rows to process
	var rows_per_thread = terrain_resolution.y / thread_count
	var start_y = thread_id * rows_per_thread
	var end_y = start_y + rows_per_thread if thread_id < thread_count - 1 else terrain_resolution.y
	
	# Convert pixel coordinates to world position
	var pixel_to_world = func(x: int, y: int) -> Vector2:
		return min_pos + Vector2(
			(float(x) / terrain_resolution.x) * map_size.x,
			(float(y) / terrain_resolution.y) * map_size.y
		)
	
	# Sample multiple noise layers for elevation
	var get_elevation = func(world_pos: Vector2) -> float:
		var elev := noise_generator.elevation_noise.get_noise_2d(world_pos.x, world_pos.y) * 0.5 + 0.5
		var detail := noise_generator.detail_noise.get_noise_2d(world_pos.x, world_pos.y) * 0.4
		var variation := noise_generator.edge_noise.get_noise_2d(world_pos.x * 2.0, world_pos.y * 2.0) * 0.2
		return pow(elev, 0.4) + detail + variation
	
	for y in range(start_y, end_y):
		for x in range(terrain_resolution.x):
			var world_pos: Vector2 = pixel_to_world.call(x, y)
			var land_factor := _get_land_factor(world_pos)
			var elevation: float = get_elevation.call(world_pos)
			var color = _get_terrain_color(land_factor, elevation)
			
			#Share image
			thread_mutex.lock()
			shared_image.set_pixel(x, y, color)
			thread_mutex.unlock()
	
	call_deferred("_on_thread_completed")


##Update after thread completion
func _on_thread_completed() -> void:
	completed_threads += 1
	
	#Update texture
	if not terrain_texture:
		terrain_texture = ImageTexture.create_from_image(shared_image)
	else:
		terrain_texture.update(shared_image)
	queue_redraw()
	
	if completed_threads >= total_threads:
		#Clean up
		for thread in active_threads:
			thread.wait_to_finish()
		active_threads.clear()

		shared_image.generate_mipmaps()
		terrain_texture.update(shared_image)
		queue_redraw()
		
		#Hide generating label
		var parent_map = get_parent()
		if parent_map and parent_map.has_node("GeneratingLabel"):
			parent_map.get_node("GeneratingLabel").visible = false

##Distance from point to nearest path
func _distance_to_path(point: Vector2) -> float:
	var min_dist := INF
	
	#Distance to nodes
	for pos_vec in positions.values():
		var dist := point.distance_to(pos_vec)
		min_dist = min(min_dist, dist)
	
	#Distance to edges
	for edge in edges:
		var a: Vector2 = positions[edge[0]]
		var b: Vector2 = positions[edge[1]]
		var dist := _point_to_segment_distance(point, a, b)
		min_dist = min(min_dist, dist)
	
	return min_dist

##Calculate distance from point to line segment
func _point_to_segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var ap := point - a
	var proj := ap.dot(ab)
	var len_sq := ab.length_squared()
	
	if len_sq == 0:
		return point.distance_to(a)
	
	var t: float = clamp(proj / len_sq, 0.0, 1.0)
	var closest: Vector2 = a + ab * t
	return point.distance_to(closest)

##Calculate land factor at world position
func _get_land_factor(world_pos: Vector2) -> float:
	#Sample noise
	var get_noise = func(noise_gen: FastNoiseLite, scale_factor: float = 1.0) -> float:
		return noise_gen.get_noise_2d(world_pos.x * scale_factor, world_pos.y * scale_factor)
	
	#Distance to nodes
	var min_dist := INF
	for pos_vec in positions.values():
		min_dist = min(min_dist, world_pos.distance_to(pos_vec))
	
	#Distance to edges
	var total_distortion: float = get_noise.call(noise_generator.edge_noise) * edge_roughness + get_noise.call(noise_generator.detail_noise, 2.0) * edge_roughness * 0.4
	var node_influence := clampf(1.0 - (min_dist + total_distortion - room_r - 50.0) / (landmass_padding * 0.3), 0.0, 1.0)
	node_influence = pow(node_influence, 1.5)
	var center_pos := Vector2.ZERO
	for pos_vec in positions.values():
		center_pos += pos_vec
	center_pos /= positions.size()
	
	var from_center := world_pos - center_pos
	var dist_from_center := from_center.length()
	var angle_from_center := atan2(from_center.y, from_center.x)
	
	var arm_noise: float = get_noise.call(noise_generator.continent_noise, 0.005)
	var arm_strength: float = (sin(angle_from_center * continent_arms) * 0.2 + arm_noise * 0.6 + get_noise.call(noise_generator.edge_noise, 0.02) * 0.2)
	arm_strength = pow(arm_strength * 0.5 + 0.5, 1.2)
	
	var arm_extension: float = arm_strength * 600.0 + arm_noise * 400.0
	var continent_factor := clampf(1.0 - (dist_from_center - arm_extension) / (landmass_padding * 1.5), 0.0, 1.0)
	continent_factor = pow(continent_factor, 0.6)
	continent_factor = clampf(continent_factor + get_noise.call(noise_generator.continent_noise) * 0.6 + get_noise.call(noise_generator.detail_noise, 0.3) * 0.4, 0.0, 1.0)
	
	#Island influence
	var island_influence := 0.0
	for i in range(island_centers.size()):
		var island_pos: Vector2 = island_centers[i]
		var dist_to_island := world_pos.distance_to(island_pos)
		var island_angle := atan2((world_pos - island_pos).y, (world_pos - island_pos).x)
		
		var seed_offset := i * 1000.0
		var island_noise := noise_generator.edge_noise.get_noise_2d(island_pos.x + seed_offset, island_pos.y + seed_offset)
		var island_detail: float = get_noise.call(noise_generator.continent_noise, 0.05)
		
		var shape_freq := 2.0 + (island_noise + 1.0) * 2.0
		var island_shape := sin(island_angle * shape_freq + island_noise * 3.0) * 0.25 + sin(island_angle * shape_freq * 1.7 + island_detail * 2.0) * 0.15 + 0.7
		
		var island_size := (200.0 + island_noise * 150.0) * island_shape
		var island_dist_adjusted: float = dist_to_island + get_noise.call(noise_generator.detail_noise, 1.2) * 100.0
		
		if island_dist_adjusted < island_size:
			island_influence = max(island_influence, pow(1.0 - island_dist_adjusted / island_size, 0.4))
	
	return max(max(node_influence, continent_factor * 0.85), island_influence)

##Calculate terrain color based on land factor and elevation
func _get_terrain_color(land_factor: float, elevation: float) -> Color:
	#Interpolation helper
	var smooth_lerp = func(from_color: Color, to_color: Color, value: float, min_val: float, max_val: float) -> Color:
		var t := clampf((value - min_val) / (max_val - min_val), 0.0, 1.0)
		return from_color.lerp(to_color, smoothstep(0.0, 1.0, t))
	
	#Land colors
	if land_factor < 0.45:
		return ocean_color
	if land_factor < 0.55:
		return smooth_lerp.call(ocean_color, shallow_water_color, land_factor, 0.45, 0.55)
	if land_factor < 0.65:
		return smooth_lerp.call(shallow_water_color, sand_color, land_factor, 0.55, 0.65)
	
	var land_elev := clampf((elevation - 0.3) / 0.7, 0.0, 1.0)
	var bands := [
		[0.2, grass_color],
		[0.35, forest_color],
		[0.5, forest_color],
		[0.65, hill_color],
		[0.8, mountain_color],
		[0.92, mountain_color],
		[1.0, snow_color]
	]
	
	#Interpolate between bands
	for i in range(bands.size() - 1):
		if land_elev < bands[i + 1][0]:
			return smooth_lerp.call(bands[i][1], bands[i + 1][1], land_elev, bands[i][0], bands[i + 1][0])
	
	return snow_color

##Draw the map background
func _draw() -> void:
	if positions.is_empty():
		return
	
	# Draw the terrain texture as background
	if terrain_texture:
		# Calculate bounds for texture placement - use SAME bounds as generation
		var min_pos := Vector2.INF
		var max_pos := Vector2(-INF, -INF)
		for pos_vec in positions.values():
			min_pos.x = min(min_pos.x, pos_vec.x)
			min_pos.y = min(min_pos.y, pos_vec.y)
			max_pos.x = max(max_pos.x, pos_vec.x)
			max_pos.y = max(max_pos.y, pos_vec.y)
		
		# Apply SAME padding as terrain generation for full coverage
		var scaled_margin := ocean_margin * terrain_scale
		min_pos -= Vector2(scaled_margin, scaled_margin)
		max_pos += Vector2(scaled_margin, scaled_margin)
		var map_size := max_pos - min_pos
		
		# Draw terrain texture covering the entire generated area
		draw_texture_rect(terrain_texture, Rect2(min_pos, map_size), false)
	
	# Draw path overlay (optional - darker paths)
	var all_shapes: Array[PackedVector2Array] = []
	
	# Add corridor polygons
	for e in edges:
		var a:Vector2 = positions[e[0]]
		var b:Vector2 = positions[e[1]]
		all_shapes.append_array(_corridor_polys(a, b, width))
	
	# Add noisy room circles
	for id in positions.keys():
		all_shapes.append(_noisy_circle(positions[id], room_r))
	
	# Merge all shapes into one
	var merged := PackedVector2Array()
	if all_shapes.size() > 0:
		merged = all_shapes[0]
		for i in range(1, all_shapes.size()):
			var union_result := Geometry2D.merge_polygons(merged, all_shapes[i])
			if union_result.size() > 0:
				merged = union_result[0]
	
	# Draw the path overlay with semi-transparent dark color
	if merged.size() > 0:
		draw_colored_polygon(merged, Color(0.05, 0.06, 0.05, 0.4))

func _noisy_circle(center: Vector2, radius: float) -> PackedVector2Array:
	var poly := PackedVector2Array()
	for i in range(noise_segments):
		var angle := (float(i) / noise_segments) * TAU
		var noise_val = noise_generator.noise.get_noise_2d(
			center.x + cos(angle) * 100,
			center.y + sin(angle) * 100
		)
		var r = radius + noise_val * noise_strength
		poly.append(center + Vector2(cos(angle), sin(angle)) * r)
	return poly

func _corridor_polys(a:Vector2, b:Vector2, w:float) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	var d = (b - a).normalized()
	var n = Vector2(-d.y, d.x) * w
	
	# Main corridor rectangle
	var rect := PackedVector2Array([
		a + n, a - n, b - n, b + n
	])
	result.append(rect)
	
	# Round caps
	result.append(_round_cap_poly(a, -d, w))
	result.append(_round_cap_poly(b, d, w))
	
	return result

func _round_cap_poly(c:Vector2, dir:Vector2, w:float) -> PackedVector2Array:
	var n = Vector2(-dir.y, dir.x)
	var pts := PackedVector2Array()
	var steps = 10
	for i in range(steps+1):
		var t = float(i)/steps * PI
		var v = dir.rotated(t - PI*0.5) * 0 + n.rotated(t) * w
		pts.append(c + v)
	pts.append(c) # center to close fan
	return pts
