shader_type sky;
render_mode use_debanding;
uniform float star_density = 0.0025;
uniform float nebula_strength = 0.25;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

void sky() {
    vec3 dir = normalize(EYEDIR);
    float horizon = max(0.0, 1.0 - abs(dir.y));
    vec3 col = vec3(0.005, 0.008, 0.025);
    col += vec3(0.08, 0.02, 0.13) * pow(horizon, 2.0) * nebula_strength;
    vec2 uv = dir.xz / max(abs(dir.y) + 0.15, 0.15);
    vec2 cell = floor(uv * 700.0);
    float star = step(1.0 - star_density, hash21(cell));
    col += vec3(0.65, 0.8, 1.0) * star;
    COLOR = col;
}
