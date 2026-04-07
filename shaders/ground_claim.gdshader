shader_type spatial;

uniform sampler2D claim_mask : filter_nearest;
uniform vec4 base_color : source_color = vec4(0.15, 0.18, 0.22, 1.0);
uniform vec4 claimed_color : source_color = vec4(0.2, 0.5, 0.9, 1.0);
uniform vec4 wall_color : source_color = vec4(0.4, 0.45, 0.5, 1.0);
uniform vec2 grid_origin = vec2(-10.0, -10.0);
uniform vec2 grid_size = vec2(20.0, 20.0);
uniform float grid_line_width = 0.02;
uniform float grid_spacing = 1.0;

void fragment() {
    // World XZ position from vertex
    vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec2 world_xz = world_pos.xz;

    // Claim mask UV
    vec2 uv_mask = (world_xz - grid_origin) / grid_size;
    float mask = texture(claim_mask, uv_mask).r;

    // Subtle grid lines
    vec2 grid_pos = mod(world_xz, grid_spacing);
    float grid_line = step(grid_pos.x, grid_line_width) + step(grid_pos.y, grid_line_width);
    grid_line = clamp(grid_line, 0.0, 1.0);

    if (mask > 0.9) {
        // Claimed territory
        ALBEDO = claimed_color.rgb + grid_line * 0.05;
    } else if (mask > 0.4) {
        // Wall or unclaimed
        float is_wall = step(0.45, mask) * (1.0 - step(0.6, mask));
        vec3 color = mix(base_color.rgb, wall_color.rgb, is_wall);
        ALBEDO = color + grid_line * 0.03;
    } else {
        // Outside
        ALBEDO = vec3(0.08, 0.08, 0.1);
    }
}
