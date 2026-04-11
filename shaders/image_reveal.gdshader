shader_type spatial;
render_mode blend_mix, cull_disabled;

uniform sampler2D claim_mask : filter_nearest;
uniform sampler2D level_image : source_color, filter_linear;
uniform vec4 overlay_color : source_color = vec4(0.12, 0.12, 0.18, 1.0);
uniform float reveal_edge_width = 0.08;
uniform vec4 edge_glow_color : source_color = vec4(0.3, 0.8, 1.0, 1.0);

void fragment() {
    // Use mesh UV directly — maps 1:1 to both claim mask and image
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
