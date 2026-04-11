shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded;

uniform float fade : hint_range(0.0, 1.0) = 1.0;
uniform vec3 crack_color : source_color = vec3(1.0, 1.0, 1.0);

// Procedural radial crack pattern
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float crack_line(vec2 uv, vec2 a, vec2 b, float width) {
	vec2 pa = uv - a;
	vec2 ba = b - a;
	float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	float d = length(pa - ba * t);
	return smoothstep(width, 0.0, d);
}

void fragment() {
	vec2 uv = UV - 0.5;  // Center at origin
	float dist = length(uv);

	// Radial cracks: 5-7 lines from center outward
	float crack = 0.0;
	for (int i = 0; i < 6; i++) {
		float angle = float(i) * 1.047 + hash(vec2(float(i), 0.5)) * 0.5;
		float len = 0.3 + hash(vec2(float(i), 1.0)) * 0.15;
		vec2 endpoint = vec2(cos(angle), sin(angle)) * len;
		// Add slight curve via midpoint offset
		vec2 mid = endpoint * 0.5 + vec2(hash(vec2(float(i), 2.0)) - 0.5, hash(vec2(float(i), 3.0)) - 0.5) * 0.08;
		crack += crack_line(uv, vec2(0.0), mid, 0.008);
		crack += crack_line(uv, mid, endpoint, 0.006);
	}

	// Concentric ring crack
	float ring = abs(dist - 0.15);
	crack += smoothstep(0.008, 0.0, ring) * 0.6;

	// Center bright spot
	crack += smoothstep(0.06, 0.0, dist) * 0.8;

	crack = clamp(crack, 0.0, 1.0);

	ALBEDO = crack_color * crack;
	ALPHA = crack * fade;
}
