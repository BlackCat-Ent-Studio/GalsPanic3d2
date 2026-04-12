shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded;

uniform float fade : hint_range(0.0, 1.0) = 1.0;
uniform float time_offset = 0.0;

// Hash for randomness
float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	vec2 centered = uv - 0.5;
	float dist_from_center = length(centered);

	// Falloff: streaks concentrated near center, fade at edges
	float falloff = 1.0 - smoothstep(0.0, 0.5, dist_from_center);
	falloff = pow(falloff, 1.5);

	// Vertical streaks: divide horizontal axis into bands
	float band_count = 80.0;
	float band_x = floor(uv.x * band_count);
	float band_seed = hash(band_x);

	// Each band has random vertical extent (height) and offset
	float band_height = 0.3 + band_seed * 0.7;
	float band_offset = hash(band_x + 17.3) * 2.0 - 1.0;

	// Animated flicker (slight time-based variation)
	float flicker_t = TIME * 8.0 + time_offset;
	float flicker = 0.5 + 0.5 * sin(flicker_t + band_x * 0.5);

	// Streak intensity based on distance from center vertically
	float v_dist = abs(uv.y - 0.5 - band_offset * 0.1);
	float streak = step(v_dist, band_height * 0.5);

	// Random per-band color (RGB stripes)
	vec3 band_color = vec3(
		hash(band_x + 1.0),
		hash(band_x + 2.0),
		hash(band_x + 3.0)
	);
	// Boost saturation - pick dominant channel
	float max_c = max(band_color.r, max(band_color.g, band_color.b));
	band_color = pow(band_color / max(max_c, 0.001), vec3(2.0));

	// Sub-bands within each band for finer detail
	float sub_band = floor(uv.x * band_count * 4.0);
	float sub_noise = hash(sub_band + flicker_t * 0.1);
	float sub_streak = step(0.3, sub_noise);

	// Combine: streak * sub_streak * flicker * falloff
	float intensity = streak * sub_streak * (0.5 + flicker * 0.5) * falloff;

	// Add some white noise speckles near center
	float noise = hash2(uv * 200.0 + vec2(flicker_t * 0.3));
	float speckle = step(0.85, noise) * falloff * 0.6;

	vec3 final_color = band_color * intensity + vec3(speckle);
	float alpha = (intensity + speckle) * fade;

	ALBEDO = final_color;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
