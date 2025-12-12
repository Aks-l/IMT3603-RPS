shader_type canvas_item;

// Array of revealed positions (in world space)
uniform int revealed_count = 0;
uniform vec2 revealed_positions[64]; // Max 64 revealed nodes (world coordinates)
uniform vec2 fog_offset = vec2(0.0, 0.0); // Fog overlay position in world space
uniform vec2 fog_size = vec2(1920.0, 1080.0); // Fog overlay size in world space
uniform float reveal_radius = 150.0; // Radius of light around each revealed node
uniform float fade_distance = 100.0; // Distance over which fog fades
uniform vec4 fog_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // Dark fog
uniform float vignette_strength = 0.8; // How strong the vignette effect is

void fragment() {
	vec2 uv = UV;
	
	// Convert fog overlay UV to world position
	vec2 world_pos = fog_offset + uv * fog_size;
	
	// Calculate minimum distance to any revealed node
	float min_dist = 999999.0;
	for (int i = 0; i < revealed_count && i < 64; i++) {
		float dist = distance(world_pos, revealed_positions[i]);
		min_dist = min(min_dist, dist);
	}
	
	// Calculate fog alpha based on distance
	float fog_alpha = 1.0;
	if (min_dist < reveal_radius) {
		// Fully visible within reveal radius
		fog_alpha = 0.0;
	} else if (min_dist < reveal_radius + fade_distance) {
		// Gradual fade in the transition zone
		float fade_factor = (min_dist - reveal_radius) / fade_distance;
		fog_alpha = smoothstep(0.0, 1.0, fade_factor) * fog_color.a;
	} else {
		// Fully fogged beyond fade distance
		fog_alpha = fog_color.a;
	}
	
	// Apply vignette effect for extra darkness at edges
	vec2 center_dist = abs(uv - vec2(0.5));
	float vignette = 1.0 - smoothstep(0.3, 0.8, length(center_dist));
	vignette = mix(1.0, vignette, vignette_strength);
	
	fog_alpha *= (1.0 + (1.0 - vignette) * 0.5);
	
	// Output fog color with calculated alpha
	COLOR = vec4(fog_color.rgb, fog_alpha);
}
