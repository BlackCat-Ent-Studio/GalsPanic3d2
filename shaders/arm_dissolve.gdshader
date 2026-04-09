shader_type spatial;
render_mode blend_mix, cull_back;

uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 base_color : source_color = vec4(0.7, 0.85, 1.0, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 0.3, 0.0, 1.0);
uniform float edge_width = 0.08;

void fragment() {
    float noise = fract(sin(dot(UV * 20.0, vec2(12.9898, 78.233))) * 43758.5453);
    if (noise < dissolve_amount) {
        discard;
    }
    float edge = smoothstep(dissolve_amount - edge_width, dissolve_amount, noise);
    ALBEDO = mix(edge_color.rgb, base_color.rgb, edge);
    EMISSION = edge_color.rgb * (1.0 - edge) * 3.0;
}
