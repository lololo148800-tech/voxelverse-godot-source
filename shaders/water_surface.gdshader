shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 water_tint : source_color = vec4(0.10, 0.44, 0.82, 0.68);
uniform float wave_height : hint_range(0.0, 0.08) = 0.026;
uniform float wave_frequency = 1.55;
uniform float wave_speed = 0.42;
uniform float surface_alpha : hint_range(0.35, 0.90) = 0.70;

void vertex() {
    vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    if (NORMAL.y > 0.45) {
        float phase_a = world_position.x * wave_frequency + TIME * wave_speed;
        float phase_b = world_position.z * (wave_frequency * 0.82) - TIME * (wave_speed * 0.73);
        VERTEX.y += sin(phase_a) * wave_height;
        VERTEX.y += cos(phase_b) * (wave_height * 0.55);
    }
}

void fragment() {
    float ripple_a = sin((VERTEX.x + TIME * 0.18) * 1.7) * 0.035;
    float ripple_b = cos((VERTEX.z - TIME * 0.13) * 1.35) * 0.025;
    ALBEDO = max(water_tint.rgb + vec3(ripple_a + ripple_b), vec3(0.0));
    ROUGHNESS = 0.18;
    SPECULAR = 0.72;
    METALLIC = 0.0;
    ALPHA = surface_alpha;
}
