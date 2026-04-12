shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded;

uniform float fade : hint_range(0.0, 1.0) = 1.0;
uniform float time_offset = 0.0;

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	vec2 centered = uv - 0.5;
	float dist = length(centered);

	// Tight circular mask — only render within small radius around center
	float mask = 1.0 - smoothstep(0.15, 0.35, dist);
	if (mask < 0.001) {
		discard;
	}

	// Vertical streaks
	float band_count = 60.0;
	float band_x = floor(uv.x * band_count);
	float band_seed = hash(band_x);

	// Each band has small random vertical extent centered on impact y
	float band_half_height = 0.05 + band_seed * 0.15;
	float band_center_y = 0.5 + (hash(band_x + 17.3) - 0.5) * 0.1;
	float v_dist = abs(uv.y - band_center_y);
	float streak = step(v_dist, band_half_height);

	// Animated flicker
	float flicker_t = TIME * 10.0 + time_offset;
	float flicker = 0.6 + 0.4 * sin(flicker_t + band_x * 0.7);

	// Sub-band gaps for finer detail
	float sub_band = floor(uv.x * band_count * 3.0);
	float sub_noise = hash(sub_band + flicker_t * 0.05);
	float sub_streak = step(0.35, sub_noise);

	// Per-band saturated RGB color
	vec3 band_color = vec3(
		hash(band_x + 1.0),
		hash(band_x + 2.0),
		hash(band_x + 3.0)
	);
	float max_c = max(band_color.r, max(band_color.g, band_color.b));
	band_color = pow(band_color / max(max_c, 0.001), vec3(2.5));

	float intensity = streak * sub_streak * flicker * mask;

	// Speckle noise tightly around center
	float noise = hash2(uv * 250.0 + vec2(flicker_t * 0.2));
	float speckle = step(0.88, noise) * mask;

	vec3 final_color = band_color * intensity + vec3(speckle * 0.8);
	float alpha = clamp((intensity + speckle) * fade, 0.0, 1.0);

	ALBEDO = final_color;
	ALPHA = alpha;
}
