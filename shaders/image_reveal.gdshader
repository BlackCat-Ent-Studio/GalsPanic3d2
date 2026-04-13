shader_type spatial;
render_mode blend_mix, cull_disabled;

uniform sampler2D claim_mask : filter_nearest;
uniform sampler2D level_image : source_color, filter_linear;
uniform vec4 overlay_color : source_color = vec4(0.12, 0.12, 0.18, 1.0);
uniform float reveal_edge_width = 0.08;
uniform vec4 edge_glow_color : source_color = vec4(0.3, 0.8, 1.0, 1.0);

// Geometric cylindrical curve — convex bulge: center protrudes toward viewer (+Z).
// curve_depth is how far, in local units, the center pushes forward along Z.
// Edges stay at local z=0; center pushes forward by curve_depth.
uniform float curve_depth : hint_range(-3.0, 3.0) = 1.0;
uniform float half_width = 10.0;

void vertex() {
	// Convex cylindrical bulge — center protrudes forward, edges stay at z=0.
	float nx = VERTEX.x / half_width;
	VERTEX.z += curve_depth * (1.0 - nx * nx);
}

void fragment() {
	vec2 uv = UV;
	float mask = texture(claim_mask, uv).r;
	vec3 img_color = texture(level_image, uv).rgb;

	// Reveal: mask > 0.9 = claimed = show image
	float reveal = smoothstep(0.9 - reveal_edge_width, 0.9, mask);

	// Glowing edge at boundary
	float edge = smoothstep(0.9 - reveal_edge_width, 0.9, mask)
	           - smoothstep(0.9, 0.9 + reveal_edge_width, mask);

	vec3 final_color = mix(overlay_color.rgb, img_color, reveal);
	final_color += edge_glow_color.rgb * edge * 2.0;

	ALBEDO = final_color;
	EMISSION = edge_glow_color.rgb * edge * 1.5;
}
