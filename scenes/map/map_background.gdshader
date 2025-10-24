shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.25, 0.30, 0.22, 1.0); // Forest green base
uniform vec4 path_color : source_color = vec4(0.45, 0.42, 0.35, 1.0); // Dirt path
uniform vec4 grass_color : source_color = vec4(0.20, 0.35, 0.25, 1.0); // Grass
uniform vec4 mountain_color : source_color = vec4(0.35, 0.32, 0.30, 1.0); // Rocky mountains

uniform float time_scale = 0.3;
uniform float path_width = 100.0;

// Node positions to generate path through
uniform vec4 nodes[50];
uniform int node_count = 0;

// Noise functions for terrain generation
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    
    for(int i = 0; i < 4; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

// Distance to path (line segment)
float distance_to_segment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

void fragment() {
    vec2 pixel_pos = FRAGCOORD.xy;
    
    // Generate base terrain with noise
    float terrain = fbm(pixel_pos * 0.005);
    
    // Calculate distance to nearest path segment
    float min_dist = 10000.0;
    for(int i = 0; i < node_count - 1 && i < 49; i++) {
        vec2 node_a = nodes[i].xy;
        vec2 node_b = nodes[i + 1].xy;
        float dist = distance_to_segment(pixel_pos, node_a, node_b);
        min_dist = min(min_dist, dist);
    }
    
    // Base landscape color (grass/forest)
    vec4 color = mix(grass_color, base_color, terrain);
    
    // Add mountain ridges far from path
    float mountain_factor = smoothstep(path_width * 2.0, path_width * 4.0, min_dist);
    color = mix(color, mountain_color, mountain_factor * terrain * 0.6);
    
    // Draw the path
    float path_factor = smoothstep(path_width, path_width * 0.5, min_dist);
    color = mix(color, path_color, path_factor);
    
    // Add terrain detail noise
    float detail = fbm(pixel_pos * 0.02 + TIME * time_scale * 0.05);
    color.rgb += (detail - 0.5) * 0.1;
    
    // Darker areas in valleys (based on noise)
    float valley = fbm(pixel_pos * 0.003);
    color.rgb *= 0.85 + valley * 0.3;
    
    // Subtle animated fog/atmosphere
    float fog = fbm(pixel_pos * 0.001 + vec2(TIME * time_scale * 0.02, 0.0));
    color.rgb = mix(color.rgb, vec3(0.6, 0.65, 0.7), fog * 0.15);
    
    COLOR = color;
}
