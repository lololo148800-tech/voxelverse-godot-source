shader_type sky;
render_mode use_debanding;

uniform vec3 zenith_color : source_color = vec3(0.38, 0.52, 0.72);
uniform vec3 horizon_color : source_color = vec3(0.72, 0.82, 0.90);
uniform vec3 sun_color : source_color = vec3(1.0, 0.86, 0.62);
uniform float sun_strength = 0.30;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float cloud_shape(vec2 cell) {
    float n = hash21(cell);
    float neighbor = hash21(cell + vec2(1.0, 0.0));
    float vertical = hash21(cell + vec2(0.0, 1.0));
    return step(0.62, n) * (0.55 + 0.45 * step(0.48, neighbor + vertical * 0.24));
}

void sky() {
    vec3 dir = normalize(EYEDIR);
    float height = clamp(dir.y * 0.5 + 0.5, 0.0, 1.0);
    float gradient = smoothstep(0.02, 0.95, height);
    vec3 color = mix(horizon_color, zenith_color, gradient);
    float horizon_glow = pow(max(0.0, 1.0 - abs(dir.y)), 3.0);
    color += vec3(0.05, 0.06, 0.05) * horizon_glow;

    vec3 sun_dir = normalize(vec3(-0.35, 0.72, -0.42));
    float sun_dot = max(dot(dir, sun_dir), 0.0);
    float sun_disc = pow(sun_dot, 320.0);
    float sun_halo = pow(sun_dot, 22.0);
    color += sun_color * (sun_disc * 1.5 + sun_halo * sun_strength);

    float cloud_height = smoothstep(0.16, 0.62, dir.y) * (1.0 - smoothstep(0.72, 0.98, dir.y));
    vec2 cloud_plane = dir.xz / max(dir.y + 0.25, 0.25) * 5.4;
    vec2 cloud_cell = floor(cloud_plane);
    vec2 cloud_fraction = fract(cloud_plane);
    float cloud = cloud_shape(cloud_cell) * step(0.82, hash21(cloud_cell + vec2(9.0, 4.0)));
    float block_edge = step(0.10, cloud_fraction.x) * step(0.08, cloud_fraction.y) * step(cloud_fraction.x, 0.92) * step(cloud_fraction.y, 0.88);
    cloud *= block_edge * cloud_height;
    color = mix(color, vec3(0.96, 0.96, 0.94), cloud * 0.58);

    COLOR = color;
}
