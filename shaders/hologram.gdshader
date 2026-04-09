shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 tint_color : source_color = vec4(0.3, 0.8, 1.0, 0.4);
uniform float scan_speed = 2.0;

void fragment() {
    ALBEDO = tint_color.rgb;
    ALPHA = tint_color.a + sin(VERTEX.y * 10.0 + TIME * scan_speed) * 0.1;
}
